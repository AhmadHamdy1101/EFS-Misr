import 'package:dartz/dartz.dart';

import '../../../core/Errors/failure.dart';
import '../../Home/data/models/user.dart';


abstract class AuthRepo {
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
  );

  Future<Either<Failure, String>> login(String email, String password);

  Future<Either<Failure, String>> addAccount(String email, String password);

  Future<Either<Failure, Users>> getUserData({required String userId});
}
