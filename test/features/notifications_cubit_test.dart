import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Notifications/data/push_service.dart';
import 'package:efs_misr/Features/Notifications/domain/entities/app_notification.dart';
import 'package:efs_misr/Features/Notifications/domain/repo/notifications_repo.dart';
import 'package:efs_misr/Features/Notifications/presentation/controller/notifications_cubit.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/paging/page_query.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tracking_fakes.dart' show worker, settle;

final _base = DateTime(2026, 10, 25, 9);

AppNotification _n(
  int id, {
  bool read = false,
  String type = 'ticket.assigned',
  Map<String, dynamic>? data,
}) => AppNotification(
  id: id,
  type: type,
  title: 'Title $id',
  body: 'Body $id',
  titleAr: 'عنوان $id',
  data: data ?? {'ticket_id': id},
  createdAt: _base.add(Duration(minutes: id)),
  readAt: read ? _base : null,
);

class _FakeRepo implements NotificationsRepo {
  /// Newest first, like the server.
  List<AppNotification> rows = [];
  final markedRead = <int>[];
  final registered = <String>[];
  final unregistered = <String>[];
  bool failMarkRead = false;
  int watchCount = 0;
  StreamController<AppNotification>? _changes;

  void push(AppNotification n) => _changes?.add(n);
  void drop() => _changes?.addError(GeneralFailure('dropped'));

  @override
  Future<Either<Failure, List<AppNotification>>> getPage(
    PageQuery query,
  ) async => Right(rows.skip(query.from).take(query.pageSize).toList());

  @override
  Future<Either<Failure, int>> unreadCount() async =>
      Right(rows.where((n) => !n.isRead).length);

  @override
  Future<Either<Failure, Unit>> markRead(List<int> ids) async {
    if (failMarkRead) return Left(GeneralFailure('nope'));
    markedRead.addAll(ids);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> markAllRead() async => const Right(unit);

  @override
  Stream<AppNotification> watch(String recipientUid) {
    watchCount++;
    _changes = StreamController<AppNotification>();
    return _changes!.stream;
  }

  @override
  Future<Either<Failure, Unit>> registerPushToken({
    required String token,
    required String platform,
    required String locale,
  }) async {
    registered.add('$token/$platform/$locale');
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> unregisterPushToken(String token) async {
    unregistered.add(token);
    return const Right(unit);
  }
}

class _FakePush implements PushService {
  void Function(Map<String, dynamic> data)? opened;

  @override
  bool get isAvailable => true;

  @override
  Future<void> start({
    required Future<void> Function(String token, String platform) onToken,
    required void Function(Map<String, dynamic> data) onOpened,
  }) async {
    opened = onOpened;
    await onToken('token-abcdefghijklmnopqrstuvwxyz', 'android');
  }

  @override
  Future<String?> currentToken() async => 'token-abcdefghijklmnopqrstuvwxyz';

  @override
  Future<void> stop() async {}
}

void main() {
  late _FakeRepo repo;
  late _FakePush push;
  late NotificationsCubit cubit;

  setUp(() async {
    repo = _FakeRepo()
      ..rows = [
        for (var id = 45; id >= 1; id--) _n(id, read: id <= 40),
      ]; // 5 unread: 41..45
    push = _FakePush();
    cubit = NotificationsCubit(
      repo: repo,
      push: push,
      locale: () => 'ar',
      reconnectDelay: const Duration(milliseconds: 1),
    );
    await cubit.start(worker(7, 'Ahmed'));
    await settle();
  });

  tearDown(() => cubit.close());

  test('loads the first page and the server unread count', () {
    expect(cubit.state.items, hasLength(PageQuery.defaultPageSize));
    expect(cubit.state.items.first.id, 45);
    expect(cubit.state.unreadCount, 5);
    expect(cubit.state.hasMore, isTrue);
  });

  test('loadMore appends the next page', () async {
    await cubit.loadMore();
    expect(cubit.state.items, hasLength(45));
    expect(cubit.state.hasMore, isFalse);
  });

  test('a realtime insert is added once and counted once', () async {
    final incoming = _n(46);
    repo.push(incoming);
    repo.push(incoming); // delivered twice
    await settle();
    expect(cubit.state.items.first.id, 46);
    expect(cubit.state.items.where((n) => n.id == 46), hasLength(1));
    expect(cubit.state.unreadCount, 6);
    expect(cubit.state.latest?.id, 46);
  });

  test('read on another device lowers the badge', () async {
    repo.push(_n(45, read: true));
    await settle();
    expect(cubit.state.unreadCount, 4);
    expect(cubit.state.items.first.isRead, isTrue);
  });

  test('markRead updates the item and the badge', () async {
    await cubit.markRead(cubit.state.items.first);
    expect(repo.markedRead, [45]);
    expect(cubit.state.items.first.isRead, isTrue);
    expect(cubit.state.unreadCount, 4);
  });

  test('a failed markRead is rolled back', () async {
    repo.failMarkRead = true;
    await cubit.markRead(cubit.state.items.first);
    expect(cubit.state.items.first.isRead, isFalse);
    expect(cubit.state.unreadCount, 5);
  });

  test('markRead on an already read notification does nothing', () async {
    final read = cubit.state.items.firstWhere((n) => n.isRead);
    await cubit.markRead(read);
    expect(repo.markedRead, isEmpty);
    expect(cubit.state.unreadCount, 5);
  });

  test('markAllRead clears the badge', () async {
    expect(await cubit.markAllRead(), isTrue);
    expect(cubit.state.unreadCount, 0);
    expect(cubit.state.items.every((n) => n.isRead), isTrue);
  });

  test('registers the push token with the user locale', () {
    expect(repo.registered, ['token-abcdefghijklmnopqrstuvwxyz/android/ar']);
  });

  test('a tapped push becomes an open request', () async {
    push.opened!({'type': 'ticket.assigned', 'ticket_id': '12'});
    final target = cubit.state.openRequest;
    expect(target, isA<TicketTarget>());
    expect((target as TicketTarget).ticketId, 12);
    expect(cubit.state.openRequestId, 1);
  });

  test('unregisterDevice removes the token; reset clears state', () async {
    await cubit.unregisterDevice();
    expect(repo.unregistered, ['token-abcdefghijklmnopqrstuvwxyz']);
    await cubit.reset();
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.unreadCount, 0);
  });

  test('realtime drop resubscribes and re-reads the badge', () async {
    repo.rows = [_n(50), ...repo.rows];
    repo.drop();
    await settle(20);
    expect(repo.watchCount, 2);
    expect(cubit.state.unreadCount, 6);
    expect(cubit.state.items.first.id, 50);
  });

  group('targets', () {
    test('ticket events open the ticket', () {
      expect(_n(1).target, isA<TicketTarget>());
    });

    test('requests to a technician open their location screen', () {
      final n = _n(1, type: 'tracking.requested', data: {'ticket_id': 3});
      expect(n.target, isA<MyLocationTarget>());
    });

    test('tracking updates for admins open the worker map', () {
      final n = _n(1, type: 'tracking.accepted', data: {'technician_id': 9});
      final target = n.target;
      expect(target, isA<WorkerTrackingTarget>());
      expect((target as WorkerTrackingTarget).technicianId, BigInt.from(9));
    });

    test('unknown data opens nothing', () {
      expect(_n(1, type: 'other', data: {}).target, isA<NoTarget>());
    });

    test('Arabic text is used for Arabic with English fallback', () {
      final n = _n(3);
      expect(n.titleFor('ar'), 'عنوان 3');
      expect(n.bodyFor('ar'), 'Body 3');
      expect(n.titleFor('en'), 'Title 3');
    });

    test('parses a database row', () {
      final n = AppNotification.fromJson({
        'id': 5,
        'type': 'ticket.cancelled',
        'title': 'T',
        'body': 'B',
        'data': {'ticket_id': 8},
        'created_at': '2026-10-25T09:00:00Z',
        'read_at': null,
      });
      expect(n.id, 5);
      expect(n.isRead, isFalse);
      expect((n.target as TicketTarget).ticketId, 8);
    });
  });
}
