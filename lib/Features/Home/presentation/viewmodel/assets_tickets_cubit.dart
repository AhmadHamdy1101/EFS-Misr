import 'package:bloc/bloc.dart';
import 'package:efs_misr/Features/Home/data/models/assets.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';

import '../../data/models/assets_and_tickets.dart';

part 'assets_tickets_state.dart';

class AssetsTicketsCubit extends Cubit<AssetsTicketsState> {
  HomeRepo homeRepo;

  AssetsTicketsCubit(this.homeRepo) : super(AddAssetsTicketsInitial());

  final List<Assets> assets = [];

  Future<void> addAssetsAndTickets({
    required BigInt assetsId,
    required BigInt ticketId,
  }) async {
    final result = await homeRepo.addAssetsAndTickets(
      assetsId: assetsId,
      ticketId: ticketId,
    );
    result.fold((l) {
      print(l.message);
    }, (r) {
      getAssetsAndTickets(ticketId: ticketId);
emit(GetAssetsTicketsSuccess(assetsAndTickets: assets));
    });
  }

  Future<void> getAssetsAndTickets({required BigInt ticketId}) async {
    emit(GetAssetsTicketsLoading());
    final result = await homeRepo.getAssetsAndTickets(ticketId: ticketId);
    result.fold((l) {
      print(l.message);
      emit(GetAssetsTicketsFailure(message: l.message));
    }, (r) {
      assets.clear();
      assets.addAll(r);
      emit(GetAssetsTicketsSuccess(assetsAndTickets: assets));
    });
  }
}
