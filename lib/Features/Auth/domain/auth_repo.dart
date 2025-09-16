import 'package:dartz/dartz.dart';

import '../../../core/Errors/failure.dart';
import '../../Home/data/models/user.dart';


abstract class AuthRepo {
  Future<Either<Failure, String>> saveUsersData(
  {
    required String userID,
    required String userName,
    required String phone,
    required String address,
    required BigInt position,
    required int status,
    required String role,
    required int userStatus,
    required String companyEmail,
    required String company,
    required String email,
    required String password,
}
  );

  Future<Either<Failure, String>> login(String email, String password);

  Future<Either<Failure,String>> addAccount({required String password,required String email});

  Future<Either<Failure, Users>> getUserData({required String userId});
}
