import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_data_repo.dart';
import 'package:efs_misr/Features/Assets_data/presentation/controller/assets_cubit.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/entities/branch_entity.dart';
import 'package:efs_misr/core/paging/page_query.dart';
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

/// Pages and filters an in-memory list the way the Supabase query does.
class _FakeAssetsRepo implements AssetsDataRepo {
  _FakeAssetsRepo(this.assets);

  final List<AssetsEntity> assets;
  final queries = <PageQuery>[];

  @override
  Future<Either<Failure, List<AssetsEntity>>> getAssets(PageQuery query) async {
    queries.add(query);
    final search = query.search.toLowerCase();
    final matching = assets.where((asset) {
      if (query.areaId != null && asset.branchObject.areaId != query.areaId) {
        return false;
      }
      if (query.branchId != null && asset.branchObject.id != query.branchId) {
        return false;
      }
      return search.isEmpty || asset.type.toLowerCase().contains(search);
    }).toList();
    return Right(matching.skip(query.from).take(query.pageSize).toList());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<int> _visibleIds(AssetsCubit cubit) =>
    (cubit.state as GetAssetsSuccess).assets.map((a) => a.id).toList();

void main() {
  group('search and filters', () {
    late _FakeAssetsRepo repo;
    late AssetsCubit cubit;

    setUp(() async {
      repo = _FakeAssetsRepo([
        _asset(1, branch: 10, area: 1, type: 'Furniture'),
        _asset(2, branch: 10, area: 1, type: 'Electricity'),
        _asset(3, branch: 20, area: 2, type: 'Furniture'),
      ]);
      cubit = AssetsCubit(repo, searchDebounce: Duration.zero);
      await cubit.getAssets();
    });

    tearDown(() => cubit.close());

    test('search and filter combine and are sent to the server', () async {
      await cubit.filterAssets(branch: 10);
      await cubit.searchAssets('furniture');
      expect(_visibleIds(cubit), [1]);
      expect(repo.queries.last.branchId, 10);
      expect(repo.queries.last.search, 'furniture');
      expect(repo.queries.last.page, 0);

      await cubit.searchAssets('');
      expect(_visibleIds(cubit), [1, 2]);
    });

    test('area filter keeps the search query', () async {
      await cubit.searchAssets('furniture');
      await cubit.filterAssets(area: 2);
      expect(_visibleIds(cubit), [3]);
    });

    test('reset clears data and filters', () async {
      await cubit.filterAssets(area: 2);
      cubit.reset();
      expect(cubit.state, isA<AssetsInitial>());
      expect(cubit.selectedAreaId, isNull);
    });
  });

  group('paging', () {
    late _FakeAssetsRepo repo;
    late AssetsCubit cubit;

    setUp(() async {
      repo = _FakeAssetsRepo([
        for (var id = 1; id <= 70; id++) _asset(id, branch: 10, area: 1),
      ]);
      cubit = AssetsCubit(repo, searchDebounce: Duration.zero);
      await cubit.getAssets();
    });

    tearDown(() => cubit.close());

    test('loads one page first', () {
      final state = cubit.state as GetAssetsSuccess;
      expect(state.assets, hasLength(PageQuery.defaultPageSize));
      expect(state.hasMore, isTrue);
    });

    test('loadMore appends pages until a short page', () async {
      await cubit.loadMore();
      expect(_visibleIds(cubit), hasLength(60));
      expect((cubit.state as GetAssetsSuccess).hasMore, isTrue);

      await cubit.loadMore();
      final state = cubit.state as GetAssetsSuccess;
      expect(_visibleIds(cubit), [for (var id = 1; id <= 70; id++) id]);
      expect(state.hasMore, isFalse);

      final calls = repo.queries.length;
      await cubit.loadMore();
      expect(repo.queries.length, calls, reason: 'no request past the end');
    });

    test('a new search starts again from the first page', () async {
      await cubit.loadMore();
      await cubit.searchAssets('furn');
      expect(repo.queries.last.page, 0);
      expect(_visibleIds(cubit), hasLength(PageQuery.defaultPageSize));
    });

    test('only the last of quick searches is sent', () async {
      final debounced = AssetsCubit(
        repo,
        searchDebounce: const Duration(milliseconds: 20),
      );
      await debounced.getAssets();
      final calls = repo.queries.length;
      debounced.searchAssets('f');
      debounced.searchAssets('fu');
      await debounced.searchAssets('fur');
      expect(repo.queries.length, calls + 1);
      expect(repo.queries.last.search, 'fur');
      await debounced.close();
    });
  });
}
