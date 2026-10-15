part of 'auth_cubit.dart';

sealed class AuthCubitState {}

final class AuthInitial extends AuthCubitState {}

final class AuthLoading extends AuthCubitState {}

final class LoginFailure extends AuthCubitState {
  final String errorMsg;

  LoginFailure({required this.errorMsg});
}

final class SessionExist extends AuthCubitState {
  final UserEntity user;

  SessionExist({required this.user});
}

final class SessionNotExist extends AuthCubitState {}

final class SessionLoadFailed extends AuthCubitState {
  final String errMsg;

  SessionLoadFailed(this.errMsg);
}
