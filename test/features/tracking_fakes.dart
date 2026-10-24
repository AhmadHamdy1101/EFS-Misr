import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Tracking/data/location_source.dart';
import 'package:efs_misr/Features/Tracking/domain/entities/tracking_session.dart';
import 'package:efs_misr/Features/Tracking/domain/entities/tracking_worker.dart';
import 'package:efs_misr/Features/Tracking/domain/repo/tracking_repo.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/entities/user_entity.dart';

final epoch = DateTime(2026, 10, 24, 9);

String uidOf(int id) => 'uid-$id';

UserEntity worker(int id, String name, {String role = 'User'}) => UserEntity(
  id: BigInt.from(id),
  userid: uidOf(id),
  name: name,
  email: '$id@efs.com',
  phone: '0100$id',
  address: '',
  role: role,
  status: 1,
  position: null,
  companyEmail: '',
  company: 'EFS',
  image: '',
);

/// An open item as `tracking_overview` returns it. Active items use
/// `s<id>` as session id, pending ones `r<id>` as request id.
TrackingSession session(
  int id, {
  required int technician,
  TrackingStatus status = TrackingStatus.active,
  String? deviceId = 'device-1',
  DateTime? lastLocationAt,
  int? ticketId,
  DateTime? expiresAt,
  bool withLocation = true,
}) {
  final active = status == TrackingStatus.active;
  return TrackingSession(
    id: active ? 's$id' : 'r$id',
    sessionId: active ? 's$id' : null,
    requestId: active ? null : 'r$id',
    workerUid: uidOf(technician),
    technicianId: BigInt.from(technician),
    status: status,
    openedAt: epoch,
    ticketId: ticketId,
    deviceId: active ? deviceId : null,
    startedAt: active ? epoch : null,
    expiresAt: expiresAt ?? epoch.add(const Duration(minutes: 15)),
    latitude: active && withLocation ? 30.05 : null,
    longitude: active && withLocation ? 31.24 : null,
    accuracy: active && withLocation ? 8 : null,
    lastLocationAt: lastLocationAt,
  );
}

/// In-memory [TrackingRepo]. Realtime events are pushed with [emit] /
/// [emitError]; every call is recorded. Actions return the configured
/// status and then [openSessions] is what the server "has".
class FakeTrackingRepo implements TrackingRepo {
  List<UserEntity> workers = [];
  List<TrackingSession> openSessions = [];
  final published = <LocationFix>[];
  final calls = <String>[];
  int watchCount = 0;
  StreamController<TrackingUpdate>? _changes;

  /// Applied by the next action: result status and the open items after it.
  Either<Failure, TrackingStatus> actionResult = const Right(
    TrackingStatus.active,
  );
  List<TrackingSession>? openAfterAction;
  Either<Failure, PublishResult> publishResult = const Right(PublishResult.ok);

  bool get hasListener => _changes?.hasListener ?? false;

  void emit(TrackingUpdate update) => _changes?.add(update);
  void emitError() => _changes?.addError(GeneralFailure('dropped'));

  Either<Failure, TrackingStatus> _act(String name) {
    calls.add(name);
    if (actionResult.isRight() && openAfterAction != null) {
      openSessions = openAfterAction!;
    }
    return actionResult;
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getWorkers() async {
    calls.add('getWorkers');
    return Right(workers);
  }

  @override
  Future<Either<Failure, List<TrackingSession>>> getOpenSessions({
    String? workerUid,
  }) async {
    calls.add('getOpenSessions');
    return Right([
      for (final s in openSessions)
        if (workerUid == null || s.workerUid == workerUid) s,
    ]);
  }

  @override
  Future<Either<Failure, BranchLocation?>> getBranch(int branchId) async =>
      Right(BranchLocation(id: branchId, name: 'Branch $branchId'));

  @override
  Stream<TrackingUpdate> watch({String? workerUid}) {
    watchCount++;
    _changes = StreamController<TrackingUpdate>();
    return _changes!.stream;
  }

  @override
  Future<Either<Failure, TrackingSession>> request({
    required String workerUid,
    int? ticketId,
  }) async {
    return _act('request').fold(Left.new, (_) {
      final open = openSessions.where((s) => s.workerUid == workerUid);
      return open.isEmpty
          ? Left(GeneralFailure('not created'))
          : Right(open.first);
    });
  }

  @override
  Future<Either<Failure, TrackingStatus>> respond({
    required String requestId,
    required bool accept,
    required String deviceId,
  }) async => _act(accept ? 'accept' : 'decline');

  @override
  Future<Either<Failure, TrackingStatus>> startSelf({
    required String deviceId,
  }) async => _act('startSelf');

  @override
  Future<Either<Failure, PublishResult>> publish({
    required String sessionId,
    required String deviceId,
    required LocationFix fix,
  }) async {
    published.add(fix);
    return publishResult;
  }

  @override
  Future<Either<Failure, Unit>> markArrived(String sessionId) async {
    calls.add('arrived');
    return const Right(unit);
  }

  @override
  Future<Either<Failure, TrackingStatus>> end(
    TrackingSession item, {
    required bool byWorker,
    String? reason,
  }) async => _act('end');
}

class FakeLocationSource implements LocationSource {
  LocationAccess access = LocationAccess.granted;
  int requestCount = 0;
  int watchCount = 0;
  StreamController<LocationFix>? _fixes;

  bool get isWatching => _fixes?.hasListener ?? false;

  void push(LocationFix fix) => _fixes?.add(fix);
  void fail() => _fixes?.addError(Exception('permission revoked'));

  @override
  Future<LocationAccess> checkAccess() async => access;

  @override
  Future<LocationAccess> requestAccess() async {
    requestCount++;
    return access;
  }

  @override
  Future<LocationFix?> currentFix() async => null;

  @override
  Stream<LocationFix> watch() {
    watchCount++;
    _fixes = StreamController<LocationFix>();
    return _fixes!.stream;
  }

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

LocationFix fix(double lat, DateTime at) =>
    LocationFix(latitude: lat, longitude: 31.2, recordedAt: at, accuracy: 5);

/// Lets stream events, microtasks and short timers run.
Future<void> settle([int ms = 5]) =>
    Future<void>.delayed(Duration(milliseconds: ms));
