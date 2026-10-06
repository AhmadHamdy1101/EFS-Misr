import 'package:dartz/dartz.dart';
import 'package:efs_misr/core/Errors/failure.dart';

import '../../../../core/models/user.dart';

abstract class HomeRepo {

  Future<Either<Failure, List<Users>>> getUsers();








  Future<Either<Failure, List<Users>>> updateUserData({
    required String userID,
    required String? userName,
    required String? phone,
    required String? address,
    required BigInt? position,
    required int? status,
    required String? role,
    required String? companyEmail,
    required String? company,
    required String? email,
    required String? password,
  });
}
