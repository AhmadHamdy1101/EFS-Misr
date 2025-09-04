import 'package:bloc/bloc.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:meta/meta.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeRepo homeRepo;
  HomeCubit(this.homeRepo) : super(HomeInitial());

  Future<void> getTickets()async{
    emit(GetTicketsLoading());
    final result = await homeRepo.getTickets();
    result.fold((failure) {
      emit(GetTicketsFailure(errMsg: failure.message));
    }, (tickets) {
      emit(GetTicketsSuccess(tickets: tickets));
    },);
  }
}
