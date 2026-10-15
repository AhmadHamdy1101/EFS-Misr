/// Ticket counts for the home overview, counted on the server so they stay
/// correct when only one page of tickets is loaded.
class TicketStats {
  final int total;
  final int completed;
  final int awaiting;

  const TicketStats({
    required this.total,
    required this.completed,
    required this.awaiting,
  });

  static const empty = TicketStats(total: 0, completed: 0, awaiting: 0);
}
