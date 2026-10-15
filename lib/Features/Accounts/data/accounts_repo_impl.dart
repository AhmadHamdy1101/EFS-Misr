import 'package:dartz/dartz.dart';

import '../../../core/Errors/failure.dart';
import '../../../core/entities/user_entity.dart';
import '../../../core/paging/page_query.dart';
import '../domain/accounts_repo.dart';
import 'accounts_remote_data_source.dart';

class AccountsRepoImpl implements AccountsRepo {
  AccountsRepoImpl(this._dataSource);

  final AccountsRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, List<UserEntity>>> getUsers(PageQuery query) async {
    try {
      final users = await _dataSource.getUsers(query);
      return Right(users.map((user) => user.toUserEntity()).toList());
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> addAccount({
    required AccountForm form,
    required String password,
  }) async {
    try {
      await _dataSource.addAccount(form: form, password: password);
      return const Right(unit);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateAccount({
    required UserEntity user,
    required AccountForm form,
  }) async {
    try {
      final updated = await _dataSource.updateAccount(
        userId: user.userid,
        emailChanged: form.email.trim() != user.email.trim(),
        form: form,
      );
      return Right(updated.toUserEntity());
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount({
    required UserEntity user,
  }) async {
    try {
      await _dataSource.deleteAccount(userId: user.userid);
      return const Right(unit);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getExportRows() async {
    try {
      return Right(await _dataSource.getExportRows());
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }
}
