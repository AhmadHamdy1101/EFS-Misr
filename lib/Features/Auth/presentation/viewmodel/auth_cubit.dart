import 'dart:async';

import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/auth_repo.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthCubitState> {
  AuthCubit(this.authRepo) : super(AuthInitial());

  final AuthRepo authRepo;
  StreamSubscription<SessionEvent>? _sub;

  UserEntity? get currentUser {
    final current = state;
    return current is SessionExist ? current.user : null;
  }

  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    final response = await authRepo.login(email, password);
    await response.fold<Future<void>>(
      (failure) async => emit(LoginFailure(errorMsg: failure.message)),
      (userId) => _loadProfile(
        userId,
        onFailure: (message) => LoginFailure(errorMsg: message),
      ),
    );
  }

  Future<void> checkSession() async {
    emit(AuthLoading());
    final userId = authRepo.currentUserId;
    if (userId != null) {
      await _loadProfile(userId, onFailure: SessionLoadFailed.new);
    } else {
      emit(SessionNotExist());
    }

    await _sub?.cancel();
    _sub = authRepo.sessionEvents.listen((event) {
      switch (event) {
        case SessionEvent.signedOut:
          if (state is! SessionNotExist) emit(SessionNotExist());
        case SessionEvent.signedIn:
          // login() already loads the profile; only react to sign-ins that
          // happened elsewhere (e.g. a restored session).
          final userId = authRepo.currentUserId;
          if (state is! SessionExist &&
              state is! AuthLoading &&
              userId != null) {
            _loadProfile(userId, onFailure: SessionLoadFailed.new);
          }
      }
    });
  }

  Future<void> logout() async {
    await authRepo.logout();
    emit(SessionNotExist());
  }

  /// Replaces the signed-in user, e.g. after the profile photo changes.
  void updateCurrentUser(UserEntity user) {
    if (state is SessionExist) emit(SessionExist(user: user));
  }

  Future<void> _loadProfile(
    String userId, {
    required AuthCubitState Function(String message) onFailure,
  }) async {
    final res = await authRepo.getUserData(userId: userId);
    res.fold(
      (failure) => emit(onFailure(failure.message)),
      (user) => emit(SessionExist(user: user)),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
