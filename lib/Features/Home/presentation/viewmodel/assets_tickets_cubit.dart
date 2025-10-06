import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'assets_tickets_state.dart';

class AssetsTicketsCubit extends Cubit<AssetsTicketsState> {
  HomeRepo homeRepo;

  AssetsTicketsCubit(this.homeRepo) : super(AddAssetsTicketsInitial());

  final List<Assets> assets = [];
  final List<Tickets> tickets = [];

  Future<void> addAssetsAndTickets({
    required BigInt assetsId,
    required BigInt ticketId,
  }) async {
    final result = await homeRepo.addAssetsAndTickets(
      assetsId: assetsId,
      ticketId: ticketId,
    );
    result.fold(
      (l) {
        print(l.message);
      },
      (r) {
        getAssetsWithTicketId(ticketId: ticketId);
        emit(GetAssetsTicketsSuccess(assetsAndTickets: assets));
      },
    );
  }

  Future<void> getAssetsWithTicketId({required BigInt ticketId}) async {
    emit(GetAssetsTicketsLoading());
    final result = await homeRepo.getAssetsWithTicketID(ticketId: ticketId);
    result.fold(
      (l) {
        print(l.message);
        emit(GetAssetsTicketsFailure(message: l.message));
      },
      (r) {
        assets.clear();
        assets.addAll(r);
        emit(GetAssetsTicketsSuccess(assetsAndTickets: assets));
      },
    );
  }

  Future<void> getTicketsWithAssetsId({required BigInt assetId}) async {
    emit(GetAssetsTicketsLoading());
    final result = await homeRepo.getTicketsWithAssetsID(assetId: assetId);
    result.fold(
      (l) {
        print(l.message);
      },
      (r) {
        tickets.clear();
        tickets.addAll(r);
      },
    );
  }
}
