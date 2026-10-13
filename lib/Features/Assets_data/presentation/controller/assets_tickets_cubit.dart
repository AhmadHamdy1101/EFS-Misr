import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_data_repo.dart';
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_repair_repository.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/asset_repair_totals.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/asset_repair_entity.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/ticket_asset_repairs_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/Errors/failure.dart';

part 'assets_tickets_state.dart';

class AssetsTicketsCubit extends Cubit<AssetsTicketsState> {
  AssetsTicketsCubit(this.assetsRepo, this.assetsRepairRepository)
    : super(AddAssetsTicketsInitial());

  final AssetsDataRepo assetsRepo;
  final AssetsRepairRepository assetsRepairRepository;

  List<TicketAssetRepairsEntity> assets = [];

  Future<Either<Failure, String>> addAssetsAndTickets({
    required BigInt assetsId,
    required BigInt ticketId,
  }) async {
    final result = await assetsRepo.addAssetsAndTickets(
      assetsId: assetsId,
      ticketId: ticketId,
    );
    return result.fold<Future<Either<Failure, String>>>(
      (failure) async {
        emit(GetAssetsTicketsFailure(message: failure.message));
        return Left(failure);
      },
      (message) async {
        await getAssetsWithTicketId(ticketId: ticketId);
        return Right(message);
      },
    );
  }

  Future<void> getAssetsWithTicketId({required BigInt ticketId}) async {
    emit(GetAssetsTicketsLoading());
    final repairsFuture = assetsRepairRepository.getRepairsForTicket(
      ticketId: ticketId,
    );
    final result = await assetsRepo.getAssetsWithTicketID(ticketId: ticketId);
    await result.fold<Future<void>>(
      (l) async {
        emit(GetAssetsTicketsFailure(message: l.message));
      },
      (r) async {
        try {
          final repairResult = await repairsFuture;
          final repairs = repairResult.fold(
            (failure) => throw StateError(failure.message),
            (data) => data,
          );
          final repairsByAsset = <BigInt, List<AssetRepairEntity>>{};
          for (final repair in repairs) {
            final assetId = repair.assetId;
            if (assetId == null) continue;
            repairsByAsset.putIfAbsent(assetId, () => []).add(repair);
          }

          assets = r.map((asset) {
            final assetRepairs =
                repairsByAsset[BigInt.from(asset.id)] ??
                const <AssetRepairEntity>[];
            final totals = AssetRepairTotals.fromRepairs(assetRepairs);
            return TicketAssetRepairsEntity(
              asset: asset,
              repairs: assetRepairs,
              totalAmount: totals.assetTicketTotal,
            );
          }).toList(growable: false);
          emit(GetAssetsTicketsSuccess(assetsAndTickets: assets));
        } catch (error) {
          emit(GetAssetsTicketsFailure(message: error.toString()));
        }
      },
    );
  }
}
