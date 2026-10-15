import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_data_repo.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/Functions/convert_to_excel_function.dart';
import 'package:efs_misr/core/paging/page_loader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'assets_state.dart';

/// Holds the asset list, one page at a time; search and filters run on the
/// server so they cover every asset, not just the loaded pages.
class AssetsCubit extends Cubit<AssetsState> {
  AssetsCubit(
    this.assetsRepo, {
    Duration searchDebounce = const Duration(milliseconds: 300),
  }) : _searchDebouncer = Debouncer(searchDebounce),
       super(AssetsInitial()) {
    _pages = PageLoader(assetsRepo.getAssets, idOf: (asset) => asset.id);
  }

  final AssetsDataRepo assetsRepo;
  final Debouncer _searchDebouncer;
  late final PageLoader<AssetsEntity> _pages;
  bool _hasLoaded = false;
  String _searchQuery = '';
  int? _areaFilter;
  int? _branchFilter;

  int? get selectedAreaId => _areaFilter;
  int? get selectedBranchId => _branchFilter;

  /// Loads the first page for the current search and filters.
  Future<void> getAssets() async {
    if (!_hasLoaded) emit(GetAssetsLoading());
    final result = await _pages.reload(
      search: _searchQuery,
      areaId: _areaFilter,
      branchId: _branchFilter,
    );
    if (result == null || isClosed) return;
    result.fold((failure) => emit(GetAssetsFailure(errMsg: failure.message)), (
      _,
    ) {
      _hasLoaded = true;
      _emitVisibleAssets();
    });
  }

  Future<void> loadMore() async {
    if (!_hasLoaded || !_pages.canLoadMore) return;
    final loading = _pages.loadMore();
    _emitVisibleAssets();
    final result = await loading;
    if (result == null) return;
    result.fold(
      (failure) => developer.log(
        'Could not load more assets: ${failure.message}',
        name: 'AssetsCubit',
      ),
      (_) {},
    );
    _emitVisibleAssets();
  }

  Future<void> searchAssets(String? search) {
    final query = search?.trim() ?? '';
    if (query == _searchQuery) return Future.value();
    _searchQuery = query;
    return _searchDebouncer.run(getAssets);
  }

  /// Search and filters are combined, so applying one never discards the other.
  Future<void> filterAssets({int? area, int? branch}) {
    _areaFilter = area;
    _branchFilter = branch;
    return getAssets();
  }

  Future<Either<Failure, ExcelExportStatus>> convertAssetsToExcel() async {
    final rows = await assetsRepo.getExportRows();
    return rows.fold((failure) async => Left(failure), (data) async {
      if (data.isEmpty) return const Right(ExcelExportStatus.noData);
      try {
        return Right(await convertDataToExcel(data));
      } catch (e) {
        return Left(Failure.fromException(e));
      }
    });
  }

  Future<Either<Failure, Unit>> addAssetsData({
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
    // Reload so the new asset shows in its sorted place, and only when it
    // matches the current search and filters.
    if (res.isRight()) await getAssets();
    return res.map((_) => unit);
  }

  /// Drops the previous user's data. Called on sign-out.
  void reset() {
    _searchDebouncer.cancel();
    _pages.clear();
    _hasLoaded = false;
    _searchQuery = '';
    _areaFilter = null;
    _branchFilter = null;
    emit(AssetsInitial());
  }

  void _emitVisibleAssets() {
    if (isClosed || !_hasLoaded) return;
    emit(
      GetAssetsSuccess(
        assets: List.unmodifiable(_pages.items),
        hasMore: _pages.hasMore,
        isLoadingMore: _pages.isLoadingMore,
      ),
    );
  }

  @override
  Future<void> close() {
    _searchDebouncer.cancel();
    return super.close();
  }
}
