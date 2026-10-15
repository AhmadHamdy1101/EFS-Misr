import 'package:dartz/dartz.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/Functions/convert_to_excel_function.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/accounts_repo.dart';

part 'accounts_state.dart';

/// Holds the account list. Actions return an [Either] so the calling widget
/// decides how to show success or failure (snackbar, navigation, ...).
class AccountsCubit extends Cubit<AccountsState> {
  AccountsCubit(this.accountsRepo) : super(AccountsInitial());

  final AccountsRepo accountsRepo;
  final List<UserEntity> _allUsers = [];
  String _searchQuery = '';
  bool _hasLoaded = false;

  Future<void> getAccounts() async {
    if (!_hasLoaded) emit(GetAccountsLoading());
    final result = await accountsRepo.getUsers();
    result.fold(
      (failure) {
        if (!_hasLoaded) emit(GetAccountsFailed(failure.message));
      },
      (accounts) {
        _allUsers
          ..clear()
          ..addAll(accounts);
        _hasLoaded = true;
        _emitVisible();
      },
    );
  }

  void searchUsers(String? search) {
    _searchQuery = search?.trim().toLowerCase() ?? '';
    _emitVisible();
  }

  Future<Either<Failure, Unit>> addAccount({
    required AccountForm form,
    required String password,
  }) async {
    final result = await accountsRepo.addAccount(
      form: form,
      password: password,
    );
    if (result.isRight()) await getAccounts();
    return result;
  }

  Future<Either<Failure, UserEntity>> updateAccount({
    required UserEntity user,
    required AccountForm form,
  }) async {
    final result = await accountsRepo.updateAccount(user: user, form: form);
    result.fold((_) {}, (updated) {
      final index = _allUsers.indexWhere((u) => u.id == updated.id);
      if (index != -1) _allUsers[index] = updated;
      _emitVisible();
    });
    return result;
  }

  Future<Either<Failure, Unit>> deleteAccount(UserEntity user) async {
    final result = await accountsRepo.deleteAccount(user: user);
    result.fold((_) {}, (_) {
      _allUsers.removeWhere((u) => u.id == user.id);
      _emitVisible();
    });
    return result;
  }

  Future<Either<Failure, ExcelExportStatus>> convertAccountsToExcel() async {
    final rows = await accountsRepo.getExportRows();
    return rows.fold((failure) async => Left(failure), (data) async {
      if (data.isEmpty) return const Right(ExcelExportStatus.noData);
      try {
        return Right(await saveRowsToExcel(data, fileNamePrefix: 'Users'));
      } catch (e) {
        return Left(Failure.fromException(e));
      }
    });
  }

  /// Drops the previous user's data. Called on sign-out.
  void reset() {
    _allUsers.clear();
    _searchQuery = '';
    _hasLoaded = false;
    emit(AccountsInitial());
  }

  void _emitVisible() {
    if (isClosed || !_hasLoaded) return;
    if (_searchQuery.isEmpty) {
      emit(GetAccountsSuccess(List.unmodifiable(_allUsers)));
      return;
    }
    final visible = _allUsers
        .where((user) {
          return user.name.toLowerCase().contains(_searchQuery) ||
              user.email.toLowerCase().contains(_searchQuery) ||
              user.company.toLowerCase().contains(_searchQuery);
        })
        .toList(growable: false);
    emit(GetAccountsSuccess(visible));
  }
}
