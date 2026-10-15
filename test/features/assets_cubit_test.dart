import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_data_repo.dart';
import 'package:efs_misr/Features/Assets_data/presentation/controller/assets_cubit.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/entities/branch_entity.dart';
import 'package:flutter_test/flutter_test.dart';

AssetsEntity _asset(
  int id, {
  required int branch,
  required int area,
  String type = 'Furniture',
}) {
  return AssetsEntity(
    id: id,
    type: type,
    branchName: 'Branch $branch',
    barCode: 'BC$id',
    place: '',
    totalAmount: 0,
    area: 'Area $area',
    branchObject: BranchEntity(
      name: 'Branch $branch',
      id: branch,
      areaId: area,
    ),
  );
}

class _FakeAssetsRepo implements AssetsDataRepo {
  _FakeAssetsRepo(this.assets);

  final List<AssetsEntity> assets;

  @override
  Future<Either<Failure, List<AssetsEntity>>> getAssets() async =>
      Right(assets);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<int> _visibleIds(AssetsCubit cubit) =>
    (cubit.state as GetAssetsSuccess).assets.map((a) => a.id).toList();

void main() {
  late AssetsCubit cubit;

  setUp(() async {
    cubit = AssetsCubit(
      _FakeAssetsRepo([
        _asset(1, branch: 10, area: 1, type: 'Furniture'),
        _asset(2, branch: 10, area: 1, type: 'Electricity'),
        _asset(3, branch: 20, area: 2, type: 'Furniture'),
      ]),
    );
    await cubit.getAssets();
  });

  tearDown(() => cubit.close());

  test('search and filter combine instead of overwriting each other', () {
    cubit.filterAssets(branch: 10);
    cubit.searchAssets('furniture');
    expect(_visibleIds(cubit), [1]);

    cubit.searchAssets('');
    expect(_visibleIds(cubit), [1, 2]);
  });

  test('area filter keeps the search query', () {
    cubit.searchAssets('furniture');
    cubit.filterAssets(area: 2);
    expect(_visibleIds(cubit), [3]);
  });

  test('reset clears data and filters', () {
    cubit.filterAssets(area: 2);
    cubit.reset();
    expect(cubit.state, isA<AssetsInitial>());
    expect(cubit.selectedAreaId, isNull);
  });
}
