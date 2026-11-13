import 'dart:async';
import 'dart:developer' as developer;

import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:efs_misr/core/paging/page_loader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/push_service.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repo/notifications_repo.dart';

part 'notifications_state.dart';

/// The signed-in user's notifications: paged list, unread badge, realtime
/// arrivals, read state, and the push-token lifecycle.
///
/// The unread count comes from the server and is then kept in step with
/// local reads and realtime events; any reconnect re-reads it, so it can't
/// drift for long.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required NotificationsRepo repo,
    required PushService push,
    String Function()? locale,
    this.reconnectDelay = const Duration(seconds: 5),
  }) : _repo = repo,
       _push = push,
       _locale = locale ?? (() => 'en'),
       super(const NotificationsState()) {
    _pages = PageLoader(_repo.getPage, idOf: (n) => n.id);
  }

  final NotificationsRepo _repo;
  final PushService _push;
  final String Function() _locale;
  final Duration reconnectDelay;
  late final PageLoader<AppNotification> _pages;

  StreamSubscription<AppNotification>? _sub;
  Timer? _reconnect;
  String? _uid;
  String? _pushToken;
  int _generation = 0;
  int _openId = 0;

  Future<void> start(UserEntity user) async {
    _uid = user.userid;
    _subscribe();
    await refresh();
    unawaited(_startPush());
  }

  /// Call before signing out, while the session is still valid: unlinks this
  /// device's push token so the next user of the phone doesn't get this
  /// user's pushes. (A token is also re-linked on the next sign-in.)
  Future<void> unregisterDevice() async {
    final token = _pushToken ?? await _push.currentToken();
    _pushToken = null;
    if (token != null) await _repo.unregisterPushToken(token);
  }

  /// After sign-out: stop realtime and push and drop the old user's data.
  Future<void> reset() async {
    _generation++;
    _reconnect?.cancel();
    await _sub?.cancel();
    _sub = null;
    _pushToken = null;
    _uid = null;
    _pages.clear();
    await _push.stop();
    if (!isClosed) emit(const NotificationsState());
  }

  Future<void> refresh() async {
    final generation = _generation;
    if (state.items.isEmpty) emit(state.copyWith(loading: true));
    final (page, count) = await (_pages.reload(), _repo.unreadCount()).wait;
    if (isClosed || generation != _generation || page == null) return;
    page.fold(
      (failure) => emit(state.copyWith(loading: false, error: failure.message)),
      (_) => emit(
        state.copyWith(
          loading: false,
          clearError: true,
          items: List.unmodifiable(_pages.items),
          hasMore: _pages.hasMore,
          unreadCount: count.getOrElse(() => state.unreadCount),
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    if (!_pages.canLoadMore) return;
    final loading = _pages.loadMore();
    emit(state.copyWith(isLoadingMore: true));
    final result = await loading;
    if (isClosed || result == null) return;
    result.fold(
      (failure) => developer.log(
        'Could not load more notifications: ${failure.message}',
        name: 'NotificationsCubit',
      ),
      (_) {},
    );
    emit(
      state.copyWith(
        isLoadingMore: false,
        items: List.unmodifiable(_pages.items),
        hasMore: _pages.hasMore,
      ),
    );
  }

  /// Marks one as read (optimistically; rolled back if the server refuses).
  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead) return;
    _replace(notification.markedRead(DateTime.now()));
    emit(state.copyWith(unreadCount: _decrement(state.unreadCount)));
    final result = await _repo.markRead([notification.id]);
    if (isClosed) return;
    result.fold((_) {
      _replace(notification);
      emit(state.copyWith(unreadCount: state.unreadCount + 1));
    }, (_) {});
  }

  Future<bool> markAllRead() async {
    final result = await _repo.markAllRead();
    if (isClosed) return false;
    return result.fold((_) => false, (_) {
      final now = DateTime.now();
      for (var i = 0; i < _pages.items.length; i++) {
        _pages.items[i] = _pages.items[i].markedRead(now);
      }
      emit(
        state.copyWith(items: List.unmodifiable(_pages.items), unreadCount: 0),
      );
      return true;
    });
  }

  /// A tapped push notification: hands its target to the UI to open.
  void openFromPush(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    emit(
      state.copyWith(
        openRequest: NotificationTarget.fromData(type, data),
        openRequestId: ++_openId,
      ),
    );
    // The list may not contain it yet; re-read so the badge is right.
    unawaited(refresh());
  }

  // ---------------------------------------------------------------------------

  Future<void> _startPush() async {
    if (!_push.isAvailable) return;
    final generation = _generation;
    await _push.start(
      onToken: (token, platform) async {
        if (generation != _generation) return;
        _pushToken = token;
        final result = await _repo.registerPushToken(
          token: token,
          platform: platform,
          locale: _locale(),
        );
        result.fold(
          (failure) => developer.log(
            'Push token registration failed: ${failure.message}',
            name: 'NotificationsCubit',
          ),
          (_) {},
        );
      },
      onOpened: (data) {
        if (generation == _generation) openFromPush(data);
      },
    );
  }

  void _subscribe() {
    final uid = _uid;
    if (uid == null) return;
    _sub?.cancel();
    _sub = _repo
        .watch(uid)
        .listen(
          _onChanged,
          onError: (Object error) {
            developer.log(
              'Notifications realtime dropped: $error',
              name: 'NotificationsCubit',
            );
            _scheduleReconnect();
          },
        );
  }

  void _scheduleReconnect() {
    if (_reconnect?.isActive ?? false) return;
    final generation = _generation;
    _reconnect = Timer(reconnectDelay, () async {
      if (isClosed || generation != _generation) return;
      _subscribe();
      await refresh();
    });
  }

  /// Realtime insert or update. Delivered at least once, so a known id only
  /// updates read state and never counts twice.
  void _onChanged(AppNotification incoming) {
    if (isClosed) return;
    final index = _pages.items.indexWhere((n) => n.id == incoming.id);
    if (index == -1) {
      _pages.items.insert(0, incoming);
      emit(
        state.copyWith(
          items: List.unmodifiable(_pages.items),
          unreadCount: incoming.isRead
              ? state.unreadCount
              : state.unreadCount + 1,
          latest: incoming,
          latestId: incoming.id,
        ),
      );
      return;
    }
    final current = _pages.items[index];
    _pages.items[index] = incoming;
    var unread = state.unreadCount;
    if (!current.isRead && incoming.isRead) unread = _decrement(unread);
    if (current.isRead && !incoming.isRead) unread++;
    emit(
      state.copyWith(
        items: List.unmodifiable(_pages.items),
        unreadCount: unread,
      ),
    );
  }

  void _replace(AppNotification notification) {
    final index = _pages.items.indexWhere((n) => n.id == notification.id);
    if (index == -1) return;
    _pages.items[index] = notification;
    emit(state.copyWith(items: List.unmodifiable(_pages.items)));
  }

  static int _decrement(int value) => value > 0 ? value - 1 : 0;

  @override
  Future<void> close() async {
    _reconnect?.cancel();
    await _sub?.cancel();
    return super.close();
  }
}
