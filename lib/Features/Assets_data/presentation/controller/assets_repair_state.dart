part of 'assets_repair_cubit.dart';

sealed class AssetsRepairState {}

final class AssetsRepairInitial extends AssetsRepairState {}

final class GetAssetsRepairDataInAssetsPageSuccess extends AssetsRepairState {
  final List<AssetRepairEntity> assetsRepair;

  GetAssetsRepairDataInAssetsPageSuccess({required this.assetsRepair});
}

final class GetAssetsRepairDataInAssetsPageFailed extends AssetsRepairState {
  final String errMsg;

  GetAssetsRepairDataInAssetsPageFailed({required this.errMsg});
}

final class GetAssetsRepairDataInAssetsPageLoading extends AssetsRepairState {}
