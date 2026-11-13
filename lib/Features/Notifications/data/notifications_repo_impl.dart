import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/paging/page_query.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/app_notification.dart';
import '../domain/repo/notifications_repo.dart';

class NotificationsRepoImpl implements NotificationsRepo {
  NotificationsRepoImpl(this._client);

  final SupabaseClient _client;

  static const _table = 'notifications';

  // The push outbox columns stay on the server.
  static const _columns =
      'id,type,title,body,title_ar,body_ar,data,created_at,read_at';

  @override
  Future<Either<Failure, List<AppNotification>>> getPage(PageQuery query) {
    return _guard(() async {
      final rows = await _client
          .from(_table)
          .select(_columns)
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .range(query.from, query.to);
      return rows.map(AppNotification.fromJson).toList();
    });
  }

  @override
  Future<Either<Failure, int>> unreadCount() {
    // RLS limits the count to the caller's rows; a HEAD request, no data.
    return _guard(() => _client.from(_table).count().isFilter('read_at', null));
  }

  @override
  Future<Either<Failure, Unit>> markRead(List<int> ids) {
    return _guard(() async {
      if (ids.isEmpty) return unit;
      await _client.rpc('notifications_mark_read', params: {'p_ids': ids});
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> markAllRead() {
    return _guard(() async {
      await _client.rpc('notifications_mark_all_read');
      return unit;
    });
  }

  @override
  Stream<AppNotification> watch(String recipientUid) {
    final controller = StreamController<AppNotification>();
    final channel = _client.channel(
      'notifications:$recipientUid:${identityHashCode(controller)}',
    );
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: recipientUid,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isEmpty || controller.isClosed) return;
            try {
              controller.add(AppNotification.fromJson(row));
            } catch (error, stackTrace) {
              controller.addError(error, stackTrace);
            }
          },
        )
        .subscribe((status, error) {
          if (controller.isClosed) return;
          if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut ||
              error != null) {
            controller.addError(
              error ?? GeneralFailure('Realtime connection lost'),
            );
          }
        });
    controller.onCancel = () => _client.removeChannel(channel);
    return controller.stream;
  }

  @override
  Future<Either<Failure, Unit>> registerPushToken({
    required String token,
    required String platform,
    required String locale,
  }) {
    return _guard(() async {
      await _client.rpc(
        'register_push_token',
        params: {'p_token': token, 'p_platform': platform, 'p_locale': locale},
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> unregisterPushToken(String token) {
    return _guard(() async {
      await _client.rpc('unregister_push_token', params: {'p_token': token});
      return unit;
    });
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }
}
