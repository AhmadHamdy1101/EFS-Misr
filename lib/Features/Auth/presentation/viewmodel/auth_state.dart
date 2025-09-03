part of 'auth_cubit.dart';

sealed class AuthCubitState {}

final class AuthInitial extends AuthCubitState {}
final class Authoading extends AuthCubitState {}

final class LoginSuccess extends AuthCubitState {
  final String userId;

  LoginSuccess({required this.userId});
}

final class LoginFailure extends AuthCubitState {
  final String errorMsg;

  LoginFailure({required this.errorMsg});
}

final class SessionExist extends AuthCubitState {
  String userId;
  SessionExist({required this.userId});
}
final class SessionNotExist extends AuthCubitState {
}


final class RegisterSuccess extends AuthCubitState {}

final class RegisterFailure extends AuthCubitState {
  final String errorMsg;

  RegisterFailure({required this.errorMsg});
}

final class RegisterLoading extends AuthCubitState {}
