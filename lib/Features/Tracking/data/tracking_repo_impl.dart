import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:efs_misr/core/models/supadart_header.dart';
import 'package:efs_misr/core/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/tracking_session.dart';
import '../domain/entities/tracking_worker.dart';
import '../domain/repo/tracking_repo.dart';

class TrackingRepoImpl implements TrackingRepo {
  TrackingRepoImpl(this._client);

  final SupabaseClient _client;
  final Map<int, BranchLocation?> _branches = {};

  static const _overview = 'tracking_overview';

  @override
  Future<Either<Failure, List<UserEntity>>> getWorkers() {
    return _guard(() async {
      final members = await _client
          .from('tracking_members')
          .select('user_id')
          .eq('role', 'worker')
          .eq('enabled', true);
      final ids = [for (final row in members) row['user_id'].toString()];
      if (ids.isEmpty) return <UserEntity>[];
      final users = await _client.users
          .select(Users.selectColumns)
          .inFilter(Users.c_userid, ids)
          .order(Users.c_name)
          .withConverter(Users.converter);
      return users.map((user) => user.toUserEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, List<TrackingSession>>> getOpenSessions({
    String? workerUid,
  }) {
    return _guard(() => _open(workerUid));
  }

  Future<List<TrackingSession>> _open(String? workerUid) async {
    var query = _client.from(_overview).select();
    if (workerUid != null) query = query.eq('worker_uid', workerUid);
    final rows = await query.order('opened_at', ascending: false);
    return rows.map(TrackingSession.fromJson).toList();
  }

  @override
  Future<Either<Failure, BranchLocation?>> getBranch(int branchId) {
    return _guard(() async {
      if (_branches.containsKey(branchId)) return _branches[branchId];
      final rows = await _client
          .from('branch')
          .select('id,name,latitude,longitude')
          .eq('id', branchId)
          .limit(1);
      final branch = rows.isEmpty
          ? null
          : BranchLocation(
              id: branchId,
              name: rows.first['name']?.toString() ?? '',
              latitude: (rows.first['latitude'] as num?)?.toDouble(),
              longitude: (rows.first['longitude'] as num?)?.toDouble(),
            );
      return _branches[branchId] = branch;
    });
  }

  /// One channel with three table listeners. Request/session changes are
  /// rare, so each one re-reads that worker's row from the overview (which
  /// also covers events missed while reconnecting). Position changes are
  /// frequent and are passed through as-is, without a query.
  @override
  Stream<TrackingUpdate> watch({String? workerUid}) {
    final controller = StreamController<TrackingUpdate>();
    // Only the latest re-read per worker is emitted, so two quick changes
    // can't be delivered in the wrong order.
    final latestRead = <String, int>{};
    var reads = 0;

    Future<void> reread(String worker, TrackingStatus? endedAs) async {
      final read = latestRead[worker] = ++reads;
      try {
        final open = await _open(worker);
        if (controller.isClosed || latestRead[worker] != read) return;
        controller.add(
          SessionUpdate(
            worker,
            session: open.isEmpty ? null : open.first,
            endedAs: endedAs,
          ),
        );
      } catch (error, stackTrace) {
        if (!controller.isClosed) controller.addError(error, stackTrace);
      }
    }

    PostgresChangeFilter? filter() => workerUid == null
        ? null
        : PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'worker_id',
            value: workerUid,
          );

    final channel = _client.channel(
      'tracking:${workerUid ?? 'all'}:${identityHashCode(controller)}',
    );
    channel
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'location_requests',
        filter: filter(),
        callback: (payload) {
          final row = payload.newRecord;
          final worker = row['worker_id']?.toString();
          if (worker == null) return;
          reread(worker, switch (row['status']?.toString()) {
            'declined' => TrackingStatus.declined,
            'expired' => TrackingStatus.expired,
            'cancelled' => TrackingStatus.cancelled,
            _ => null,
          });
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'location_sessions',
        filter: filter(),
        callback: (payload) {
          final row = payload.newRecord;
          final worker = row['worker_id']?.toString();
          if (worker == null) return;
          final stopped = row['status']?.toString() == 'stopped';
          reread(
            worker,
            !stopped
                ? null
                : row['end_reason']?.toString() == 'Stopped by worker'
                ? TrackingStatus.completed
                : TrackingStatus.cancelled,
          );
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'worker_locations',
        filter: filter(),
        callback: (payload) {
          final row = payload.newRecord;
          final worker = row['worker_id']?.toString();
          final latitude = (row['latitude'] as num?)?.toDouble();
          final longitude = (row['longitude'] as num?)?.toDouble();
          if (worker == null || latitude == null || longitude == null) return;
          if (controller.isClosed) return;
          controller.add(
            LocationUpdate(
              worker,
              sessionId: row['session_id'].toString(),
              latitude: latitude,
              longitude: longitude,
              accuracy: (row['accuracy_meters'] as num?)?.toDouble(),
              heading: (row['heading'] as num?)?.toDouble(),
              speed: (row['speed'] as num?)?.toDouble(),
              recordedAt: _date(row['recorded_at']),
              receivedAt: _date(row['received_at']),
            ),
          );
        },
      )
      ..subscribe((status, error) {
        if (controller.isClosed) return;
        if (status == RealtimeSubscribeStatus.channelError ||
            status == RealtimeSubscribeStatus.timedOut ||
            error != null) {
          controller.addError(
            error ?? GeneralFailure('Realtime connection lost'),
          );
        }
      });

    controller.onCancel = () => _client.removeChannel(channel);
    return controller.stream;
  }

  // The RPCs below are the tracking functions that already exist in the live
  // database (extended by 20261024161406_live_location_tracking.sql with the
  // ticket link, device binding, heading/speed and admin stop).

  @override
  Future<Either<Failure, TrackingSession>> request({
    required String workerUid,
    int? ticketId,
  }) {
    return _guard(() async {
      await _client.rpc(
        'tracking_request_location',
        params: {'p_worker': workerUid, 'p_ticket_id': ticketId},
      );
      final open = await _open(workerUid);
      if (open.isEmpty) {
        throw GeneralFailure('The request could not be created.');
      }
      return open.first;
    });
  }

  @override
  Future<Either<Failure, TrackingStatus>> respond({
    required String requestId,
    required bool accept,
    required String deviceId,
  }) {
    // Accepting also opens the session bound to this device, in the same
    // transaction, so an accepted request can't be left without a session.
    return _guard(() async {
      final result = await _client.rpc(
        'tracking_respond_request',
        params: {
          'p_request': requestId,
          'p_accept': accept,
          'p_device_id': deviceId,
        },
      );
      return switch (result?.toString()) {
        'active' || 'accepted' => TrackingStatus.active,
        final other => TrackingStatus.fromDatabase(other),
      };
    });
  }

  @override
  Future<Either<Failure, TrackingStatus>> startSelf({
    required String deviceId,
  }) {
    return _guard(() async {
      await _client.rpc(
        'tracking_start_session',
        params: {'p_request': null, 'p_device_id': deviceId},
      );
      return TrackingStatus.active;
    });
  }

  @override
  Future<Either<Failure, PublishResult>> publish({
    required String sessionId,
    required String deviceId,
    required LocationFix fix,
  }) async {
    try {
      final stored = await _client.rpc(
        'tracking_update_location',
        params: {
          'p_session': sessionId,
          'p_lat': fix.latitude,
          'p_lng': fix.longitude,
          'p_accuracy': (fix.accuracy ?? -1) >= 0 ? fix.accuracy : null,
          'p_recorded_at': fix.recordedAt.toUtc().toIso8601String(),
          'p_heading': fix.heading,
          'p_speed': fix.speed,
          'p_device_id': deviceId,
        },
      );
      return Right(stored == true ? PublishResult.ok : PublishResult.ignored);
    } on PostgrestException catch (error) {
      // Error codes raised by tracking_update_location.
      return switch (error.code) {
        trackingNoActiveSession => const Right(PublishResult.ended),
        trackingOtherDevice => const Right(PublishResult.otherDevice),
        // A fix older than the server accepts (e.g. queued while offline):
        // drop it; the next fix or heartbeat replaces it.
        trackingStaleFix => const Right(PublishResult.ignored),
        _ => Left(Failure.fromException(error)),
      };
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> markArrived(String sessionId) {
    return _guard(() async {
      await _client.rpc(
        'tracking_mark_arrived',
        params: {'p_session': sessionId},
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, TrackingStatus>> end(
    TrackingSession item, {
    required bool byWorker,
    String? reason,
  }) {
    return _guard(() async {
      final sessionId = item.sessionId;
      if (sessionId != null) {
        await _client.rpc(
          'tracking_stop_session',
          params: {'p_session': sessionId, 'p_reason': reason},
        );
        return byWorker ? TrackingStatus.completed : TrackingStatus.cancelled;
      }
      final requestId = item.requestId ?? item.id;
      if (byWorker) {
        await _client.rpc(
          'tracking_respond_request',
          params: {'p_request': requestId, 'p_accept': false},
        );
        return TrackingStatus.declined;
      }
      await _client.rpc(
        'tracking_cancel_request',
        params: {'p_request': requestId},
      );
      return TrackingStatus.cancelled;
    });
  }

  /// SQLSTATEs raised by `tracking_update_location`.
  static const trackingNoActiveSession = 'TR001';
  static const trackingOtherDevice = 'TR002';
  static const trackingStaleFix = 'TR003';


  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }
}
