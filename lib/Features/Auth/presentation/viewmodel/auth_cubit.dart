import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../constants/constants.dart';
import '../../domain/auth_repo.dart';
part 'auth_state.dart';


class AuthCubit extends Cubit<AuthCubitState> {
  final auth = supabaseClient.auth;

  StreamSubscription<AuthState>? _sub;
  final AuthRepo authRepo;

  AuthCubit(this.authRepo) : super(AuthInitial());

  Future<void> login({required String email, required String password}) async {
    print('loadinnnnnnnnnnggggggggggggggggggg');
    emit(AuthLoading());
    final response = await authRepo.login(email, password);
    response.fold(
      (l) {
        emit(LoginFailure(errorMsg:l.message));
      },
      (userId) async {
        print(userId+'user iddddddddddddddddddddddddddddd');
        emit(LoginSuccess(userId: userId));
        emit(SessionExist(userId: userId));
      },
    );
  }



  void checkSession() {
    final s = auth.currentSession;
    if (s?.user != null) {
      emit(SessionExist( userId: s!.user.id));
    } else {
      emit(SessionNotExist());
    }
    _sub?.cancel();
    _sub = auth.onAuthStateChange.listen((event) {
      final session = event.session;
      if (session?.user != null) {
        emit(SessionExist(userId: session!.user.id));
      } else {
        emit(SessionNotExist());
      }
    });
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
