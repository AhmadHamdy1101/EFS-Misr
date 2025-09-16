import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../constants/constants.dart';
import '../../../Home/data/models/user.dart';
import '../../domain/auth_repo.dart';
part 'auth_state.dart';


class AuthCubit extends Cubit<AuthCubitState> {
  final auth = supabaseClient.auth;

  StreamSubscription<AuthState>? _sub;
  final AuthRepo authRepo;

  AuthCubit(this.authRepo) : super(AuthInitial());

  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    final response = await authRepo.login(email, password);
    response.fold(
      (l) {
        emit(LoginFailure(errorMsg:l.message));
      },
      (userId) async {
       final user =  await authRepo.getUserData(userId: userId);
        user.fold(
              (l) {
                print(l.message);
            emit(LoginFailure(errorMsg:l.message));
          },
              (user) {
            emit(LoginSuccess(user: user));
            emit(SessionExist(user: user));
          },
        );
      },
    );
  }



  Future<void> checkSession() async {
    final session = auth.currentSession;
    if (session?.user != null) {
      final res = await authRepo.getUserData(userId: session!.user.id);
      res.fold(
            (failure) {
          emit(SessionLoadFailed(failure.message)); // اعمل الحالة دي لو مش موجودة
        },
            (user) {
          emit(SessionExist(user: user));
        },
      );
    } else {
      emit(SessionNotExist());
    }

    await _sub?.cancel();
    _sub = auth.onAuthStateChange.listen((event) async {
      final newSession = event.session;
      if (newSession?.user != null) {
        final res = await authRepo.getUserData(userId: newSession!.user.id);
        res.fold(
              (failure) {
            emit(SessionLoadFailed(failure.message));
          },
              (user) {
            emit(SessionExist(user: user));
          },
        );
      } else {
        emit(SessionNotExist());
      }
    });
  }


  Future<void> addAccount({
    required String email,
    required String userName,
    required String password,
    required String phone,
    required String address,
    required String companyEmail,
    required String company,
    required BigInt position,
    required String role,
    required int status,
    required int userStatus,
  }) async
  {
    emit(RegisterLoading());
    final result = await authRepo.addAccount(email: email,password: password);
    result.fold(
      (l) {
        emit(RegisterFailure(errorMsg: l.message));
      },
      (userId) async {
        final savingData = await authRepo.saveUsersData(
          password: password,
          role: role,
          companyEmail: companyEmail,
          email: email,
          address: address,
          company:company,
          phone: phone,
          position: position,
          status: status,
          userID: userId,
          userName: userName,
          userStatus: userStatus
        );
        savingData.fold(
          (l) {
            emit(RegisterFailure(errorMsg: l.message));
          },
          (r) {
            emit(RegisterSuccess());
          },
        );
      },
    );
  }

  Future<void> logout() async {
    await auth.signOut();
    emit(SessionNotExist());
  }


  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
