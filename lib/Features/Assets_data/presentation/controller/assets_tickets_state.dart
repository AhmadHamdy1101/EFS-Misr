part of 'assets_tickets_cubit.dart';

sealed class AssetsTicketsState {}

final class AddAssetsTicketsInitial extends AssetsTicketsState {}

final class AddAssetsTicketsSuccess extends AssetsTicketsState {}

final class AddAssetsTicketsFailed extends AssetsTicketsState {}

final class AddAssetsTicketsLoading extends AssetsTicketsState {}

final class GetAssetsTicketsLoading extends AssetsTicketsState {}

final class GetAssetsTicketsSuccess extends AssetsTicketsState {
  final List<AssetsWithAssetsRepairEntity> assetsAndTickets;
  GetAssetsTicketsSuccess({required this.assetsAndTickets});
}

final class GetAssetsTicketsFailure extends AssetsTicketsState {
  final String message;
  GetAssetsTicketsFailure({required this.message});
}

final class GetAssetsRepairSuccess extends AssetsTicketsState {
  final List<AssetsRepair> assetsRepairData;

  GetAssetsRepairSuccess({required this.assetsRepairData});
}
