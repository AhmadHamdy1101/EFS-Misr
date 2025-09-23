import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/supabase_functions.dart';
import '../../../../constants/constants.dart';
import '../../../../core/Errors/failure.dart';
import '../../../Home/data/models/user.dart';
import '../../domain/auth_repo.dart';
import '../source/remote_data_source.dart';

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



  @override
  Future<Either<Failure, String>> addAccount(
      {required String password, required String email}
  ) async {
    try {
      final result = await SupabaseFunctions.createUser(
        email: email,
        password: password,
      );

      if (result == null) {
        return Left(GeneralFailure("Unknown error"));
      }

      // لو رجع id
      if (result.length == 36) { // طول UUID دايمًا 36
        return Right(result);
      }
      return Left(GeneralFailure(result));
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, String>> saveUsersData({
    required String userID,
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
}) async {
    try {
      await supabaseClient.users.insert(
        Users.insert(
          userid: userID,
          email: email,
          status: status,
          address: address,
          phone: phone,
          createdAt: DateTime.now(),
          name: userName,
          positionID:position,
          companyEmail: companyEmail,
          company: company,
          role: role,
          password: password,
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
