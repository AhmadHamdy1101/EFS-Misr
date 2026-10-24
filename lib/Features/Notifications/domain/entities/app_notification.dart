/// A persistent notification from the `notifications` table. Rows are
/// created by database triggers; the app only reads them and marks them read.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.titleAr,
    this.bodyAr,
    this.data = const {},
    this.readAt,
  });

  final int id;

  /// Dotted event name, e.g. `ticket.assigned`, `tracking.requested`.
  final String type;
  final String title;
  final String body;
  final String? titleAr;
  final String? bodyAr;

  /// Navigation hints (ids only). Never trusted for authorization: the
  /// target is re-read with the user's own permissions before opening.
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  String titleFor(String languageCode) =>
      languageCode == 'ar' && (titleAr?.isNotEmpty ?? false) ? titleAr! : title;

  String bodyFor(String languageCode) =>
      languageCode == 'ar' && (bodyAr?.isNotEmpty ?? false) ? bodyAr! : body;

  NotificationTarget get target => NotificationTarget.fromData(type, data);

  AppNotification markedRead(DateTime at) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    titleAr: titleAr,
    bodyAr: bodyAr,
    data: data,
    createdAt: createdAt,
    readAt: readAt ?? at,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return AppNotification(
      id: int.parse(json['id'].toString()),
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      titleAr: json['title_ar']?.toString(),
      bodyAr: json['body_ar']?.toString(),
      data: data is Map ? Map<String, dynamic>.from(data) : const {},
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      readAt: DateTime.tryParse(json['read_at']?.toString() ?? '')?.toLocal(),
    );
  }
}

/// Where tapping a notification leads.
sealed class NotificationTarget {
  const NotificationTarget();

  factory NotificationTarget.fromData(String type, Map<String, dynamic> data) {
    int? asInt(Object? value) =>
        value == null ? null : int.tryParse(value.toString());
    final ticketId = asInt(data['ticket_id']);
    final technicianId = asInt(data['technician_id']);

    // Requests addressed to the technician open their consent screen.
    const workerSide = {
      'tracking.requested',
      'tracking.cancelled',
      'tracking.stopped',
    };
    if (workerSide.contains(type)) return const MyLocationTarget();
    if (type.startsWith('tracking.') && technicianId != null) {
      return WorkerTrackingTarget(BigInt.from(technicianId));
    }
    if (ticketId != null) return TicketTarget(ticketId);
    return const NoTarget();
  }
}

final class TicketTarget extends NotificationTarget {
  const TicketTarget(this.ticketId);
  final int ticketId;
}

/// The technician's own location/requests screen.
final class MyLocationTarget extends NotificationTarget {
  const MyLocationTarget();
}

/// The admin's live view of one technician.
final class WorkerTrackingTarget extends NotificationTarget {
  const WorkerTrackingTarget(this.technicianId);
  final BigInt technicianId;
}

final class NoTarget extends NotificationTarget {
  const NoTarget();
}
