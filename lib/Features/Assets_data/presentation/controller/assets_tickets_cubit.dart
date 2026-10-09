
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_data_repo.dart';
import 'package:efs_misr/Features/Tickets/domain/repo/tickets_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/constants.dart';
import '../../../../core/models/assets_repair.dart';
import '../../../../core/models/supadart_header.dart';
import '../../../../core/models/tickets.dart';
import '../../../Home/domain/entities/asset_with_asset_repair_entitiy.dart';

part 'assets_tickets_state.dart';

class AssetsTicketsCubit extends Cubit<AssetsTicketsState> {
  AssetsDataRepo assetsRepo;
  TicketsRepo ticketsRepo;

  AssetsTicketsCubit(this.assetsRepo, this.ticketsRepo) : super(AddAssetsTicketsInitial());

   List<AssetsWithAssetsRepairEntity> assets = [];
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
      (r) async {
        List<Future<AssetsWithAssetsRepairEntity>> futures = r.map((p) async {
          var assetsRepair = await supabaseClient.AssetsRepair.select()
              .eq(AssetsRepair.c_assetsId, p.id)
              .eq(AssetsRepair.c_TicketsId, ticketId)
              .withConverter(AssetsRepair.converter);
          final num totalAmount = assetsRepair.fold<num>(
            0,
                (sum, repair) => sum + (repair.amount ?? 0),
          );
          return AssetsWithAssetsRepairEntity(
            assets: p,
            assetsRepair: assetsRepair,
            totalAmount: totalAmount,
          );
        }).toList();
        assets = await Future.wait(futures);
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
