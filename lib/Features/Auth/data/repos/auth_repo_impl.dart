import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Auth/data/models/supadart_header.dart';


import '../../../../constants/constants.dart';
import '../../../../core/Errors/failure.dart';
import '../../domain/auth_repo.dart';
import '../DataSources/remote_data_source.dart';
import '../models/users.dart';

class AuthRepoImpl extends AuthRepo {
  final AuthRemoteData authRemoteData;

  AuthRepoImpl(this.authRemoteData);
  @override
  Future<Either<Failure, String>> login(String email, String password) async {
    try {
      final res = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final userId = res.user?.id;
      if (userId == null) return Left(GeneralFailure('Login failed: user missing'));
      return Right(userId);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  // @override
  // Future<Either<Failure, String>> login(String email, String password) async {
  //   try {
  //     final signIn = await supabaseClient.auth.signInWithPassword(
  //       password: password,
  //       email: email,
  //     );
  //     return Right(signIn.user!.id);
  //   } catch (e) {
  //     final failure = Failure.fromException(e);
  //     return Left(failure);
  //   }
  // }

  @override
  Future<Either<Failure, String>> addAccount(
    String email,
    String password,
  ) async {
    try {
      final signUp = await supabaseClient.auth.signUp(
        password: password,
        email: email,
      );
      final userId = signUp.user?.id;
      if (userId==null) {
        return Left(GeneralFailure('Login failed: user missing'));
      }
      else {
        return Right(userId);
      }
    } catch (e) {
      final failure = Failure.fromException(e);
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, String>> saveUsersData(
    String userID,
    String userName,
    String phone,
    String address,
    int position,
    double salary,
    int status,
    String companyEmail,
    String email,
  ) async {
    try {
      await supabaseClient.users.insert(
        Users.insert(
          id: userID,
          email: email,
          status: status,
          address: address,
          phone: phone,
          companyEmail: companyEmail,
          createdAt: DateTime.now(),
          position: position,
          salary: salary,
          userName: userName,
        ),
      );
      return Right(userID);
    } catch (e) {
      final failure = Failure.fromException(e);
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, Users>> getUserData({
    required String userId,
  }) async {
    try {
      final user = await authRemoteData.getUserData(userId: userId);
      return Right(user);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }
}
