import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Accounts/domain/accounts_repo.dart';
import 'package:efs_misr/Features/Accounts/presentation/controller/accounts_cubit.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:efs_misr/core/paging/page_query.dart';
import 'package:flutter_test/flutter_test.dart';

UserEntity _user(int id, String name) => UserEntity(
  id: BigInt.from(id),
  userid: 'uid-$id',
  name: name,
  email: '${name.toLowerCase()}@efs.com',
  phone: '',
  address: '',
  role: 'User',
  status: 1,
  position: null,
  companyEmail: '',
  company: 'EFS',
  image: '',
);

/// Pages and searches an in-memory list the way the Supabase query does.
class _FakeAccountsRepo implements AccountsRepo {
  _FakeAccountsRepo([List<UserEntity>? users])
    : users = users ?? [_user(1, 'Ahmed'), _user(2, 'Mona')];

  final List<UserEntity> users;
  final queries = <PageQuery>[];
  bool failDelete = false;

  @override
  Future<Either<Failure, List<UserEntity>>> getUsers(PageQuery query) async {
    queries.add(query);
    final search = query.search.toLowerCase();
    final matching = users
        .where((u) => search.isEmpty || u.name.toLowerCase().contains(search))
        .toList();
    return Right(matching.skip(query.from).take(query.pageSize).toList());
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount({
    required UserEntity user,
  }) async {
    if (failDelete) return Left(GeneralFailure('nope'));
    users.removeWhere((u) => u.id == user.id);
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<String> _names(AccountsCubit cubit) =>
    (cubit.state as GetAccountsSuccess).accounts.map((u) => u.name).toList();

void main() {
  group('search and delete', () {
    late _FakeAccountsRepo repo;
    late AccountsCubit cubit;

    setUp(() async {
      repo = _FakeAccountsRepo();
      cubit = AccountsCubit(repo, searchDebounce: Duration.zero);
      await cubit.getAccounts();
    });

    tearDown(() => cubit.close());

    test('search is sent to the server', () async {
      await cubit.searchUsers('mon');
      expect(_names(cubit), ['Mona']);
      expect(repo.queries.last.search, 'mon');
      expect(repo.queries.last.page, 0);
    });

    test('delete removes the user locally and keeps the search', () async {
      await cubit.searchUsers('a');
      final result = await cubit.deleteAccount(repo.users.first);
      expect(result.isRight(), isTrue);
      expect(_names(cubit), ['Mona']);
    });

    test('failed delete returns the failure and keeps the list', () async {
      repo.failDelete = true;
      final result = await cubit.deleteAccount(repo.users.first);
      expect(result.isLeft(), isTrue);
      expect(_names(cubit), ['Ahmed', 'Mona']);
    });
  });

  group('paging', () {
    late _FakeAccountsRepo repo;
    late AccountsCubit cubit;

    setUp(() async {
      repo = _FakeAccountsRepo([
        for (var id = 1; id <= 45; id++) _user(id, 'User $id'),
      ]);
      cubit = AccountsCubit(repo, searchDebounce: Duration.zero);
      await cubit.getAccounts();
    });

    tearDown(() => cubit.close());

    test('loads one page, then the rest on loadMore', () async {
      var state = cubit.state as GetAccountsSuccess;
      expect(state.accounts, hasLength(PageQuery.defaultPageSize));
      expect(state.hasMore, isTrue);

      await cubit.loadMore();
      state = cubit.state as GetAccountsSuccess;
      expect(state.accounts, hasLength(45));
      expect(state.hasMore, isFalse);
      expect(repo.queries.last.page, 1);
    });

    test('searching after loading more shows only search results', () async {
      final loading = cubit.loadMore();
      await cubit.searchUsers('User 4');
      await loading;
      expect(_names(cubit), everyElement(contains('User 4')));
    });

    test('reset clears the list', () async {
      cubit.reset();
      expect(cubit.state, isA<AccountsInitial>());
      await cubit.loadMore();
      expect(cubit.state, isA<AccountsInitial>());
    });
  });
}
