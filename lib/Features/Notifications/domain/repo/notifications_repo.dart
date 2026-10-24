import 'package:dartz/dartz.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/paging/page_query.dart';

import '../entities/app_notification.dart';

abstract interface class NotificationsRepo {
  /// The signed-in user's notifications, newest first.
  Future<Either<Failure, List<AppNotification>>> getPage(PageQuery query);

  Future<Either<Failure, int>> unreadCount();

  Future<Either<Failure, Unit>> markRead(List<int> ids);

  Future<Either<Failure, Unit>> markAllRead();

  /// New and updated (e.g. read on another device) notifications of the
  /// user. Emits an error when the realtime channel drops.
  Stream<AppNotification> watch(String recipientUid);

  Future<Either<Failure, Unit>> registerPushToken({
    required String token,
    required String platform,
    required String locale,
  });

  Future<Either<Failure, Unit>> unregisterPushToken(String token);
}
