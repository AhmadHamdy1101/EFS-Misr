import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Home/data/data_source/remote_data_source.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:efs_misr/constants/constants.dart';
import 'package:efs_misr/core/Errors/failure.dart';

import '../../../../core/models/supadart_header.dart';
import '../../../../core/models/user.dart';

class HomeRepoImpl extends HomeRepo {
  HomeRemoteDataSource homeRemoteDataSource;

  HomeRepoImpl(this.homeRemoteDataSource);

  @override
  Future<Either<Failure, List<Users>>> getUsers() async {
    try {
      final users = await homeRemoteDataSource.getUsers();
      return Right(users);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }



  @override
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
  }) async {
    try {
       await supabaseClient.functions.invoke(
        'update-user',
        body: {'userId': userID, 'email': email, 'password': password},
      );
      final user = await supabaseClient.users
          .update(
            Users.update(
              address: address,
              company: company,
              companyEmail: companyEmail,
              email: email,
              name: userName,
              password: password,
              phone: phone,
              role: role,
              positionID: position,
              status: status,
            ),
          )
          .eq(Users.c_userid, userID)
          .select('*,positions(*)')
          .withConverter(Users.converter);
      return Right(user);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Users>> updateUserImage({
    required BigInt userID,
    required String? image,
  }) async {
    try {
      final user = await supabaseClient.users
          .update(Users.update(image: image))
          .eq(Users.c_id, userID)
          .select('*,positions(*)')
          .single()
          .withConverter(Users.converterSingle);
      return Right(user);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

}
