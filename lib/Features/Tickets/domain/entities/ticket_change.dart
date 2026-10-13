import 'ticket_entity.dart';

/// A ticket row inserted, updated, or removed while a screen is listening.
class TicketChange {
  final int id;
  final TicketEntity? ticket;

  const TicketChange({required this.id, this.ticket});
}
