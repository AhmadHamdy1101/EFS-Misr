import 'package:flutter/material.dart';

import '../../../../core/utils/app_colors.dart';
import '../../data/models/worker_location_model.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final WorkerStatus status;

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.gray;
    String label = 'Not sharing';

    switch (status) {
      case WorkerStatus.live:
        color = AppColors.successGreen;
        label = 'Live';
        break;
      case WorkerStatus.offline:
        color = AppColors.gray;
        label = 'Not sharing';
        break;
      case WorkerStatus.pending:
        color = Colors.orange;
        label = 'Request pending';
        break;
      case WorkerStatus.declined:
        color = Colors.red;
        label = 'Request declined';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
