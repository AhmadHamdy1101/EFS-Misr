part of 'tickets_cubit.dart';

sealed class TicketsState {}

final class HomeInitial extends TicketsState {}

final class GetTicketsLoading extends TicketsState {}

final class GetTicketsSuccess extends TicketsState {
  final List<TicketEntity> tickets;
  final List<TicketEntity> allTickets;

  GetTicketsSuccess({required this.tickets, required this.allTickets});
}

final class GetTicketsFailure extends TicketsState {
  final String errMsg;
  GetTicketsFailure({required this.errMsg});
}
