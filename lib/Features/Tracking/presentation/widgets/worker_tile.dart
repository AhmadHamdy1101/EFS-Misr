import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/tracking_worker.dart';
import 'tracking_widgets.dart';

/// One worker row: avatar, name, position, sharing state and last update.
/// Admins get the action that fits the state (View / Request / Pending);
/// in [readOnly] mode (role User) only View is offered.
class WorkerTile extends StatelessWidget {
  const WorkerTile({
    super.key,
    required this.worker,
    required this.now,
    required this.onView,
    required this.onRequest,
    required this.onCancelPending,
    this.readOnly = false,
  });

  final TrackingWorker worker;
  final DateTime now;
  final VoidCallback onView;
  final VoidCallback onRequest;
  final VoidCallback onCancelPending;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final sizes = TrackingSizes.of(context);
    final user = worker.user;
    final trackingState = worker.stateAt(now);
    final (label, color, _) = trackingStateStyle(trackingState);
    final canView =
        trackingState == WorkerTrackingState.live ||
        trackingState == WorkerTrackingState.offline;
    final updated = switch (trackingState) {
      WorkerTrackingState.live || WorkerTrackingState.offline => timeAgo(
        worker.session?.lastLocationAt,
        now,
      ),
      WorkerTrackingState.pending => 'Waiting for approval'.tr,
      WorkerTrackingState.notSharing => '',
    };
    final action = _action(trackingState, sizes);

    return Material(
      color: trackingCardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: canView ? onView : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: sizes.compact ? 10 : 12,
            vertical: sizes.compact ? 10 : 12,
          ),
          child: Row(
            children: [
              WorkerAvatar(user: user, radius: sizes.avatar),
              SizedBox(width: sizes.compact ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: sizes.title,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (user.position?.name ?? user.role).tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.gray,
                        fontSize: sizes.caption,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 9, color: color),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            updated.isEmpty
                                ? label.tr
                                : '${label.tr} · $updated',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: sizes.caption,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (action != null) ...[const SizedBox(width: 8), action],
            ],
          ),
        ),
      ),
    );
  }

  Widget? _action(WorkerTrackingState trackingState, TrackingSizes sizes) {
    ButtonStyle style(Color fg, Color? bg, Color? border) => ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, sizes.compact ? 34 : 38)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 14),
      ),
      foregroundColor: WidgetStatePropertyAll(fg),
      backgroundColor: WidgetStatePropertyAll(bg),
      side: border == null
          ? null
          : WidgetStatePropertyAll(BorderSide(color: border, width: 1.5)),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      textStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: sizes.body, fontWeight: FontWeight.w600),
      ),
      visualDensity: VisualDensity.compact,
    );
    return switch (trackingState) {
      WorkerTrackingState.live || WorkerTrackingState.offline => OutlinedButton(
        style: style(AppColors.green, null, AppColors.green),
        onPressed: onView,
        child: Text('View'.tr),
      ),
      WorkerTrackingState.pending when !readOnly => OutlinedButton(
        style: style(AppColors.gray, null, AppColors.gray),
        onPressed: onCancelPending,
        child: Text('Pending'.tr),
      ),
      WorkerTrackingState.notSharing when !readOnly => FilledButton(
        style: style(Colors.white, AppColors.green, null),
        onPressed: onRequest,
        child: Text('Request'.tr),
      ),
      _ => null,
    };
  }
}
