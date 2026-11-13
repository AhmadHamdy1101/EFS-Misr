import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Tracking/domain/entities/tracking_session.dart';
import 'package:efs_misr/Features/Tracking/domain/entities/tracking_worker.dart';
import 'package:efs_misr/Features/Tracking/domain/repo/tracking_repo.dart';
import 'package:efs_misr/Features/Tracking/presentation/controller/tracking_control_cubit.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tracking_fakes.dart';

void main() {
  late FakeTrackingRepo repo;
  late TrackingControlCubit cubit;
  final now = epoch.add(const Duration(hours: 1));
  final inTenMinutes = now.add(const Duration(minutes: 10));

  LocationUpdate position(int technician, int session, DateTime receivedAt) =>
      LocationUpdate(
        uidOf(technician),
        sessionId: 's$session',
        latitude: 30.2,
        longitude: 31.3,
        accuracy: 6,
        receivedAt: receivedAt,
      );

  setUp(() async {
    repo = FakeTrackingRepo()
      ..workers = [
        worker(1, 'Mohamed Ali'),
        worker(2, 'Ahmed Hassan'),
        worker(3, 'Omar Khaled'),
        worker(4, 'Sara Adel'),
      ]
      ..openSessions = [
        session(10, technician: 1, lastLocationAt: now),
        session(
          11,
          technician: 3,
          lastLocationAt: now.subtract(const Duration(minutes: 10)),
        ),
        session(
          12,
          technician: 4,
          status: TrackingStatus.pending,
          expiresAt: inTenMinutes,
        ),
      ];
    cubit = TrackingControlCubit(
      repo,
      clock: () => now,
      reconnectDelay: const Duration(milliseconds: 1),
    );
    await cubit.start();
  });

  tearDown(() => cubit.close());

  test('classifies workers as live, offline, pending and not sharing', () {
    final state = cubit.state;
    expect(state.workers, hasLength(4));
    expect(state.countOf(WorkerTrackingState.live), 1);
    expect(state.countOf(WorkerTrackingState.offline), 1);
    expect(state.countOf(WorkerTrackingState.pending), 1);
    expect(state.countOf(WorkerTrackingState.notSharing), 1);
    expect(state.mappedWorkers.map((w) => w.user.name), [
      'Mohamed Ali',
      'Omar Khaled',
    ]);
  });

  test('an expired pending request counts as not sharing', () async {
    repo.openSessions = [
      session(12, technician: 4, status: TrackingStatus.pending),
    ];
    await cubit.refresh();
    expect(
      cubit.state.workerById(BigInt.from(4))!.stateAt(now),
      WorkerTrackingState.notSharing,
    );
  });

  test('filters and search narrow the list', () {
    cubit.setFilter(WorkerFilter.offline);
    expect(cubit.state.visibleWorkers.single.user.name, 'Omar Khaled');
    cubit.setFilter(WorkerFilter.all);
    cubit.search('ahmed');
    expect(cubit.state.visibleWorkers.single.user.name, 'Ahmed Hassan');
  });

  test('a position update makes a stale worker live again', () async {
    repo.emit(position(3, 11, now));
    await settle();
    expect(cubit.state.countOf(WorkerTrackingState.live), 2);
    expect(cubit.state.sessions[BigInt.from(3)]!.latitude, 30.2);
  });

  test('an older position arriving late does not move the marker', () async {
    repo.emit(position(1, 10, now.subtract(const Duration(seconds: 30))));
    await settle();
    expect(cubit.state.sessions[BigInt.one]!.latitude, 30.05);
  });

  test('a position for an old session is ignored', () async {
    repo.emit(position(1, 99, now.add(const Duration(seconds: 5))));
    await settle();
    expect(cubit.state.sessions[BigInt.one]!.latitude, 30.05);
  });

  test('a declined request is removed and announced', () async {
    repo.emit(SessionUpdate(uidOf(4), endedAs: TrackingStatus.declined));
    await settle();
    expect(cubit.state.sessions.containsKey(BigInt.from(4)), isFalse);
    expect(cubit.state.notice, contains('declined'));
    expect(cubit.state.notices, hasLength(1));
  });

  test('acceptance replaces the request with the session', () async {
    repo.emit(SessionUpdate(uidOf(4), session: session(13, technician: 4)));
    await settle();
    expect(cubit.state.sessions[BigInt.from(4)]!.status, TrackingStatus.active);
    expect(cubit.state.notice, contains('accepted'));
  });

  test('request applies the returned item', () async {
    repo.actionResult = const Right(TrackingStatus.pending);
    repo.openAfterAction = [
      ...repo.openSessions,
      session(
        20,
        technician: 2,
        status: TrackingStatus.pending,
        expiresAt: inTenMinutes,
      ),
    ];
    final result = await cubit.requestLocation(repo.workers[1]);
    expect(result.isRight(), isTrue);
    expect(
      cubit.state.workerById(BigInt.two)!.stateAt(now),
      WorkerTrackingState.pending,
    );
  });

  test('a rejected request leaves the state unchanged', () async {
    repo.actionResult = Left(GeneralFailure('This ticket is closed.'));
    final result = await cubit.requestLocation(repo.workers[1]);
    expect(result.isLeft(), isTrue);
    expect(cubit.state.sessions.containsKey(BigInt.two), isFalse);
  });

  test('cancel removes the session', () async {
    final current = cubit.state.sessions[BigInt.one]!;
    repo.actionResult = const Right(TrackingStatus.cancelled);
    await cubit.cancel(current);
    expect(cubit.state.sessions.containsKey(BigInt.one), isFalse);
  });

  test('realtime drop resubscribes and reloads', () async {
    repo.openSessions = [];
    repo.emitError();
    await settle(20);
    expect(repo.watchCount, 2);
    expect(cubit.state.sessions, isEmpty);
    expect(cubit.state.realtimeLost, isFalse);
  });

  test('reset closes the realtime subscription and clears data', () async {
    await cubit.reset();
    expect(repo.hasListener, isFalse);
    expect(cubit.state.workers, isEmpty);
  });

  test('freshness is measured from the server receive time', () {
    final s = session(
      1,
      technician: 1,
      lastLocationAt: now.subtract(TrackingSession.staleAfter),
    );
    expect(s.isStale(now), isFalse);
    expect(s.isStale(now.add(const Duration(seconds: 1))), isTrue);
  });
}
