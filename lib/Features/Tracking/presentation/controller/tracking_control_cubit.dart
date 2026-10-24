import 'dart:async';
import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tracking_session.dart';
import '../../domain/entities/tracking_worker.dart';
import '../../domain/repo/tracking_repo.dart';

part 'tracking_control_state.dart';

/// The admin's live view: every worker with their open session, kept in sync
/// through realtime. A periodic tick re-evaluates freshness so a worker whose
/// updates stopped turns "offline" without any new event arriving.
class TrackingControlCubit extends Cubit<TrackingControlState> {
  TrackingControlCubit(
    this._repo, {
    DateTime Function()? clock,
    this.tickInterval = const Duration(seconds: 30),
    this.reconnectDelay = const Duration(seconds: 5),
  }) : _clock = clock ?? DateTime.now,
       super(TrackingControlState(now: (clock ?? DateTime.now)()));

  final TrackingRepo _repo;
  final DateTime Function() _clock;
  final Duration tickInterval;
  final Duration reconnectDelay;

  StreamSubscription<TrackingUpdate>? _sub;
  Timer? _tick;
  Timer? _reconnect;
  int _generation = 0;
  int _noticeId = 0;

  Future<void> start() async {
    final generation = _generation;
    emit(state.copyWith(loading: true, clearError: true));
    _subscribe();
    _tick ??= Timer.periodic(tickInterval, (_) {
      if (!isClosed) emit(state.copyWith(now: _clock()));
    });
    await _load(generation);
  }

  Future<void> refresh() => _load(_generation);

  /// Stops realtime and clears data for the previous user (sign-out).
  Future<void> reset() async {
    _generation++;
    _tick?.cancel();
    _tick = null;
    _reconnect?.cancel();
    await _sub?.cancel();
    _sub = null;
    if (!isClosed) emit(TrackingControlState(now: _clock()));
  }

  void search(String query) =>
      emit(state.copyWith(query: query.trim().toLowerCase()));

  void setFilter(WorkerFilter filter) => emit(state.copyWith(filter: filter));

  Future<Either<Failure, TrackingSession>> requestLocation(
    UserEntity worker, {
    int? ticketId,
  }) async {
    final result = await _repo.request(
      workerUid: worker.userid,
      ticketId: ticketId,
    );
    result.fold((_) {}, (session) => _applySession(session.workerUid, session));
    return result;
  }

  /// Withdraws a pending request or stops an active session.
  Future<Either<Failure, TrackingStatus>> cancel(
    TrackingSession session,
  ) async {
    final result = await _repo.end(session, byWorker: false);
    result.fold((_) {}, (status) {
      if (!status.isOpen) _applySession(session.workerUid, null);
    });
    return result;
  }

  Future<Either<Failure, BranchLocation?>> branch(int branchId) =>
      _repo.getBranch(branchId);

  Future<void> _load(int generation) async {
    final (workers, sessions) = await (
      _repo.getWorkers(),
      _repo.getOpenSessions(),
    ).wait;
    if (isClosed || generation != _generation) return;
    final failure =
        workers.fold((f) => f, (_) => null) ??
        sessions.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(state.copyWith(loading: false, error: failure.message));
      return;
    }
    final open = <BigInt, TrackingSession>{};
    // Newest first from the server; keep the newest per worker.
    for (final session in sessions.getOrElse(() => const [])) {
      open.putIfAbsent(session.technicianId, () => session);
    }
    emit(
      state.copyWith(
        loading: false,
        clearError: true,
        now: _clock(),
        workers: workers.getOrElse(() => const []),
        sessions: open,
      ),
    );
  }

  void _subscribe() {
    _sub?.cancel();
    _sub = _repo.watch().listen(
      _onUpdate,
      onError: (Object error) {
        developer.log(
          'Tracking realtime dropped: $error',
          name: 'TrackingControlCubit',
        );
        emit(state.copyWith(realtimeLost: true));
        _scheduleReconnect();
      },
    );
  }

  void _scheduleReconnect() {
    if (_reconnect?.isActive ?? false) return;
    final generation = _generation;
    _reconnect = Timer(reconnectDelay, () async {
      if (isClosed || generation != _generation) return;
      _subscribe();
      await _load(generation);
      if (!isClosed) emit(state.copyWith(realtimeLost: false));
    });
  }

  void _onUpdate(TrackingUpdate update) {
    if (isClosed) return;
    switch (update) {
      case SessionUpdate(:final workerUid, :final session, :final endedAs):
        _applySession(workerUid, session, endedAs: endedAs);
      case LocationUpdate():
        _applyLocation(update);
    }
  }

  /// Positions arrive often and possibly out of order or twice: only a newer
  /// one for the worker's current session moves the marker.
  void _applyLocation(LocationUpdate update) {
    final entry = _entryFor(update.workerUid);
    if (entry == null) return;
    final current = entry.value;
    if (current.sessionId != update.sessionId) return;
    final last = current.lastLocationAt;
    final received = update.receivedAt;
    if (last != null && received != null && !received.isAfter(last)) return;
    emit(
      state.copyWith(
        now: _clock(),
        sessions: {
          ...state.sessions,
          entry.key: current.withLocation(
            latitude: update.latitude,
            longitude: update.longitude,
            accuracy: update.accuracy,
            heading: update.heading,
            speed: update.speed,
            recordedAt: update.recordedAt,
            receivedAt: received,
          ),
        },
      ),
    );
  }

  /// Applies a worker's current open item ([session] null = nothing open).
  void _applySession(
    String workerUid,
    TrackingSession? session, {
    TrackingStatus? endedAs,
  }) {
    if (isClosed) return;
    final sessions = Map.of(state.sessions);
    final technicianId = session?.technicianId ?? _technicianIdFor(workerUid);
    if (technicianId == null) return;
    final current = sessions[technicianId];

    String? notice;
    if (session != null) {
      sessions[technicianId] = session;
      if (current?.status == TrackingStatus.pending &&
          session.status == TrackingStatus.active) {
        notice =
            '${_name(technicianId)} accepted and is sharing live location.';
      }
    } else {
      if (current == null) return;
      sessions.remove(technicianId);
      final name = _name(technicianId);
      notice = switch (endedAs) {
        TrackingStatus.declined => '$name declined the location request.',
        TrackingStatus.expired => 'The location request to $name expired.',
        TrackingStatus.completed => '$name stopped sharing location.',
        _ => null,
      };
    }
    emit(
      state.copyWith(
        sessions: sessions,
        now: _clock(),
        notice: notice,
        noticeId: notice == null ? null : ++_noticeId,
        notices: notice == null
            ? null
            : [TrackingNotice(notice, _clock()), ...state.notices.take(19)],
      ),
    );
  }

  MapEntry<BigInt, TrackingSession>? _entryFor(String workerUid) {
    for (final entry in state.sessions.entries) {
      if (entry.value.workerUid == workerUid) return entry;
    }
    return null;
  }

  BigInt? _technicianIdFor(String workerUid) {
    final entry = _entryFor(workerUid);
    if (entry != null) return entry.key;
    for (final worker in state.workers) {
      if (worker.userid == workerUid) return worker.id;
    }
    return null;
  }

  String _name(BigInt technicianId) {
    for (final worker in state.workers) {
      if (worker.id == technicianId) return worker.name;
    }
    return 'The technician';
  }

  @override
  Future<void> close() async {
    _tick?.cancel();
    _reconnect?.cancel();
    await _sub?.cancel();
    return super.close();
  }
}
