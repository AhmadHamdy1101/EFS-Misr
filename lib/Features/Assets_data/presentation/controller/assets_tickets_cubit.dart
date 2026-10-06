
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_data_repo.dart';
import 'package:efs_misr/Features/Tickets/domain/repo/tickets_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/assets.dart';
import '../../../../core/models/assets_repair.dart';
import '../../../../core/models/tickets.dart';

part 'assets_tickets_state.dart';

class AssetsTicketsCubit extends Cubit<AssetsTicketsState> {
  AssetsDataRepo assetsRepo;
  TicketsRepo ticketsRepo;

  AssetsTicketsCubit(this.assetsRepo, this.ticketsRepo) : super(AddAssetsTicketsInitial());

  final List<Assets> assets = [];
  final List<Tickets> tickets = [];

  Future<void> addAssetsAndTickets({
    required BigInt assetsId,
    required BigInt ticketId,
  }) async {
    final result = await assetsRepo.addAssetsAndTickets(
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
    final result = await assetsRepo.getAssetsWithTicketID(ticketId: ticketId);
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
    final result = await ticketsRepo.getTicketsWithAssetsID(assetId: assetId);
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
