import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Tracking/data/location_source.dart';
import 'package:efs_misr/Features/Tracking/domain/entities/tracking_session.dart';
import 'package:efs_misr/Features/Tracking/domain/entities/tracking_worker.dart';
import 'package:efs_misr/Features/Tracking/domain/repo/tracking_repo.dart';
import 'package:efs_misr/Features/Tracking/presentation/controller/my_tracking_cubit.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tracking_fakes.dart';

void main() {
  final me = worker(7, 'Ahmed Hassan');
  late FakeTrackingRepo repo;
  late FakeLocationSource location;
  late MyTrackingCubit cubit;

  MyTrackingCubit build({
    Duration minPublishInterval = Duration.zero,
    Duration heartbeat = const Duration(minutes: 10),
  }) => MyTrackingCubit(
    repo: repo,
    location: location,
    deviceId: 'device-1',
    minPublishInterval: minPublishInterval,
    heartbeatInterval: heartbeat,
    reconnectDelay: const Duration(milliseconds: 1),
  );

  final pending = session(1, technician: 7, status: TrackingStatus.pending);
  final active = session(1, technician: 7);

  setUp(() {
    repo = FakeTrackingRepo();
    location = FakeLocationSource();
    cubit = build();
  });

  tearDown(() => cubit.close());

  group('requests and consent', () {
    test('a pending request collects no location before consent', () async {
      repo.openSessions = [pending];
      await cubit.start(me);
      expect(cubit.state.pendingRequest?.id, 'r1');
      expect(location.watchCount, 0);
      expect(location.requestCount, 0);
      expect(repo.published, isEmpty);
    });

    test('accept without permission fails and does not accept', () async {
      repo.openSessions = [pending];
      await cubit.start(me);
      location.access = LocationAccess.denied;

      final result = await cubit.accept();
      expect(result.isLeft(), isTrue);
      expect(repo.calls, isNot(contains('accept')));
      expect(location.watchCount, 0);
    });

    test('accept starts publishing on this device', () async {
      repo.openSessions = [pending];
      repo.openAfterAction = [active];
      await cubit.start(me);

      final result = await cubit.accept();
      expect(result.isRight(), isTrue);
      expect(cubit.state.sharing, isTrue);

      location.push(fix(30.1, epoch));
      await settle();
      expect(repo.published.single.latitude, 30.1);
      expect(cubit.state.lastPublishedAt, isNotNull);
    });

    test('decline clears the request without touching location', () async {
      repo.openSessions = [pending];
      repo.actionResult = const Right(TrackingStatus.declined);
      repo.openAfterAction = [];
      await cubit.start(me);

      await cubit.decline();
      expect(cubit.state.session, isNull);
      expect(location.watchCount, 0);
    });

    test(
      'accepting an expired request reports it and does not share',
      () async {
        repo.openSessions = [pending];
        repo.actionResult = const Right(TrackingStatus.expired);
        repo.openAfterAction = [];
        await cubit.start(me);

        await cubit.accept();
        expect(cubit.state.session, isNull);
        expect(cubit.state.sharing, isFalse);
        expect(cubit.state.message, 'The location request expired.');
      },
    );

    test('a server rejection is returned and nothing starts', () async {
      repo.actionResult = Left(GeneralFailure('You are not enabled.'));
      await cubit.start(me);
      final result = await cubit.startSharing();
      expect(result.isLeft(), isTrue);
      expect(location.watchCount, 0);
    });
  });

  group('publishing', () {
    setUp(() {
      repo.openAfterAction = [session(5, technician: 7)];
    });

    test('fixes inside the minimum interval are coalesced', () async {
      cubit = build(minPublishInterval: const Duration(milliseconds: 80));
      await cubit.start(me);
      await cubit.startSharing();

      location.push(fix(30.1, epoch));
      await settle();
      location.push(fix(30.2, epoch.add(const Duration(seconds: 1))));
      location.push(fix(30.3, epoch.add(const Duration(seconds: 2))));
      await settle();
      expect(repo.published.map((f) => f.latitude), [30.1]);

      await settle(120);
      expect(repo.published.map((f) => f.latitude), [30.1, 30.3]);
    });

    test('heartbeat republishes a parked position', () async {
      cubit = build(heartbeat: const Duration(milliseconds: 30));
      await cubit.start(me);
      await cubit.startSharing();
      location.push(fix(30.1, epoch));
      await settle();
      await settle(80);
      expect(repo.published.length, greaterThan(1));
      expect(repo.published.last.latitude, 30.1);
      expect(
        repo.published.last.recordedAt.isAfter(repo.published.first.recordedAt),
        isTrue,
      );
    });

    test('a failed publish marks the connection lost, then recovers', () async {
      await cubit.start(me);
      await cubit.startSharing();
      repo.publishResult = Left(GeneralFailure('offline'));
      location.push(fix(30.1, epoch));
      await settle();
      expect(cubit.state.connectionLost, isTrue);
      expect(cubit.state.isActive, isTrue, reason: 'session is kept');

      repo.publishResult = const Right(PublishResult.ok);
      location.push(fix(30.2, epoch.add(const Duration(seconds: 30))));
      await settle();
      expect(cubit.state.connectionLost, isFalse);
    });

    test('another device taking over stops this one', () async {
      await cubit.start(me);
      await cubit.startSharing();
      repo.publishResult = const Right(PublishResult.otherDevice);
      location.push(fix(30.1, epoch));
      await settle();
      expect(cubit.state.sharing, isFalse);
      expect(location.isWatching, isFalse);
    });

    test('revoked permission pauses sharing', () async {
      await cubit.start(me);
      await cubit.startSharing();
      location.access = LocationAccess.denied;
      location.fail();
      await settle();
      expect(cubit.state.sharing, isFalse);
      expect(cubit.state.isPaused, isTrue);
      expect(cubit.state.access, LocationAccess.denied);
    });
  });

  group('lifecycle', () {
    test('ticket reassigned on the server stops publishing', () async {
      repo.openAfterAction = [session(5, technician: 7, ticketId: 3)];
      await cubit.start(me);
      await cubit.startSharing();
      expect(location.isWatching, isTrue);

      repo.emit(SessionUpdate(uidOf(7), endedAs: TrackingStatus.cancelled));
      await settle();
      expect(cubit.state.session, isNull);
      expect(location.isWatching, isFalse);
      expect(cubit.state.message, contains('ended'));
    });

    test('resumes an active session of this device after restart', () async {
      repo.openSessions = [session(5, technician: 7)];
      await cubit.start(me);
      expect(cubit.state.sharing, isTrue);
    });

    test('does not resume a session bound to another device', () async {
      repo.openSessions = [session(5, technician: 7, deviceId: 'other')];
      await cubit.start(me);
      expect(cubit.state.sharing, isFalse);
      expect(cubit.state.isPaused, isTrue);
    });

    test('realtime drop resubscribes and reloads', () async {
      await cubit.start(me);
      repo.openSessions = [
        session(9, technician: 7, status: TrackingStatus.pending),
      ];
      repo.emitError();
      await settle(20);
      expect(repo.watchCount, 2);
      expect(cubit.state.pendingRequest?.id, 'r9');
    });

    test('reset stops location and realtime', () async {
      repo.openSessions = [session(5, technician: 7)];
      await cubit.start(me);
      await cubit.reset();
      expect(location.isWatching, isFalse);
      expect(repo.hasListener, isFalse);
      expect(cubit.state.session, isNull);
    });
  });
}
