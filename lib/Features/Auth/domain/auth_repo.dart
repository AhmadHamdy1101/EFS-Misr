import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:efs_misr/core/entities/user_entity.dart';

import '../../../core/Errors/failure.dart';

enum SessionEvent { signedIn, signedOut }

abstract class AuthRepo {
  String? get currentUserId;

  /// Only the events the app reacts to. Token refreshes and the initial
  /// session event are filtered out so they don't trigger profile reloads.
  Stream<SessionEvent> get sessionEvents;

  Future<Either<Failure, String>> login(String email, String password);

  Future<Either<Failure, Unit>> logout();

  Future<Either<Failure, UserEntity>> getUserData({required String userId});

  Future<Either<Failure, UserEntity>> updateProfileImage({
    required UserEntity user,
    required File file,
  });
}
