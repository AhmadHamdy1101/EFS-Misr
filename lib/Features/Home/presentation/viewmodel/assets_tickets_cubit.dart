import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/Features/Home/domain/entities/asset_with_asset_repair_entitiy.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:efs_misr/constants/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'assets_tickets_state.dart';

class AssetsTicketsCubit extends Cubit<AssetsTicketsState> {
  HomeRepo homeRepo;

  AssetsTicketsCubit(this.homeRepo) : super(AddAssetsTicketsInitial());

  final List<Tickets> tickets = [];
  List<AssetsWithAssetsRepairEntity> assetsDetails = [];

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
        emit(GetAssetsTicketsSuccess(assetsAndTickets: assetsDetails));
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
        assetsDetails = await Future.wait(futures);
        emit(GetAssetsTicketsSuccess(assetsAndTickets: assetsDetails));
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
