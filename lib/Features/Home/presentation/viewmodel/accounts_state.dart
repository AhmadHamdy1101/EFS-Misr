part of 'accounts_cubit.dart';

sealed class AccountsState {}

final class AccountsInitial extends AccountsState {}
final class GetAccountsSuccess extends AccountsState {
  final List<Users> accounts;
  GetAccountsSuccess(this.accounts);
}
final class GetAccountsLoading extends AccountsState {}
final class GetAccountsFailed extends AccountsState {
  final String errorMsg;
  GetAccountsFailed(this.errorMsg);
}

