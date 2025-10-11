part of 'assets_cubit.dart';

sealed class AssetsState {}

final class AssetsInitial extends AssetsState {}

final class GetAssetsFailure extends AssetsState {
  final String errMsg;
  GetAssetsFailure({required this.errMsg});
}

final class GetAssetsSuccess extends AssetsState {
  final List<Assets> assets;
  GetAssetsSuccess({required this.assets});
}

final class GetAssetsLoading extends AssetsState {}

final class AddAssetsLoading extends AssetsState {}

class GetAssetsFiltered extends AssetsState {
  final List<Assets> assets;
  final bool resetDropdown;
  GetAssetsFiltered({required this.assets, this.resetDropdown = false});
}
