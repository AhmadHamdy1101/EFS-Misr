part of 'assets_repair_cubit.dart';

sealed class AssetsRepairState {}

final class AssetsRepairInitial extends AssetsRepairState {}

final class GetAssetsRepairDataSuccess extends AssetsRepairState {
  final List<AssetsRepair> assetsRepair;

  GetAssetsRepairDataSuccess({required this.assetsRepair});
}

final class GetAssetsRepairDataFailed extends AssetsRepairState {
  final String errMsg;

  GetAssetsRepairDataFailed({required this.errMsg});
}

final class GetAssetsRepairDataLoading extends AssetsRepairState {}
