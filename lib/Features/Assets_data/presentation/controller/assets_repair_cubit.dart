import 'dart:developer';

import 'package:efs_misr/Features/Assets_data/domain/repo/assets_data_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../../../core/models/assets_repair.dart';
import '../../../../core/models/tickets.dart';
import '../../../../core/utils/app_colors.dart';

part 'assets_repair_state.dart';

class AssetsRepairCubit extends Cubit<AssetsRepairState> {
  AssetsDataRepo assetsRepo;
  final List<AssetsRepair> assetsRepair = [];

  AssetsRepairCubit(this.assetsRepo) : super(AssetsRepairInitial());

  Future<void> getAssetsRepairDetails({required BigInt ticketID,required BigInt assetID}) async {
    emit(GetAssetsRepairDataLoading(assetID: assetID));

    final res = await assetsRepo.getAssetsRepairWithTicketID(ticketID: ticketID);

    res.fold(
      (fail) {
        emit(GetAssetsRepairDataFailed(errMsg: fail.message,));
      },
      (data) {
        emit(GetAssetsRepairDataSuccess(assetsRepair: data, assetID: assetID));
      },
    );
  }

  Future<void> getAssetsRepairDetailsWithAssetId({
    required BigInt assetID,
  }) async {
    emit(GetAssetsRepairDataInAssetsPageLoading());
    final res = await assetsRepo.getAssetsRepairWithAssetId(assetID: assetID);
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
    final result = await assetsRepo.addAssetsRepairs(
      assetsId: assetsId,
      ticketId: ticketId,
      variation: variation,
      comment: comment,
      amount: amount,
    );
    result.fold(
      (l) {
        log("Error while updating ticket");
      },
      (r) {
        Get.snackbar(
          'Success',
          'Details Added Successfully',
          backgroundColor: AppColors.green,
        );
        emit(UpdateTicketDataSuccess(tickets: r));
      },
    );
  }
}
