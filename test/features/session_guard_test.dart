import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Auth/domain/auth_repo.dart';
import 'package:efs_misr/Features/Auth/presentation/viewmodel/auth_cubit.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/auth/session_guard.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

final _user = UserEntity(
  id: BigInt.from(44),
  userid: 'uid-44',
  name: 'Tech',
  email: 't@efs.com',
  phone: '',
  address: '',
  role: 'Worker',
  status: 1,
  position: null,
  companyEmail: '',
  company: 'EFS',
  image: '',
);

class _FakeAuthRepo implements AuthRepo {
  _FakeAuthRepo({this.restoredUserId});

  String? restoredUserId;
  final events = StreamController<SessionEvent>.broadcast();
  final calls = <String>[];

  @override
  String? get currentUserId => restoredUserId;

  @override
  Stream<SessionEvent> get sessionEvents => events.stream;

  @override
  Future<Either<Failure, String>> login(String email, String password) async {
    calls.add('login');
    restoredUserId = _user.userid;
    return Right(_user.userid);
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    calls.add('logout');
    restoredUserId = null;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, UserEntity>> getUserData({
    required String userId,
  }) async {
    calls.add('profile');
    return Right(_user);
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfileImage({
    required UserEntity user,
    required File file,
  }) => throw UnimplementedError();
}

class _FakeGuard implements SessionGuard {
  _FakeGuard(this.status, {this.claimError});

  SessionCheck status;
  Object? claimError;
  final calls = <String>[];
  final changes = StreamController<void>.broadcast();
  int watchers = 0;

  @override
  Future<void> claim({required String deviceId}) async {
    calls.add('claim $deviceId');
    final error = claimError;
    if (error != null) throw error;
    status = SessionCheck.current;
  }

  @override
  Future<SessionCheck> check() async {
    calls.add('check');
    return status;
  }

  @override
  Stream<void> watch(String authUserId) {
    watchers++;
    return changes.stream;
  }
}

void main() {
  late _FakeAuthRepo repo;
  late _FakeGuard guard;
  late AuthCubit cubit;

  AuthCubit build({
    String? restored,
    SessionCheck? status,
    Object? claimError,
  }) {
    repo = _FakeAuthRepo(restoredUserId: restored);
    guard = _FakeGuard(status ?? SessionCheck.current, claimError: claimError);
    return cubit = AuthCubit(
      repo,
      sessionGuard: guard,
      deviceId: () => 'device-A',
    );
  }

  tearDown(() => cubit.close());

  group('sign-in', () {
    test('claims the session before loading the profile', () async {
      build();
      await cubit.login(email: 'e', password: 'p');
      expect(repo.calls, ['login', 'profile']);
      expect(guard.calls, ['claim device-A']);
      expect(cubit.state, isA<SessionExist>());
      expect(guard.watchers, 1);
    });

    test(
      'a session revoked meanwhile (concurrent sign-in) is refused',
      () async {
        build(claimError: const SessionEndedException());
        await cubit.login(email: 'e', password: 'p');
        expect(repo.calls, ['login', 'logout']);
        expect(cubit.state, isA<LoginFailure>());
      },
    );

    test('a failed claim (offline) never enters the app', () async {
      build(claimError: const SocketException('offline'));
      await cubit.login(email: 'e', password: 'p');
      expect(repo.calls, contains('logout'));
      expect(repo.calls, isNot(contains('profile')));
      expect(cubit.state, isA<LoginFailure>());
    });
  });

  group('restored session', () {
    test(
      'replaced while the app was closed: signed out with a reason',
      () async {
        build(restored: _user.userid, status: SessionCheck.replaced);
        await cubit.checkSession();
        expect(repo.calls, ['logout']);
        final state = cubit.state as SessionLoadFailed;
        expect(state.errMsg, AuthCubit.replacedMessage);
      },
    );

    test('unclaimed (older build) takes the session over', () async {
      build(restored: _user.userid, status: SessionCheck.unclaimed);
      await cubit.checkSession();
      expect(guard.calls, ['check', 'claim device-A']);
      expect(cubit.state, isA<SessionExist>());
    });

    test(
      'offline start keeps the user in; the server still enforces',
      () async {
        build(restored: _user.userid, status: SessionCheck.unknown);
        await cubit.checkSession();
        expect(cubit.state, isA<SessionExist>());
        expect(repo.calls, isNot(contains('logout')));
      },
    );
  });

  group('while signed in', () {
    Future<void> signedIn() async {
      build(restored: _user.userid);
      await cubit.checkSession();
      expect(cubit.state, isA<SessionExist>());
    }

    test('another device signs in: this one is signed out', () async {
      await signedIn();
      guard.status = SessionCheck.replaced;
      guard.changes.add(null);
      await pumpEventQueue();
      expect(cubit.state, isA<SessionLoadFailed>());
      expect(repo.calls.where((c) => c == 'logout'), hasLength(1));
    });

    test('a change that is still ours (e.g. re-claim) is ignored', () async {
      await signedIn();
      guard.changes.add(null);
      await pumpEventQueue();
      expect(cubit.state, isA<SessionExist>());
      expect(repo.calls, isNot(contains('logout')));
    });

    test('resume check and realtime at once sign out only once', () async {
      await signedIn();
      guard.status = SessionCheck.replaced;
      guard.changes.add(null);
      await Future.wait([cubit.verifySession(), cubit.verifySession()]);
      await pumpEventQueue();
      expect(repo.calls.where((c) => c == 'logout'), hasLength(1));
    });

    test('logout stops watching the session', () async {
      await signedIn();
      await cubit.logout();
      guard.status = SessionCheck.replaced;
      guard.changes.add(null);
      await pumpEventQueue();
      expect(cubit.state, isA<SessionNotExist>());
      expect(guard.calls.where((c) => c == 'check'), hasLength(1));
    });

    test('without a guard behaves as before', () async {
      repo = _FakeAuthRepo();
      guard = _FakeGuard(SessionCheck.current);
      cubit = AuthCubit(repo);
      await cubit.login(email: 'e', password: 'p');
      expect(cubit.state, isA<SessionExist>());
      await cubit.verifySession();
      expect(repo.calls, ['login', 'profile']);
    });
  });
}
