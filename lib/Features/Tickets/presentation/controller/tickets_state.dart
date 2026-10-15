part of 'tickets_cubit.dart';

sealed class TicketsState {}

final class HomeInitial extends TicketsState {}

final class GetTicketsLoading extends TicketsState {}

final class GetTicketsSuccess extends TicketsState {
  /// The loaded pages of the ticket list, matching the search and filters.
  final List<TicketEntity> tickets;

  /// The newest tickets regardless of search and filters (home page).
  final List<TicketEntity> recentTickets;

  /// Counts over every ticket, not just the loaded pages.
  final TicketStats stats;
  final bool hasMore;
  final bool isLoadingMore;

  /// Set when the list couldn't be reloaded for a new search or filter.
  final String? listError;

  GetTicketsSuccess({
    required this.tickets,
    this.recentTickets = const [],
    this.stats = TicketStats.empty,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.listError,
  });

  /// The latest loaded copy of a ticket, if it's in the list or recent ones.
  TicketEntity? findTicket(int id) {
    for (final ticket in tickets) {
      if (ticket.id == id) return ticket;
    }
    for (final ticket in recentTickets) {
      if (ticket.id == id) return ticket;
    }
    return null;
  }
}

final class GetTicketsFailure extends TicketsState {
  final String errMsg;
  GetTicketsFailure({required this.errMsg});
}
