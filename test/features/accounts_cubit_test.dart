import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Accounts/domain/accounts_repo.dart';
import 'package:efs_misr/Features/Accounts/presentation/controller/accounts_cubit.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
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

class _FakeAccountsRepo implements AccountsRepo {
  final users = [_user(1, 'Ahmed'), _user(2, 'Mona')];
  bool failDelete = false;

  @override
  Future<Either<Failure, List<UserEntity>>> getUsers() async =>
      Right(List.of(users));

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
  late _FakeAccountsRepo repo;
  late AccountsCubit cubit;

  setUp(() async {
    repo = _FakeAccountsRepo();
    cubit = AccountsCubit(repo);
    await cubit.getAccounts();
  });

  tearDown(() => cubit.close());

  test('search filters by name', () {
    cubit.searchUsers('mon');
    expect(_names(cubit), ['Mona']);
  });

  test('delete removes the user locally and keeps the search', () async {
    cubit.searchUsers('a');
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
}
