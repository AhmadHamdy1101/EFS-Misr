part of 'accounts_cubit.dart';

sealed class AccountsState {}

final class AccountsInitial extends AccountsState {}

final class GetAccountsSuccess extends AccountsState {
  final List<UserEntity> accounts;
  final bool hasMore;
  final bool isLoadingMore;
  GetAccountsSuccess(
    this.accounts, {
    this.hasMore = false,
    this.isLoadingMore = false,
  });
}

final class GetAccountsLoading extends AccountsState {}

final class GetAccountsFailed extends AccountsState {
  final String errorMsg;
  GetAccountsFailed(this.errorMsg);
}
