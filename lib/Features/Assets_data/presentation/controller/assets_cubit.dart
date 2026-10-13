import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_data_repo.dart';
import 'package:efs_misr/core/Functions/convert_to_excel_function.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../../../constants/constants.dart';
import '../../../../core/models/supadart_header.dart';
import '../../../../core/utils/app_colors.dart';

part 'assets_state.dart';

class AssetsCubit extends Cubit<AssetsState> {
  AssetsDataRepo assetsRepo;

  AssetsCubit(this.assetsRepo) : super(AssetsInitial());

  final List<AssetsEntity> allAssets = [];
  final List<AssetsEntity> searchedAssets = [];
  final List<AssetsEntity> filterdAssets = [];

  Future<void> getAssets() async {
    emit(GetAssetsLoading());
    final result = await assetsRepo.getAssets();

    result.fold(
      (failure) {
        emit(GetAssetsFailure(errMsg: failure.message));
      },
      (assets) {
        allAssets.clear();
        allAssets.addAll(assets);
        emit(GetAssetsSuccess(assets: allAssets));
      },
    );
  }

  void searchAssets(String? search) {
    final query = search?.trim().toLowerCase() ?? '';
    if (query.isEmpty) {
      emit(GetAssetsSuccess(assets: allAssets));
      return;
    }
    searchedAssets.clear();
    final res = allAssets.where((asset) {
      final nameMatch = asset.type.toLowerCase().contains(query);
      final branchName = asset.branchName.toLowerCase().contains(query);
      final areaName = asset.area.toLowerCase().contains(query);
      final barcode = asset.barCode.toLowerCase().contains(query);
      return nameMatch || branchName || areaName || barcode;
    }).toList();
    searchedAssets.addAll(res);
    emit(GetAssetsSuccess(assets: searchedAssets));
  }

  Future<ExcelExportStatus> convertAssetsToExcel() async {
    final data = await supabaseClient.assetsAndTickets.select(
      'id,tickets(orecal_id),assets(barcode,name,branch(name),floor,place,area,type),Ammount',
    );
    if (data.isEmpty) return ExcelExportStatus.noData;

    return convertDataToExcel(data);
  }

  void filterAssets({int? area, int? branch}) {
    filterdAssets.clear();

    final res = allAssets.where((asset) {
      final matchArea = area == null || asset.branchObject.areaId == area;
      final matchBranch = branch == null || asset.branchObject.id == branch;
      return matchBranch && matchArea;
    }).toList();

    filterdAssets.addAll(res);
    emit(GetAssetsSuccess(assets: filterdAssets));
  }

  Future<void> addAssetsData({
    required String? barcode,
    required String? name,
    required String? floor,
    required String? place,
    required String? type,
    required BigInt? branch,
  }) async {
    final res = await assetsRepo.addAssets(
      barcode: barcode,
      name: name,
      floor: floor,
      place: place,
      type: type,
      branch: branch,
    );
    await res.fold<Future<void>>(
      (l) async {
        Get.snackbar(
          'Error',
          l.message,
          backgroundColor: Colors.red,
          colorText: AppColors.white,
        );
      },
      (r) async {
        await getAssets();
        Get.snackbar(
          "Add Assets Success",
          'Assets Added Successfully',
          backgroundColor: AppColors.green,
          colorText: AppColors.white,
        );
      },
    );
  }
}
