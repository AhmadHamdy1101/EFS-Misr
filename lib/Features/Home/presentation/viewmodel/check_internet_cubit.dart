import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'check_internet_state.dart';

class CheckInternetCubit extends Cubit<CheckInternetState> {
  final Connectivity _connectivity;
  late StreamSubscription _subscription;

  CheckInternetCubit(this._connectivity) : super(CheckInternetInitial()) {
    checkInitialConnection();
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        emit(InternetDisconnected());
      } else {
        emit(InternetConnected());
      }
    });
  }
  Future<void> checkInitialConnection() async {
    final result = await _connectivity.checkConnectivity();
    if (result == ConnectivityResult.none) {
      emit(InternetDisconnected());
    } else {
      emit(InternetConnected());
    }
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
