import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/add_asset_repair_result.dart';
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_repair_repository.dart';
import 'package:efs_misr/Features/Assets_data/domain/usecases/add_asset_repair_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/Errors/failure.dart';
import '../../domain/entities/asset_repair_entity.dart';

part 'assets_repair_state.dart';

class AssetsRepairCubit extends Cubit<AssetsRepairState> {
  final AssetsRepairRepository assetsRepairRepository;
  final AddAssetRepairUseCase addAssetRepair;
  final List<AssetRepairEntity> assetsRepair = [];

  AssetsRepairCubit({
    required this.assetsRepairRepository,
    required this.addAssetRepair,
  }) : super(AssetsRepairInitial());

  Future<void> getAssetsRepairDetailsWithAssetId({
    required BigInt assetID,
  }) async {
    emit(GetAssetsRepairDataInAssetsPageLoading());
    final res = await assetsRepairRepository.getRepairsForAsset(
      assetId: assetID,
    );
    res.fold(
      (fail) {
        emit(GetAssetsRepairDataInAssetsPageFailed(errMsg: fail.message));
      },
      (data) {
        assetsRepair.clear();
        assetsRepair.addAll(data);
        emit(GetAssetsRepairDataInAssetsPageSuccess(assetsRepair: data));
      },
    );
  }

  Future<Either<Failure, AddAssetRepairResult>> addAssetsRepair({
    required BigInt assetsId,
    required BigInt ticketId,
    required String variation,
    required String comment,
    required num amount,
  }) async {
    final result = await addAssetRepair(
      assetId: assetsId,
      ticketId: ticketId,
      variation: variation,
      comment: comment,
      amount: amount,
    );
    return result;
  }
}
