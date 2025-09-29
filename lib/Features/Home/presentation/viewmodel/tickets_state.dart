part of 'tickets_cubit.dart';

sealed class TicketsState {}

final class HomeInitial extends TicketsState {}

final class GetTicketsLoading extends TicketsState {}

final class GetTicketsSuccess extends TicketsState {
  final List<Tickets> tickets;

  GetTicketsSuccess({required this.tickets});
}

final class GetTicketsFailure extends TicketsState {
  final String errMsg;
  GetTicketsFailure({required this.errMsg});
}
