part of 'home_cubit.dart';

sealed class HomeState {}

final class HomeInitial extends HomeState {}
final class GetTicketsLoading extends HomeState {}
final class GetTicketsSuccess extends HomeState {
  final List<Tickets> tickets;

  GetTicketsSuccess({required this.tickets});
}
final class GetTicketsFailure extends HomeState {
  final String errMsg;
  GetTicketsFailure({required this.errMsg});
}

