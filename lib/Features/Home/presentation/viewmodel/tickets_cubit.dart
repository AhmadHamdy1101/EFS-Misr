import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'tickets_state.dart';

class TicketsCubit extends Cubit<TicketsState> {
  HomeRepo homeRepo;

  TicketsCubit(this.homeRepo) : super(HomeInitial());

  int totalTickets = 0;
  int totalDoneTickets = 0;
  int totalAwaitingTickets = 0;

  final List<Tickets> allTickets = [];

  Future<void> getTickets() async {
    emit(GetTicketsLoading());
    final result = await homeRepo.getTickets();
    result.fold((failure) {
      emit(GetTicketsFailure(errMsg: failure.message));
    }, (tickets) {
      allTickets.clear();
      allTickets.addAll(tickets);
      totalTickets = tickets.length;
      totalDoneTickets = tickets.where((ticket) => ticket.status == 'Completed').length;
      totalAwaitingTickets = tickets.where((ticket) => ticket.status == 'Awaiting').length;
      emit(GetTicketsSuccess(tickets: allTickets));
    },);
  }

}
