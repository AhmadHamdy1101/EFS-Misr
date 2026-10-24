import 'dart:async';
import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/location_source.dart';
import '../../domain/entities/tracking_session.dart';
import '../../domain/entities/tracking_worker.dart';
import '../../domain/repo/tracking_repo.dart';

part 'my_tracking_state.dart';

/// The technician's side: incoming requests, consent, and publishing the
/// device position while a session is active.
///
/// Positions are throttled before they reach the database: the OS stream
/// already drops moves under ~20 m, at most one write goes out every
/// [minPublishInterval], and a [heartbeatInterval] write keeps a parked
/// technician from looking "stale" to the admin.
class MyTrackingCubit extends Cubit<MyTrackingState> {
  MyTrackingCubit({
    required TrackingRepo repo,
    required LocationSource location,
    required String deviceId,
    DateTime Function()? clock,
    this.minPublishInterval = const Duration(seconds: 10),
    this.heartbeatInterval = const Duration(seconds: 60),
    this.reconnectDelay = const Duration(seconds: 5),
  }) : _repo = repo,
       _location = location,
       _deviceId = deviceId,
       _clock = clock ?? DateTime.now,
       super(const MyTrackingState());

  final TrackingRepo _repo;
  final LocationSource _location;
  final String _deviceId;
  final DateTime Function() _clock;
  final Duration minPublishInterval;
  final Duration heartbeatInterval;
  final Duration reconnectDelay;

  UserEntity? _user;
  StreamSubscription<TrackingUpdate>? _sessionsSub;
  StreamSubscription<LocationFix>? _fixesSub;
  Timer? _heartbeat;
  Timer? _throttle;
  Timer? _reconnect;
  LocationFix? _latest;
  bool _publishing = false;
  bool _pendingPublish = false;
  int _messageId = 0;

  /// Bumped on sign-out so late responses for the previous user are ignored.
  int _generation = 0;

  String get deviceId => _deviceId;

  /// Loads the open session and listens for requests. Resumes publishing if
  /// this device was sharing when the app was last closed.
  Future<void> start(UserEntity user) async {
    _user = user;
    final generation = _generation;
    emit(state.copyWith(loading: true));
    _subscribe();
    await _reload(generation);
    if (generation != _generation) return;
    final session = state.session;
    if (session != null &&
        session.status == TrackingStatus.active &&
        session.deviceId == _deviceId) {
      final access = await _location.checkAccess();
      if (generation != _generation) return;
      emit(state.copyWith(access: access));
      if (_isUsable(access)) _startStream(session);
    }
  }

  /// Stops publishing and drops everything for the previous user (sign-out).
  /// The session stays open on the server; it shows as stale until the
  /// technician signs in again or an admin cancels it.
  Future<void> reset() async {
    _generation++;
    _user = null;
    await _stopStream();
    await _sessionsSub?.cancel();
    _sessionsSub = null;
    _reconnect?.cancel();
    if (!isClosed) emit(const MyTrackingState());
  }

  Future<Either<Failure, Unit>> accept() async {
    final request = state.pendingRequest;
    if (request == null) {
      return Left(GeneralFailure('There is no pending request.'));
    }
    // Permission first: never accept a request we can't honour.
    final access = await _ensureAccess();
    if (access != null) return Left(access);
    return _run(
      () => _repo.respond(
        requestId: request.requestId ?? request.id,
        accept: true,
        deviceId: _deviceId,
      ),
      startSharing: true,
    );
  }

  Future<Either<Failure, Unit>> decline() async {
    final request = state.pendingRequest;
    if (request == null) {
      return Left(GeneralFailure('There is no pending request.'));
    }
    return _run(
      () => _repo.respond(
        requestId: request.requestId ?? request.id,
        accept: false,
        deviceId: _deviceId,
      ),
    );
  }

  /// Starts sharing without a request, or takes over an active session on
  /// this device (e.g. after reinstalling or switching phones).
  Future<Either<Failure, Unit>> startSharing() async {
    final access = await _ensureAccess();
    if (access != null) return Left(access);
    return _run(() => _repo.startSelf(deviceId: _deviceId), startSharing: true);
  }

  Future<Either<Failure, Unit>> stopSharing() async {
    final session = state.session;
    if (session == null) return const Right(unit);
    return _run(() => _repo.end(session, byWorker: true));
  }

  Future<Either<Failure, Unit>> markArrived() async {
    final session = state.session;
    final sessionId = session?.sessionId;
    if (session == null || sessionId == null || !state.isActive) {
      return Left(GeneralFailure('Start sharing first.'));
    }
    return _run(() async {
      final result = await _repo.markArrived(sessionId);
      return result.map((_) => TrackingStatus.active);
    });
  }

  Future<void> refreshAccess() async {
    final access = await _location.checkAccess();
    if (!isClosed) emit(state.copyWith(access: access));
  }

  Future<void> openAppSettings() => _location.openAppSettings();
  Future<void> openLocationSettings() => _location.openLocationSettings();

  // ---------------------------------------------------------------------------

  /// Runs a state change on the server, then re-reads the open item so the
  /// screen shows exactly what the database decided (e.g. the request had
  /// expired, or the ticket was reassigned meanwhile).
  Future<Either<Failure, Unit>> _run(
    Future<Either<Failure, TrackingStatus>> Function() action, {
    bool startSharing = false,
  }) async {
    if (state.busy) return Left(GeneralFailure('Please wait…'));
    emit(state.copyWith(busy: true));
    final result = await action();
    if (result.isRight()) {
      final status = result.getOrElse(() => TrackingStatus.unknown);
      await _reload(_generation, endedAs: status.isOpen ? null : status);
      final session = state.session;
      if (startSharing &&
          session != null &&
          session.status == TrackingStatus.active) {
        _startStream(session);
      }
    }
    if (!isClosed) emit(state.copyWith(busy: false));
    return result.map((_) => unit);
  }

  /// Returns a failure explaining why location can't be used, or null.
  Future<Failure?> _ensureAccess() async {
    final access = await _location.requestAccess();
    if (isClosed) return GeneralFailure('Closed');
    emit(state.copyWith(access: access));
    return switch (access) {
      LocationAccess.granted || LocationAccess.approximate => null,
      LocationAccess.serviceDisabled => GeneralFailure(
        'Turn on location services to share your location.',
      ),
      LocationAccess.deniedForever => GeneralFailure(
        'Location permission is blocked. Allow it in the app settings.',
      ),
      LocationAccess.denied => GeneralFailure(
        'Location permission is needed to share your location.',
      ),
    };
  }

  static bool _isUsable(LocationAccess access) =>
      access == LocationAccess.granted || access == LocationAccess.approximate;

  Future<void> _reload(int generation, {TrackingStatus? endedAs}) async {
    final user = _user;
    if (user == null) return;
    final result = await _repo.getOpenSessions(workerUid: user.userid);
    if (isClosed || generation != _generation) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          loading: false,
          message: failure.message,
          messageId: ++_messageId,
        ),
      ),
      (sessions) {
        emit(state.copyWith(loading: false));
        _setSession(sessions.isEmpty ? null : sessions.first, endedAs: endedAs);
      },
    );
  }

  void _subscribe() {
    final user = _user;
    if (user == null) return;
    _sessionsSub?.cancel();
    _sessionsSub = _repo
        .watch(workerUid: user.userid)
        .listen(
          _onUpdate,
          onError: (Object error) {
            developer.log(
              'Tracking realtime dropped: $error',
              name: 'MyTrackingCubit',
            );
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
      // Changes made while disconnected were not delivered: re-read.
      await _reload(generation);
    });
  }

  void _onUpdate(TrackingUpdate update) {
    if (isClosed || update is! SessionUpdate) return;
    // Our own position echoes back as LocationUpdate; lastFix covers it.
    _setSession(update.session, endedAs: update.endedAs);
  }

  /// Applies the current open item from the server and stops publishing if
  /// nothing is open any more. [endedAs] explains why the previous one ended.
  void _setSession(TrackingSession? session, {TrackingStatus? endedAs}) {
    if (isClosed) return;
    final previous = state.session;
    if (session == null) {
      if (previous != null) {
        _notify(_endedMessage(endedAs, previous.status));
      }
      unawaited(_stopStream());
      emit(state.copyWith(clearSession: true, clearBranch: true));
      return;
    }
    emit(state.copyWith(session: session));
    if (session.branchId != null && session.branchId != previous?.branchId) {
      _loadBranch(session.branchId!);
    } else if (session.branchId == null && state.branch != null) {
      emit(state.copyWith(clearBranch: true));
    }
    if (session.status == TrackingStatus.active &&
        session.deviceId != _deviceId &&
        state.sharing) {
      unawaited(_stopStream());
      _notify('Location sharing moved to another device.');
    }
  }

  Future<void> _loadBranch(int branchId) async {
    final result = await _repo.getBranch(branchId);
    if (isClosed || state.session?.branchId != branchId) return;
    result.fold((_) {}, (branch) => emit(state.copyWith(branch: branch)));
  }

  String _endedMessage(TrackingStatus? endedAs, TrackingStatus previous) {
    return switch (endedAs) {
      TrackingStatus.expired => 'The location request expired.',
      TrackingStatus.declined => 'Request declined.',
      TrackingStatus.completed => 'Location sharing stopped.',
      TrackingStatus.cancelled =>
        previous == TrackingStatus.pending
            ? 'The location request was cancelled.'
            : 'Location sharing was ended by an administrator or the ticket changed.',
      _ => 'Location sharing ended.',
    };
  }

  void _notify(String message) {
    if (isClosed) return;
    emit(state.copyWith(message: message, messageId: ++_messageId));
  }

  void _startStream(TrackingSession session) {
    if (_fixesSub != null) return;
    emit(state.copyWith(sharing: true, connectionLost: false));
    _fixesSub = _location.watch().listen(
      _onFix,
      onError: (Object error) async {
        await _stopStream();
        final access = await _location.checkAccess();
        if (isClosed) return;
        emit(state.copyWith(access: access));
        _notify(
          access == LocationAccess.serviceDisabled
              ? 'Location services were turned off. Sharing is paused.'
              : 'Location permission was removed. Sharing is paused.',
        );
      },
    );
    _heartbeat = Timer.periodic(heartbeatInterval, (_) => _onHeartbeat());
    // Publish a first fix right away instead of waiting for movement.
    _location.currentFix().then((fix) {
      if (fix != null && _fixesSub != null && _latest == null) _onFix(fix);
    });
  }

  Future<void> _stopStream() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    _throttle?.cancel();
    _throttle = null;
    await _fixesSub?.cancel();
    _fixesSub = null;
    _latest = null;
    _pendingPublish = false;
    if (!isClosed && state.sharing) {
      emit(state.copyWith(sharing: false, connectionLost: false));
    }
  }

  void _onFix(LocationFix fix) {
    if (isClosed) return;
    _latest = fix;
    emit(state.copyWith(lastFix: fix));
    _publishSoon();
  }

  void _onHeartbeat() {
    final latest = _latest;
    final last = state.lastPublishedAt;
    if (latest == null) return;
    if (last != null && _clock().difference(last) < heartbeatInterval * 0.9) {
      return;
    }
    // Not moved more than the distance filter: the last fix is still where
    // the technician is, so re-stamp it to keep the session fresh.
    _latest = latest.copyWith(recordedAt: _clock());
    _publishSoon();
  }

  void _publishSoon() {
    final last = state.lastPublishedAt;
    final wait = last == null
        ? Duration.zero
        : minPublishInterval - _clock().difference(last);
    if (wait <= Duration.zero) {
      _publish();
    } else if (!(_throttle?.isActive ?? false)) {
      _throttle = Timer(wait, _publish);
    }
  }

  Future<void> _publish() async {
    final session = state.session;
    final fix = _latest;
    final sessionId = session?.sessionId;
    if (sessionId == null || fix == null || _fixesSub == null) return;
    if (_publishing) {
      _pendingPublish = true;
      return;
    }
    _publishing = true;
    final result = await _repo.publish(
      sessionId: sessionId,
      deviceId: _deviceId,
      fix: fix,
    );
    _publishing = false;
    if (isClosed || _fixesSub == null) return;
    result.fold(
      // Offline: keep the session and the latest fix; the next fix or
      // heartbeat retries. The admin sees the position go stale meanwhile.
      (_) => emit(state.copyWith(connectionLost: true)),
      (outcome) {
        switch (outcome) {
          case PublishResult.ok:
          case PublishResult.ignored:
            emit(
              state.copyWith(connectionLost: false, lastPublishedAt: _clock()),
            );
          case PublishResult.otherDevice:
            unawaited(_stopStream());
            _notify('Location sharing moved to another device.');
          case PublishResult.ended:
            unawaited(_reload(_generation));
        }
      },
    );
    if (_pendingPublish) {
      _pendingPublish = false;
      _publishSoon();
    }
  }

  @override
  Future<void> close() async {
    _reconnect?.cancel();
    await _stopStream();
    await _sessionsSub?.cancel();
    return super.close();
  }
}
