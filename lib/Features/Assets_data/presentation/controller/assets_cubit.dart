import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_data_repo.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/Functions/convert_to_excel_function.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'assets_state.dart';

class AssetsCubit extends Cubit<AssetsState> {
  AssetsCubit(this.assetsRepo) : super(AssetsInitial());

  final AssetsDataRepo assetsRepo;
  final List<AssetsEntity> _allAssets = [];
  bool _hasLoaded = false;
  String _searchQuery = '';
  int? _areaFilter;
  int? _branchFilter;

  int? get selectedAreaId => _areaFilter;
  int? get selectedBranchId => _branchFilter;

  Future<void> getAssets() async {
    if (!_hasLoaded) emit(GetAssetsLoading());
    final result = await assetsRepo.getAssets();
    result.fold(
      (failure) {
        if (!_hasLoaded) emit(GetAssetsFailure(errMsg: failure.message));
      },
      (assets) {
        _allAssets
          ..clear()
          ..addAll(assets);
        _hasLoaded = true;
        _emitVisibleAssets();
      },
    );
  }

  void searchAssets(String? search) {
    _searchQuery = search?.trim().toLowerCase() ?? '';
    _emitVisibleAssets();
  }

  /// Search and filters are combined, so applying one never discards the other.
  void filterAssets({int? area, int? branch}) {
    _areaFilter = area;
    _branchFilter = branch;
    _emitVisibleAssets();
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
    return res.fold((failure) => Left(failure), (added) {
      _allAssets.addAll(added);
      _emitVisibleAssets();
      return const Right(unit);
    });
  }

  /// Drops the previous user's data. Called on sign-out.
  void reset() {
    _allAssets.clear();
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
        assets: List.unmodifiable(_allAssets.where(_matchesFilters)),
      ),
    );
  }

  bool _matchesFilters(AssetsEntity asset) {
    if (_areaFilter != null && asset.branchObject.areaId != _areaFilter) {
      return false;
    }
    if (_branchFilter != null && asset.branchObject.id != _branchFilter) {
      return false;
    }
    if (_searchQuery.isEmpty) return true;
    return asset.type.toLowerCase().contains(_searchQuery) ||
        asset.branchName.toLowerCase().contains(_searchQuery) ||
        asset.area.toLowerCase().contains(_searchQuery) ||
        asset.barCode.toLowerCase().contains(_searchQuery);
  }
}
