import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/tracking_worker.dart';

/// Light green tint used behind icons and badges in the tracking screens.
const trackingTint = Color(0xffDDF3E6);
const trackingCardColor = Color(0xffF0F0F0);

/// "Just now", "5 mins ago", ... for last-update labels.
String timeAgo(DateTime? time, DateTime now) {
  if (time == null) return 'No update yet'.tr;
  final diff = now.difference(time);
  if (diff.inSeconds < 60) return 'Just now'.tr;
  if (diff.inMinutes < 60) return '${diff.inMinutes} ${'mins ago'.tr}';
  if (diff.inHours < 24) return '${diff.inHours} ${'hours ago'.tr}';
  return '${diff.inDays} ${'days ago'.tr}';
}

String formatDistance(double meters) => meters < 1000
    ? '${meters.round()} ${'m'.tr}'
    : '${(meters / 1000).toStringAsFixed(1)} ${'km'.tr}';

String formatCoordinates(double latitude, double longitude) {
  final ns = latitude >= 0 ? 'N' : 'S';
  final ew = longitude >= 0 ? 'E' : 'W';
  return '${latitude.abs().toStringAsFixed(4)}° $ns, '
      '${longitude.abs().toStringAsFixed(4)}° $ew';
}

class WorkerAvatar extends StatelessWidget {
  const WorkerAvatar({super.key, required this.user, this.radius = 40});

  final UserEntity user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasImage = user.image.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xffE6E6E6),
      backgroundImage: hasImage ? NetworkImage(user.image) : null,
      child: hasImage
          ? null
          : Icon(Icons.person, size: radius * 1.1, color: AppColors.gray),
    );
  }
}

/// Status pill: "● Live", "● Offline", "● Pending", "● Not sharing".
class TrackingStatusChip extends StatelessWidget {
  const TrackingStatusChip({
    super.key,
    required this.state,
    this.large = false,
  });

  final WorkerTrackingState state;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = trackingStateStyle(state);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 12,
        vertical: large ? 9 : 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: large ? 11 : 9, color: color),
          const SizedBox(width: 8),
          Text(
            label.tr,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: large ? 18 : 15,
            ),
          ),
        ],
      ),
    );
  }
}

(String, Color, Color) trackingStateStyle(WorkerTrackingState state) =>
    switch (state) {
      WorkerTrackingState.live => ('Live', AppColors.green, trackingTint),
      WorkerTrackingState.offline => (
        'Offline',
        const Color(0xffD97706),
        const Color(0xffFFF1DC),
      ),
      WorkerTrackingState.pending => (
        'Pending',
        const Color(0xff2563EB),
        const Color(0xffE0EAFF),
      ),
      WorkerTrackingState.notSharing => (
        'Not sharing',
        AppColors.gray,
        const Color(0xffE6E6E6),
      ),
    };

/// White rounded card with an icon, a number and a label.
class TrackingStatCard extends StatelessWidget {
  const TrackingStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor = AppColors.green,
    this.iconBackground = trackingTint,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const Spacer(),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.gray, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// The green full-width rounded action button used across the screens.
class TrackingPrimaryButton extends StatelessWidget {
  const TrackingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.color = AppColors.green,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon), const SizedBox(width: 14)],
                  Flexible(
                    child: Text(
                      label.tr,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Icon + bold title + grey subtitle row (status explanations).
class TrackingInfoRow extends StatelessWidget {
  const TrackingInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = AppColors.green,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: iconColor, size: 30),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.gray, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
