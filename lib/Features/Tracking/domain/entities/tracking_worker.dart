import 'package:efs_misr/core/entities/user_entity.dart';

import 'tracking_session.dart';

/// How a worker appears on the admin control screen.
enum WorkerTrackingState { live, offline, pending, notSharing }

/// A worker together with their open tracking session, if any.
class TrackingWorker {
  const TrackingWorker({required this.user, this.session});

  final UserEntity user;
  final TrackingSession? session;

  WorkerTrackingState stateAt(DateTime now) {
    final session = this.session;
    if (session == null || !session.status.isOpen) {
      return WorkerTrackingState.notSharing;
    }
    if (session.status == TrackingStatus.pending) {
      return session.isExpired(now)
          ? WorkerTrackingState.notSharing
          : WorkerTrackingState.pending;
    }
    return session.isLive(now)
        ? WorkerTrackingState.live
        : WorkerTrackingState.offline;
  }
}

/// A branch as a map destination. Coordinates are null until an admin
/// enters them in the `branch` table.
class BranchLocation {
  const BranchLocation({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String name;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;
}

/// Outcome of publishing one position, as reported by the server.
enum PublishResult {
  ok,

  /// Older than the stored position; harmless.
  ignored,

  /// The session was taken over by another device of the same technician.
  otherDevice,

  /// The session is no longer active (stopped, cancelled, ticket closed).
  ended,
}
