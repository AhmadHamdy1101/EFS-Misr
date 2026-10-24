import 'package:efs_misr/Features/Auth/presentation/viewmodel/auth_cubit.dart';
import 'package:efs_misr/Features/Tracking/presentation/widgets/tracking_widgets.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/widgets/app_snack_bar.dart';
import 'package:efs_misr/core/utils/widgets/load_more_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../domain/entities/app_notification.dart';
import '../controller/notifications_cubit.dart';
import '../notification_router.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Future<void> _open(BuildContext context, AppNotification notification) async {
    final cubit = context.read<NotificationsCubit>();
    final auth = context.read<AuthCubit>().currentUser;
    await cubit.markRead(notification);
    if (auth == null || !context.mounted) return;
    await NotificationRouter.open(context, notification.target, auth);
  }

  Future<void> _markAll(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<NotificationsCubit>().markAllRead();
    if (!ok) {
      showAppSnackBar(
        messenger,
        'Could not update notifications.'.tr,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = Get.locale?.languageCode ?? 'en';
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final cubit = context.read<NotificationsCubit>();
        return Scaffold(
          backgroundColor: AppColors.appBackground,
          appBar: AppBar(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            title: Text('Notifications'.tr),
            actions: [
              if (state.unreadCount > 0)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () => _markAll(context),
                  child: Text('Mark all read'.tr),
                ),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.green,
            onRefresh: cubit.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.loading && state.items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.green),
                    ),
                  )
                else if (state.error != null && state.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.error!, textAlign: TextAlign.center),
                          TextButton(
                            onPressed: cubit.refresh,
                            child: Text('Retry'.tr),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (state.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: AppColors.gray,
                          ),
                          const SizedBox(height: 12),
                          Text('No notifications yet'.tr),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    sliver: SliverList.builder(
                      itemCount: state.items.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.items.length) {
                          return LoadMoreIndicator(
                            isLoading: state.isLoadingMore,
                            onLoadMore: cubit.loadMore,
                          );
                        }
                        final notification = state.items[index];
                        return _NotificationTile(
                          notification: notification,
                          language: language,
                          onTap: () => _open(context, notification),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.language,
    required this.onTap,
  });

  final AppNotification notification;
  final String language;
  final VoidCallback onTap;

  static IconData _icon(String type) {
    if (type.startsWith('tracking.')) return Icons.location_on_outlined;
    if (type.startsWith('asset.')) return Icons.build_outlined;
    if (type == 'ticket.completed') return Icons.check_circle_outline;
    if (type == 'ticket.cancelled' || type == 'ticket.rejected') {
      return Icons.cancel_outlined;
    }
    return Icons.confirmation_number_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return Material(
      color: unread ? trackingTint.withValues(alpha: 0.6) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: trackingTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon(notification.type), color: AppColors.green),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.titleFor(language),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: unread ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.bodyFor(language),
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeAgo(notification.createdAt, DateTime.now()),
                      style: const TextStyle(
                        color: AppColors.gray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread)
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 8),
                  child: Icon(Icons.circle, size: 10, color: AppColors.green),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
