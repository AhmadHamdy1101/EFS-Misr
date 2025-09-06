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
            emit(LoginFailure(errorMsg:l.message));
          },
              (user) {
            emit(LoginSuccess(user: user));
            emit(SessionExist(user: user));
          },
        );
        // emit(LoginSuccess(userId: userId));
        // emit(SessionExist(userId: userId));
      },
    );
  }



  Future<void> checkSession() async {
    final s = auth.currentSession;
    if (s?.user != null) {
      final user =  await authRepo.getUserData(userId: s!.user.id);
      user.fold((l) {
        emit(SessionNotExist());
      }, (r) {
        emit(SessionExist( user: r));
      },);
    } else {
      emit(SessionNotExist());
    }
    // _sub?.cancel();
    // _sub = auth.onAuthStateChange.listen((event) async {
    //   final session = event.session;
    //   if (session?.user != null) {
    //     final user =  await authRepo.getUserData(userId: s!.user.id);
    //     user.fold((l) {
    //       emit(SessionNotExist());
    //     }, (r) {
    //       emit(SessionExist( user: r));
    //     },);
    //   } else {
    //     emit(SessionNotExist());
    //   }
    // });
  }


  Future<void> addAccount({
    required String email,
    required String password,
    required String userName,
    required String phone,
    required String address,
    required String companyEmail,
    required int position,
    required double salary,
    required int status,
  }) async
  {
    emit(RegisterLoading());
    final result = await authRepo.addAccount(email, password);
    result.fold(
      (l) {
        emit(RegisterFailure(errorMsg: l.message));
      },
      (userId) async {
        final savingData = await authRepo.saveUsersData(
          userId,
          userName,
          phone,
          address,
          position,
          salary,
          status,
          companyEmail,
          email,
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
