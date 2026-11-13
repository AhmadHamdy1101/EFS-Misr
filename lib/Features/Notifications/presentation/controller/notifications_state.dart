part of 'notifications_cubit.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.loading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
    this.latest,
    this.latestId = 0,
    this.openRequest,
    this.openRequestId = 0,
  });

  final List<AppNotification> items;
  final int unreadCount;
  final bool loading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  /// The last notification that arrived while the app was open (for an
  /// in-app banner); [latestId] changes with each one.
  final AppNotification? latest;
  final int latestId;

  /// A target to open from a tapped push; [openRequestId] changes each time.
  final NotificationTarget? openRequest;
  final int openRequestId;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    bool? loading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
    AppNotification? latest,
    int? latestId,
    NotificationTarget? openRequest,
    int? openRequestId,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      loading: loading ?? this.loading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : error ?? this.error,
      latest: latest ?? this.latest,
      latestId: latestId ?? this.latestId,
      openRequest: openRequest ?? this.openRequest,
      openRequestId: openRequestId ?? this.openRequestId,
    );
  }
}
