import 'dart:developer';
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

  searchAssets(String? search) {
    if (search == null || search.isEmpty) {
      emit(GetAssetsSuccess(assets: allAssets));
      return;
    }
    searchedAssets.clear();
    final res = allAssets.where((asset) {
      final nameMatch = asset.type.toLowerCase().contains(search);
      final branchName =
          asset.branchName.toLowerCase().contains(search) ;
      final areaName =
          asset.area.toLowerCase().contains(search) ;
      final barcode = asset.barCode.toLowerCase().contains(search) ;
      return nameMatch || branchName || areaName || barcode;
    }).toList();
    searchedAssets.addAll(res);
    emit(GetAssetsSuccess(assets: searchedAssets));
  }

  Future<void> convertAssetsToExcel() async {
    try {
      final data = await supabaseClient.assetsAndTickets.select('id,tickets(orecal_id),assets(barcode,name,branch(name),floor,place,area,type),Ammount');
      if (data.isEmpty) {
        return;
      }
      await convertDataToExcel(data);
    } catch (e) {
     log(e.toString());
    }
  }
  void filterAssets({int? area, int? branch}) {
    filterdAssets.clear();

    final res = allAssets.where((asset) {
      final matchArea = area == null ||
          asset.branchObject.areaId == area;
      final matchBranch = branch == null ||
          asset.branchObject.id == branch;
      return matchBranch || matchArea;
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
    res.fold(
          (l) {
        Get.snackbar(
          'Error',
          l.message,
          backgroundColor: Colors.red,
          colorText: AppColors.white,
        );
      },
          (r) {
        getAssets();
        emit(GetAssetsSuccess(assets: allAssets));
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
