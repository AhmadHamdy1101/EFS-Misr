part of 'assets_repair_cubit.dart';

sealed class AssetsRepairState {}

final class AssetsRepairInitial extends AssetsRepairState {}

final class GetAssetsRepairDataSuccess extends AssetsRepairState {
  final List<AssetsRepair> assetsRepair;
  final BigInt assetID;
  GetAssetsRepairDataSuccess({
    required this.assetsRepair,
    required this.assetID,
  });
}

final class GetAssetsRepairDataFailed extends AssetsRepairState {
  final String errMsg;
  final BigInt assetID;
  GetAssetsRepairDataFailed({required this.errMsg, required this.assetID});
}

final class GetAssetsRepairDataLoading extends AssetsRepairState {
  final BigInt assetID;

  GetAssetsRepairDataLoading({required this.assetID});
}

final class GetAssetsRepairDataInAssetsPageSuccess extends AssetsRepairState {
  final List<AssetsRepair> assetsRepair;

  GetAssetsRepairDataInAssetsPageSuccess({required this.assetsRepair});
}

final class GetAssetsRepairDataInAssetsPageFailed extends AssetsRepairState {
  final String errMsg;

  GetAssetsRepairDataInAssetsPageFailed({required this.errMsg});
}

final class GetAssetsRepairDataInAssetsPageLoading extends AssetsRepairState {}

final class UpdateTicketDataSuccess extends AssetsRepairState {
  final Tickets tickets;
  UpdateTicketDataSuccess({required this.tickets});
}
