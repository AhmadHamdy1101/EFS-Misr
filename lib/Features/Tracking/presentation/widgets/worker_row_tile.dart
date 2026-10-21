import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/worker_location_model.dart';
import '../controller/tracking_cubit.dart';
import '../controller/tracking_state.dart';

class WorkerRowTile extends StatelessWidget {
  const WorkerRowTile({
    super.key,
    required this.worker,
    required this.isDarkMode,
  });

  final WorkerLocationModel worker;
  final bool isDarkMode;

  Color _getStatusColor(WorkerStatus status) {
    switch (status) {
      case WorkerStatus.live:
        return AppColors.successGreen;
      case WorkerStatus.offline:
        return AppColors.gray;
      case WorkerStatus.pending:
        return Colors.orange;
      case WorkerStatus.declined:
        return Colors.red;
    }
  }

  String _getStatusLabel(WorkerStatus status) {
    switch (status) {
      case WorkerStatus.live:
        return 'Live'.tr;
      case WorkerStatus.offline:
        return 'Not sharing'.tr;
      case WorkerStatus.pending:
        return 'Request pending'.tr;
      case WorkerStatus.declined:
        return 'Request declined'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TrackingCubit>();
    final statusColor = _getStatusColor(worker.status);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.scafolddark : AppColors.appBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.green.withValues(alpha: 0.15),
            backgroundImage: NetworkImage(worker.avatarUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name,
                  style: AppTextStyle.latoBold16(context).copyWith(
                    color: isDarkMode ? AppColors.white : AppColors.black,
                  ),
                ),
                Text(
                  worker.position,
                  style: AppTextStyle.latoRegular12(context).copyWith(
                    color: AppColors.gray,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusLabel(worker.status),
                      style: AppTextStyle.latoBold10(context).copyWith(
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      worker.lastUpdated,
                      style: AppTextStyle.latoRegular12(context).copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (worker.status == WorkerStatus.live)
            OutlinedButton(
              onPressed: () {
                cubit.selectWorker(worker);
                cubit.navigateTo(TrackingViewType.workerDetail,
                    targetWorker: worker);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green),
                minimumSize: const Size(60, 32),
              ),
              child: Text('View'.tr),
            ),
          if (worker.status == WorkerStatus.offline)
            ElevatedButton(
              onPressed: () {
                cubit.navigateTo(TrackingViewType.requestConfirmation,
                    targetWorker: worker);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.white,
                minimumSize: const Size(60, 32),
              ),
              child: Text('Request'.tr),
            ),
          if (worker.status == WorkerStatus.pending)
            TextButton(
              onPressed: () {
                cubit.navigateTo(TrackingViewType.pendingApproval,
                    targetWorker: worker);
              },
              child: Text('Pending'.tr,
                  style: const TextStyle(color: Colors.orange)),
            ),
          if (worker.status == WorkerStatus.declined)
            TextButton(
              onPressed: () {
                cubit.navigateTo(TrackingViewType.requestConfirmation,
                    targetWorker: worker);
              },
              child: Text('Retry'.tr,
                  style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}
