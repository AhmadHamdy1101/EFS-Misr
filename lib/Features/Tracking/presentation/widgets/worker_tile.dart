import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/tracking_worker.dart';
import 'tracking_widgets.dart';

/// One worker row in the admin sheet: avatar, name, position, sharing state,
/// and the action that fits the state (View / Request / Pending).
class WorkerTile extends StatelessWidget {
  const WorkerTile({
    super.key,
    required this.worker,
    required this.now,
    required this.onView,
    required this.onRequest,
    required this.onCancelPending,
  });

  final TrackingWorker worker;
  final DateTime now;
  final VoidCallback onView;
  final VoidCallback onRequest;
  final VoidCallback onCancelPending;

  @override
  Widget build(BuildContext context) {
    final user = worker.user;
    final trackingState = worker.stateAt(now);
    final (label, color, _) = trackingStateStyle(trackingState);
    final updated = switch (trackingState) {
      WorkerTrackingState.live || WorkerTrackingState.offline => timeAgo(
        worker.session?.lastLocationAt,
        now,
      ),
      WorkerTrackingState.pending => 'Waiting for approval'.tr,
      WorkerTrackingState.notSharing => 'Not sharing'.tr,
    };

    return Material(
      color: trackingCardColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap:
            trackingState == WorkerTrackingState.live ||
                trackingState == WorkerTrackingState.offline
            ? onView
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              WorkerAvatar(user: user, radius: 40),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (user.position?.name ?? user.role).tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.gray,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 14, color: color),
                        const SizedBox(width: 10),
                        Text(
                          label.tr,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Flexible(
                          child: Text(
                            updated,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.gray,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _action(trackingState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(WorkerTrackingState trackingState) {
    const shape = StadiumBorder();
    const padding = EdgeInsets.symmetric(horizontal: 28, vertical: 14);
    const textStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.w500);
    return switch (trackingState) {
      WorkerTrackingState.live || WorkerTrackingState.offline => OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.green,
          side: const BorderSide(color: AppColors.green, width: 2),
          shape: shape,
          padding: padding,
          textStyle: textStyle,
        ),
        onPressed: onView,
        child: Text('View'.tr),
      ),
      WorkerTrackingState.pending => OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gray,
          side: const BorderSide(color: AppColors.gray, width: 2),
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: textStyle,
        ),
        onPressed: onCancelPending,
        child: Text('Pending'.tr),
      ),
      WorkerTrackingState.notSharing => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          shape: shape,
          padding: padding,
          textStyle: textStyle,
        ),
        onPressed: onRequest,
        child: Text('Request'.tr),
      ),
    };
  }
}
