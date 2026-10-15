import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/Functions/convert_to_excel_function.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:efs_misr/core/paging/page_loader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/accounts_repo.dart';

part 'accounts_state.dart';

/// Holds the account list, one page at a time; search runs on the server.
/// Actions return an [Either] so the calling widget decides how to show
/// success or failure (snackbar, navigation, ...).
class AccountsCubit extends Cubit<AccountsState> {
  AccountsCubit(
    this.accountsRepo, {
    Duration searchDebounce = const Duration(milliseconds: 300),
  }) : _searchDebouncer = Debouncer(searchDebounce),
       super(AccountsInitial()) {
    _pages = PageLoader(accountsRepo.getUsers, idOf: (user) => user.id);
  }

  final AccountsRepo accountsRepo;
  final Debouncer _searchDebouncer;
  late final PageLoader<UserEntity> _pages;
  String _searchQuery = '';
  bool _hasLoaded = false;

  /// Loads the first page for the current search.
  Future<void> getAccounts() async {
    if (!_hasLoaded) emit(GetAccountsLoading());
    final result = await _pages.reload(search: _searchQuery);
    if (result == null || isClosed) return;
    result.fold((failure) => emit(GetAccountsFailed(failure.message)), (_) {
      _hasLoaded = true;
      _emitVisible();
    });
  }

  Future<void> loadMore() async {
    if (!_hasLoaded || !_pages.canLoadMore) return;
    final loading = _pages.loadMore();
    _emitVisible();
    final result = await loading;
    if (result == null) return;
    result.fold(
      (failure) => developer.log(
        'Could not load more accounts: ${failure.message}',
        name: 'AccountsCubit',
      ),
      (_) {},
    );
    _emitVisible();
  }

  Future<void> searchUsers(String? search) {
    final query = search?.trim() ?? '';
    if (query == _searchQuery) return Future.value();
    _searchQuery = query;
    return _searchDebouncer.run(getAccounts);
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
      final index = _pages.items.indexWhere((u) => u.id == updated.id);
      if (index != -1) _pages.items[index] = updated;
      _emitVisible();
    });
    return result;
  }

  Future<Either<Failure, Unit>> deleteAccount(UserEntity user) async {
    final result = await accountsRepo.deleteAccount(user: user);
    result.fold((_) {}, (_) {
      _pages.items.removeWhere((u) => u.id == user.id);
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
    _searchDebouncer.cancel();
    _pages.clear();
    _searchQuery = '';
    _hasLoaded = false;
    emit(AccountsInitial());
  }

  void _emitVisible() {
    if (isClosed || !_hasLoaded) return;
    emit(
      GetAccountsSuccess(
        List.unmodifiable(_pages.items),
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
