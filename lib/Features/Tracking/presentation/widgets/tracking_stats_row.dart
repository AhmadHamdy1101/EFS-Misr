import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';

class TrackingStatsRow extends StatelessWidget {
  const TrackingStatsRow({
    super.key,
    required this.totalWorkers,
    required this.liveCount,
    required this.offlineCount,
    required this.isDarkMode,
  });

  final int totalWorkers;
  final int liveCount;
  final int offlineCount;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              title: 'Total workers'.tr,
              value: totalWorkers.toString(),
              icon: Icons.people_outline,
              color: AppColors.green,
              isDarkMode: isDarkMode,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              context,
              title: 'Live now'.tr,
              value: liveCount.toString(),
              icon: Icons.gps_fixed,
              color: AppColors.successGreen,
              isDarkMode: isDarkMode,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              context,
              title: 'Not sharing'.tr,
              value: offlineCount.toString(),
              icon: Icons.location_off_outlined,
              color: AppColors.gray,
              isDarkMode: isDarkMode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode ? AppColors.buttondark : AppColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                Text(
                  value,
                  style: AppTextStyle.latoBold20(context).copyWith(
                    color: isDarkMode ? AppColors.white : AppColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyle.latoRegular12(context).copyWith(
                color: AppColors.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
