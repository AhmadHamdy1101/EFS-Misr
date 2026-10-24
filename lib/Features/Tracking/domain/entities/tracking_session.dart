import 'dart:math' as math;

/// Lifecycle of a request/session as reported by `tracking_overview` and the
/// `tracking_*` database functions. Whether the latest location is fresh is a separate question, see
/// [TrackingSession.isStale].
enum TrackingStatus {
  pending('pending'),
  active('active'),
  declined('declined'),
  cancelled('cancelled'),
  expired('expired'),
  completed('completed'),
  unknown('unknown');

  const TrackingStatus(this.databaseValue);

  final String databaseValue;

  bool get isOpen => this == pending || this == active;

  static TrackingStatus fromDatabase(String? value) {
    for (final status in values) {
      if (status.databaseValue == value) return status;
    }
    return TrackingStatus.unknown;
  }
}

/// One open item from `tracking_overview`: a pending request or an active
/// session, with the latest position when there is one.
class TrackingSession {
  const TrackingSession({
    required this.id,
    required this.workerUid,
    required this.technicianId,
    required this.status,
    this.requestId,
    this.sessionId,
    this.openedAt,
    this.requestedBy,
    this.ticketId,
    this.branchId,
    this.endReason,
    this.requestedAt,
    this.expiresAt,
    this.respondedAt,
    this.startedAt,
    this.arrivedAt,
    this.endedAt,
    this.deviceId,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.heading,
    this.speed,
    this.locationRecordedAt,
    this.lastLocationAt,
  });

  /// After this long without an update the position is shown as stale.
  static const staleAfter = Duration(minutes: 3);

  /// The session id while active, the request id while pending.
  final String id;
  final String? requestId;
  final String? sessionId;

  /// The worker's auth uid (`users.userid`).
  final String workerUid;

  /// The worker's `users.id`.
  final BigInt technicianId;

  /// When the request was made or the session started; newer wins.
  final DateTime? openedAt;
  final BigInt? requestedBy;
  final int? ticketId;
  final int? branchId;
  final TrackingStatus status;
  final String? endReason;
  final DateTime? requestedAt;
  final DateTime? expiresAt;
  final DateTime? respondedAt;
  final DateTime? startedAt;
  final DateTime? arrivedAt;
  final DateTime? endedAt;
  final String? deviceId;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? heading;
  final double? speed;
  final DateTime? locationRecordedAt;

  /// Server time the latest position arrived.
  final DateTime? lastLocationAt;

  bool get hasLocation => latitude != null && longitude != null;

  /// Active, but no position arrived recently (GPS off, no network, app
  /// killed). The session stays open; viewers are warned instead.
  bool isStale(DateTime now) {
    if (status != TrackingStatus.active) return false;
    final last = lastLocationAt ?? startedAt;
    if (last == null) return true;
    return now.difference(last) > staleAfter;
  }

  /// Active with a fresh position.
  bool isLive(DateTime now) =>
      status == TrackingStatus.active && hasLocation && !isStale(now);

  bool isExpired(DateTime now) =>
      status == TrackingStatus.pending &&
      expiresAt != null &&
      now.isAfter(expiresAt!);

  /// The same item with a newer position from `worker_locations`.
  TrackingSession withLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? heading,
    double? speed,
    DateTime? recordedAt,
    DateTime? receivedAt,
  }) {
    return TrackingSession(
      id: id,
      workerUid: workerUid,
      technicianId: technicianId,
      status: status,
      requestId: requestId,
      sessionId: sessionId,
      openedAt: openedAt,
      requestedBy: requestedBy,
      ticketId: ticketId,
      branchId: branchId,
      endReason: endReason,
      requestedAt: requestedAt,
      expiresAt: expiresAt,
      respondedAt: respondedAt,
      startedAt: startedAt,
      arrivedAt: arrivedAt,
      endedAt: endedAt,
      deviceId: deviceId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      heading: heading,
      speed: speed,
      locationRecordedAt: recordedAt,
      lastLocationAt: receivedAt,
    );
  }

  factory TrackingSession.fromJson(Map<String, dynamic> json) {
    return TrackingSession(
      id: json['id'].toString(),
      requestId: json['request_id']?.toString(),
      sessionId: json['session_id']?.toString(),
      workerUid: json['worker_uid'].toString(),
      openedAt: _date(json['opened_at']),
      technicianId: BigInt.parse(json['technician_id'].toString()),
      requestedBy: json['requested_by'] == null
          ? null
          : BigInt.parse(json['requested_by'].toString()),
      ticketId: _int(json['ticket_id']),
      branchId: _int(json['branch_id']),
      status: TrackingStatus.fromDatabase(json['status']?.toString()),
      endReason: json['end_reason']?.toString(),
      requestedAt: _date(json['requested_at']),
      expiresAt: _date(json['expires_at']),
      respondedAt: _date(json['responded_at']),
      startedAt: _date(json['started_at']),
      arrivedAt: _date(json['arrived_at']),
      endedAt: _date(json['ended_at']),
      deviceId: json['device_id']?.toString(),
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
      accuracy: _double(json['accuracy']),
      heading: _double(json['heading']),
      speed: _double(json['speed']),
      locationRecordedAt: _date(json['location_recorded_at']),
      lastLocationAt: _date(json['last_location_at']),
    );
  }

  static int? _int(Object? value) =>
      value == null ? null : int.tryParse(value.toString());

  static double? _double(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('${value ?? ''}');

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
}

/// Great-circle distance in meters.
double distanceInMeters(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  double rad(double degrees) => degrees * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}
