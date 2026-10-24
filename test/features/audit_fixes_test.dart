import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Auth/domain/auth_repo.dart';
import 'package:efs_misr/Features/Auth/presentation/viewmodel/auth_cubit.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/entities/positions_entity.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:efs_misr/core/models/assets.dart';
import 'package:flutter_test/flutter_test.dart';

UserEntity _user({int status = 1, String role = 'User'}) => UserEntity(
  id: BigInt.one,
  userid: 'uid-1',
  name: 'Mona',
  email: 'mona@efs.com',
  phone: '',
  address: '',
  role: role,
  status: status,
  position: PositionsEntity(id: 1, name: 'Technician'),
  companyEmail: '',
  company: 'EFS',
  image: '',
);

class _FakeAuthRepo implements AuthRepo {
  _FakeAuthRepo(this.user);

  final UserEntity user;
  int logouts = 0;

  @override
  String? get currentUserId => null;

  @override
  Stream<SessionEvent> get sessionEvents => const Stream.empty();

  @override
  Future<Either<Failure, String>> login(String email, String password) async =>
      Right(user.userid);

  @override
  Future<Either<Failure, Unit>> logout() async {
    logouts++;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, UserEntity>> getUserData({
    required String userId,
  }) async => Right(user);

  @override
  Future<Either<Failure, UserEntity>> updateProfileImage({
    required UserEntity user,
    required File file,
  }) async => Right(user);
}

void main() {
  group('disabled accounts', () {
    for (final status in [3, 4]) {
      test('status $status cannot sign in and is signed out', () async {
        final repo = _FakeAuthRepo(_user(status: status));
        final cubit = AuthCubit(repo);
        await cubit.login(email: 'mona@efs.com', password: 'x');
        expect(cubit.state, isA<LoginFailure>());
        expect(repo.logouts, 1);
        await cubit.close();
      });
    }

    test('active and internship accounts sign in', () async {
      for (final status in [1, 2]) {
        final cubit = AuthCubit(_FakeAuthRepo(_user(status: status)));
        await cubit.login(email: 'mona@efs.com', password: 'x');
        expect(cubit.state, isA<SessionExist>());
        await cubit.close();
      }
    });

    test('role helpers', () {
      expect(_user(role: 'Admin').isAdmin, isTrue);
      expect(_user().isAdmin, isFalse);
      expect(_user(status: 3).isDisabled, isTrue);
    });
  });

  test('an asset without a branch maps instead of crashing the list', () {
    final asset = Assets(
      id: BigInt.from(4),
      barcode: 'BC4',
      createdAt: DateTime(2026),
    ).toAssetsEntity();
    expect(asset.id, 4);
    expect(asset.branchName, '');
    expect(asset.branchObject.id, 0);
  });
}
