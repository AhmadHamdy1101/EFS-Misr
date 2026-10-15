import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/Errors/failure.dart';
import '../../domain/auth_repo.dart';
import '../source/remote_data_source.dart';

class AuthRepoImpl extends AuthRepo {
  final AuthRemoteData authRemoteData;

  AuthRepoImpl(this.authRemoteData);

  @override
  String? get currentUserId => authRemoteData.currentUserId;

  @override
  Stream<SessionEvent> get sessionEvents => authRemoteData.authEvents
      .where(
        (event) =>
            event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.signedOut,
      )
      .map(
        (event) => event == AuthChangeEvent.signedIn
            ? SessionEvent.signedIn
            : SessionEvent.signedOut,
      );

  @override
  Future<Either<Failure, String>> login(String email, String password) async {
    try {
      return Right(
        await authRemoteData.signIn(email: email, password: password),
      );
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await authRemoteData.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getUserData({
    required String userId,
  }) async {
    try {
      final user = await authRemoteData.getUserData(userId: userId);
      return Right(user.toUserEntity());
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfileImage({
    required UserEntity user,
    required File file,
  }) async {
    try {
      final updated = await authRemoteData.uploadProfileImage(
        id: user.id,
        userId: user.userid,
        file: file,
        previousImageUrl: user.image,
      );
      return Right(updated.toUserEntity());
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }
}
