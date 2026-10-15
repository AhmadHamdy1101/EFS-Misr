part of 'assets_cubit.dart';

sealed class AssetsState {}

final class AssetsInitial extends AssetsState {}

final class GetAssetsFailure extends AssetsState {
  final String errMsg;
  GetAssetsFailure({required this.errMsg});
}

final class GetAssetsSuccess extends AssetsState {
  final List<AssetsEntity> assets;
  final bool hasMore;
  final bool isLoadingMore;
  GetAssetsSuccess({
    required this.assets,
    this.hasMore = false,
    this.isLoadingMore = false,
  });
}

final class GetAssetsLoading extends AssetsState {}
