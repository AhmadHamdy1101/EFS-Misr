import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../domain/repo/home_repo.dart';

part 'assets_repair_state.dart';

class AssetsRepairCubit extends Cubit<AssetsRepairState> {
  HomeRepo homeRepo;
  final List<AssetsRepair> assetsRepair = [];
  final Map<BigInt, List<AssetsRepair>> repairsPerAsset = {};

  AssetsRepairCubit(this.homeRepo) : super(AssetsRepairInitial());

  Future<void> getAssetsRepairDetailsWithAssetIdInTicketPage({
    required BigInt assetID,
    required BigInt ticketID,
  }) async {
    emit(GetAssetsRepairDataLoading(assetID: assetID));

    final res = await homeRepo.getAssetsRepairWithAssetIdAndTicketID(
      assetID: assetID,
      ticketID: ticketID,
    );
    res.fold(
      (fail) {
        emit(GetAssetsRepairDataFailed(assetID: assetID, errMsg: fail.message));
      },
      (data) {
        repairsPerAsset[assetID] = data;
        emit(GetAssetsRepairDataSuccess(assetID: assetID, assetsRepair: data));
      },
    );
  }

  List<AssetsRepair> getRepairsForAsset(BigInt assetID) {
    return repairsPerAsset[assetID] ?? [];
  }

  Future<void> getAssetsRepairDetailsWithAssetId({
    required BigInt assetID,
  }) async {
    emit(GetAssetsRepairDataInAssetsPageLoading());
    final res = await homeRepo.getAssetsRepairWithAssetId(assetID: assetID);
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

  Future<void> addAssetsRepair({
    required BigInt assetsId,
    required BigInt ticketId,
    required String variation,
    required String comment,
    required num amount,
  }) async {
    final result = await homeRepo.addAssetsRepairs(
      assetsId: assetsId,
      ticketId: ticketId,
      variation: variation,
      comment: comment,
      amount: amount,
    );
    result.fold(
      (l) {
        print(l.message);
      },
      (r) async {
        Get.snackbar(
          'Success',
          'Details Added Successfully',
          backgroundColor: AppColors.green,
        );
        emit(UpdateTicketDataSuccess(tickets: r));
      },
    );
  }

  num getTotalForAsset(BigInt assetId) {
    return assetsRepair
        .where((e) => e.assetsId == assetId)
        .fold<num>(0, (sum, e) => sum + (e.amount ?? 0));
  }
}

// Future<void> getAssetsRepairDetails({required BigInt ticketID}) async {
//   emit(GetAssetsRepairDataLoading());
//
//   final res = await homeRepo.getAssetsRepairWithTicketID(ticketID: ticketID);
//
//   res.fold(
//     (fail) {
//       print(fail.message);
//       emit(GetAssetsRepairDataFailed(errMsg: fail.message));
//     },
//     (data) {
//       emit(GetAssetsRepairDataSuccess(assetsRepair: data));
//     },
//   );
// }
