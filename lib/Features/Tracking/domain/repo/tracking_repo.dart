import 'package:dartz/dartz.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/entities/user_entity.dart';

import '../entities/tracking_session.dart';
import '../entities/tracking_worker.dart';

/// Requests, sessions and latest positions (tables `location_requests`,
/// `location_sessions`, `worker_locations`, read through the
/// `tracking_overview` view). Every write goes through a database function
/// that checks the caller's role and the current state; those functions
/// return the resulting [TrackingStatus].
abstract interface class TrackingRepo {
  /// Users enabled as workers in `tracking_members`.
  Future<Either<Failure, List<UserEntity>>> getWorkers();

  /// Open (pending or active) items visible to the caller, optionally only
  /// one worker's (by auth uid).
  Future<Either<Failure, List<TrackingSession>>> getOpenSessions({
    String? workerUid,
  });

  Future<Either<Failure, BranchLocation?>> getBranch(int branchId);

  /// Live changes visible to the caller, optionally only one worker's.
  /// Emits an error when the realtime channel drops.
  Stream<TrackingUpdate> watch({String? workerUid});

  /// Asks a worker to share; returns their open item afterwards (a new
  /// pending request, or the request/session that already existed).
  Future<Either<Failure, TrackingSession>> request({
    required String workerUid,
    int? ticketId,
  });

  Future<Either<Failure, TrackingStatus>> respond({
    required String requestId,
    required bool accept,
    required String deviceId,
  });

  Future<Either<Failure, TrackingStatus>> startSelf({required String deviceId});

  Future<Either<Failure, PublishResult>> publish({
    required String sessionId,
    required String deviceId,
    required LocationFix fix,
  });

  Future<Either<Failure, Unit>> markArrived(String sessionId);

  /// Stops an active session (`tracking_stop_session`) or withdraws a
  /// pending request (`tracking_cancel_request`). Returns how it ended:
  /// completed when the worker stops their own sharing, otherwise cancelled.
  Future<Either<Failure, TrackingStatus>> end(
    TrackingSession item, {
    required bool byWorker,
    String? reason,
  });
}

/// A realtime change for one worker.
sealed class TrackingUpdate {
  const TrackingUpdate(this.workerUid);

  final String workerUid;
}

/// The worker's request or session changed. [session] is their open item
/// now (null when nothing is open); [endedAs] says how the previous one
/// ended, when the change ended it.
final class SessionUpdate extends TrackingUpdate {
  const SessionUpdate(super.workerUid, {this.session, this.endedAs});

  final TrackingSession? session;
  final TrackingStatus? endedAs;
}

/// A new position for the worker's session.
final class LocationUpdate extends TrackingUpdate {
  const LocationUpdate(
    super.workerUid, {
    required this.sessionId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.heading,
    this.speed,
    this.recordedAt,
    this.receivedAt,
  });

  final String sessionId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? heading;
  final double? speed;
  final DateTime? recordedAt;
  final DateTime? receivedAt;
}

/// One GPS reading.
class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.accuracy,
    this.heading,
    this.speed,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final double? accuracy;
  final double? heading;
  final double? speed;

  LocationFix copyWith({DateTime? recordedAt}) => LocationFix(
    latitude: latitude,
    longitude: longitude,
    recordedAt: recordedAt ?? this.recordedAt,
    accuracy: accuracy,
    heading: heading,
    speed: speed,
  );
}
