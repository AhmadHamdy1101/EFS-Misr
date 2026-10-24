import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../controller/notifications_cubit.dart';
import '../screens/notifications_page.dart';

/// Bell with the unread badge; opens the notification list. Rebuilds only
/// when the unread count changes.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, required this.icon});

  /// The bell itself, so each header keeps its own look.
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final unread = context.select<NotificationsCubit, int>(
      (cubit) => cubit.state.unreadCount,
    );
    return IconButton(
      tooltip: 'Notifications'.tr,
      onPressed: () => Get.to(() => const NotificationsPage()),
      icon: Badge(
        isLabelVisible: unread > 0,
        backgroundColor: Colors.red,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: icon,
      ),
    );
  }
}
