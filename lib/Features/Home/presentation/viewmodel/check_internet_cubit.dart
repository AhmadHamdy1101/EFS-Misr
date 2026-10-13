import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'check_internet_state.dart';

class CheckInternetCubit extends Cubit<CheckInternetState> {
  final Connectivity _connectivity;
  late StreamSubscription _subscription;

  CheckInternetCubit(this._connectivity) : super(CheckInternetInitial()) {
    _subscription = _connectivity.onConnectivityChanged.listen(_updateState);
    checkInitialConnection();
  }

  Future<void> checkInitialConnection() async {
    final result = await _connectivity.checkConnectivity();
    _updateState(result);
  }

  void _updateState(List<ConnectivityResult> results) {
    if (isClosed) return;

    final isDisconnected =
        results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
    emit(isDisconnected ? InternetDisconnected() : InternetConnected());
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
