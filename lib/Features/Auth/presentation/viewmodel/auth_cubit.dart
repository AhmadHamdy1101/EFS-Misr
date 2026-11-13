import 'dart:async';

import 'package:efs_misr/core/auth/session_guard.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/auth_repo.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthCubitState> {
  AuthCubit(
    this.authRepo, {
    SessionGuard? sessionGuard,
    String Function()? deviceId,
  }) : _guard = sessionGuard,
       _deviceId = deviceId ?? (() => ''),
       super(AuthInitial());

  final AuthRepo authRepo;

  /// One active device per account (server-enforced); optional so tests
  /// and builds without it behave as before.
  final SessionGuard? _guard;
  final String Function() _deviceId;
  StreamSubscription<SessionEvent>? _sub;
  StreamSubscription<void>? _sessionWatch;
  bool _verifying = false;

  static const replacedMessage =
      'This account signed in on another device, so you were signed out here.';

  UserEntity? get currentUser {
    final current = state;
    return current is SessionExist ? current.user : null;
  }

  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    final response = await authRepo.login(email, password);
    await response.fold<Future<void>>(
      (failure) async => emit(LoginFailure(errorMsg: failure.message)),
      (userId) async {
        // Claim before loading anything: it revokes the account's other
        // devices, and nothing is shown unless this device holds the session.
        final claimError = await _claim();
        if (claimError != null) {
          await authRepo.logout();
          emit(LoginFailure(errorMsg: claimError));
          return;
        }
        await _loadProfile(
          userId,
          onFailure: (message) => LoginFailure(errorMsg: message),
        );
      },
    );
  }

  Future<void> checkSession() async {
    emit(AuthLoading());
    final userId = authRepo.currentUserId;
    if (userId != null) {
      final guard = _guard;
      final check = guard == null ? SessionCheck.current : await guard.check();
      switch (check) {
        case SessionCheck.replaced:
          await authRepo.logout();
          emit(SessionLoadFailed(replacedMessage));
        case SessionCheck.unclaimed:
          // Signed in with an older build: take the session over now.
          final claimError = await _claim();
          if (claimError != null) {
            await authRepo.logout();
            emit(SessionLoadFailed(claimError));
          } else {
            await _loadProfile(userId, onFailure: SessionLoadFailed.new);
          }
        case SessionCheck.current || SessionCheck.unknown:
          // Unknown = offline: the database still refuses a replaced
          // session; the watch and the next resume check catch up.
          await _loadProfile(userId, onFailure: SessionLoadFailed.new);
      }
    } else {
      emit(SessionNotExist());
    }

    await _sub?.cancel();
    _sub = authRepo.sessionEvents.listen((event) {
      switch (event) {
        case SessionEvent.signedOut:
          _stopWatch();
          if (state is! SessionNotExist && state is! SessionLoadFailed) {
            emit(SessionNotExist());
          }
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

  /// Asks the server whether this device still holds the session (app
  /// resume, or the account's session changed). Signs out if it doesn't.
  Future<void> verifySession() async {
    final guard = _guard;
    if (guard == null || _verifying || state is! SessionExist) return;
    _verifying = true;
    try {
      if (await guard.check() == SessionCheck.replaced &&
          state is SessionExist) {
        _stopWatch();
        // Local sign-out still happens if the server call fails (the
        // session is already revoked there).
        await authRepo.logout();
        emit(SessionLoadFailed(replacedMessage));
      }
    } finally {
      _verifying = false;
    }
  }

  Future<void> logout() async {
    _stopWatch();
    await authRepo.logout();
    emit(SessionNotExist());
  }

  /// Replaces the signed-in user, e.g. after the profile photo changes.
  void updateCurrentUser(UserEntity user) {
    if (state is SessionExist) emit(SessionExist(user: user));
  }

  /// Null on success, else the message to show.
  Future<String?> _claim() async {
    final guard = _guard;
    if (guard == null) return null;
    try {
      await guard.claim(deviceId: _deviceId());
      return null;
    } on SessionEndedException {
      return 'This session has ended. Please sign in again.';
    } catch (_) {
      return 'Could not start the session. Check your connection and try again.';
    }
  }

  void _startWatch(UserEntity user) {
    final guard = _guard;
    if (guard == null) return;
    _sessionWatch?.cancel();
    _sessionWatch = guard.watch(user.userid).listen((_) => verifySession());
  }

  void _stopWatch() {
    _sessionWatch?.cancel();
    _sessionWatch = null;
  }

  Future<void> _loadProfile(
    String userId, {
    required AuthCubitState Function(String message) onFailure,
  }) async {
    final res = await authRepo.getUserData(userId: userId);
    await res.fold<Future<void>>(
      (failure) async => emit(onFailure(failure.message)),
      (user) async {
        if (user.isDisabled) {
          // Terminated or suspended: end the session instead of entering.
          await authRepo.logout();
          emit(
            onFailure('This account is disabled. Contact your administrator.'),
          );
          return;
        }
        emit(SessionExist(user: user));
        _startWatch(user);
      },
    );
  }

  @override
  Future<void> close() async {
    _stopWatch();
    await _sub?.cancel();
    return super.close();
  }
}
