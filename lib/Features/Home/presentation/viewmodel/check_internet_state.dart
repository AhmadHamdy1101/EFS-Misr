part of 'check_internet_cubit.dart';

sealed class CheckInternetState {}

final class CheckInternetInitial extends CheckInternetState {}

final class InternetConnected extends CheckInternetState {}

final class InternetDisconnected extends CheckInternetState {}
