import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/tracking_worker.dart';

/// Light green tint used behind icons and badges in the tracking screens.
const trackingTint = Color(0xffDDF3E6);
const trackingCardColor = Color(0xffF0F0F0);

/// Sizes for the tracking screens. Phones narrower than 380 dp (or very
/// short screens) get a compact scale so nothing overflows; everything else
/// uses the regular Material sizes.
class TrackingSizes {
  const TrackingSizes._(this.compact);

  factory TrackingSizes.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return TrackingSizes._(size.width < 380 || size.height < 600);
  }

  final bool compact;

  double get gutter => compact ? 12 : 16;
  double get avatar => compact ? 22 : 26;
  double get title => compact ? 15 : 16;
  double get body => compact ? 13 : 14;
  double get caption => compact ? 11.5 : 12.5;
  double get buttonHeight => compact ? 44 : 48;
  double get chipHeight => compact ? 34 : 38;
  double get statIcon => compact ? 32 : 38;
  double get marker => compact ? 46 : 52;
}

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
  const WorkerAvatar({super.key, required this.user, this.radius = 26});

  final UserEntity user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasImage = user.image.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xffE6E6E6),
      foregroundImage: hasImage ? NetworkImage(user.image) : null,
      child: Icon(Icons.person, size: radius * 1.1, color: AppColors.gray),
    );
  }
}

/// Status pill: "● Live", "● Offline", "● Pending", "● Not sharing".
class TrackingStatusChip extends StatelessWidget {
  const TrackingStatusChip({super.key, required this.state});

  final WorkerTrackingState state;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = trackingStateStyle(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            label.tr,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
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
        const Color(0xffB45309),
        const Color(0xffFFF1DC),
      ),
      WorkerTrackingState.pending => (
        'Pending',
        const Color(0xff2563EB),
        const Color(0xffE0EAFF),
      ),
      WorkerTrackingState.notSharing => (
        'Not sharing',
        const Color(0xff6B7280),
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
    final sizes = TrackingSizes.of(context);
    return Container(
      padding: EdgeInsets.all(sizes.compact ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                width: sizes.statIcon,
                height: sizes.statIcon,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: sizes.statIcon * 0.55,
                ),
              ),
              const SizedBox(width: 6),
              // Scales down instead of overflowing on narrow phones, large
              // counts or large accessibility font sizes.
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$value',
                      style: TextStyle(
                        fontSize: sizes.compact ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.gray, fontSize: sizes.caption),
          ),
        ],
      ),
    );
  }
}

/// Full-width action button with loading and disabled states.
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
    final sizes = TrackingSizes.of(context);
    return SizedBox(
      width: double.infinity,
      height: sizes.buttonHeight,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      label.tr,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: sizes.compact ? 15 : 16,
                        fontWeight: FontWeight.w600,
                      ),
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
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  /// Optional button under the text (e.g. Retry, Open settings).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final sizes = TrackingSizes.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: sizes.title,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: AppColors.gray, fontSize: sizes.body),
              ),
              if (action != null) ...[const SizedBox(height: 4), action!],
            ],
          ),
        ),
      ],
    );
  }
}

/// Centered message with an optional retry, for empty and error states.
class TrackingMessage extends StatelessWidget {
  const TrackingMessage({
    super.key,
    required this.icon,
    required this.text,
    this.onRetry,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.gray),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center),
          if (onRetry != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.green),
              onPressed: onRetry,
              child: Text('Retry'.tr),
            ),
        ],
      ),
    );
  }
}
