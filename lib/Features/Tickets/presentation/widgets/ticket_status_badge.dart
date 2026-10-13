import 'package:efs_misr/Features/Tickets/domain/entities/ticket_entity.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_text_styles.dart';

class TicketStatusBadge extends StatelessWidget {
  const TicketStatusBadge({super.key, required this.status});

  final TicketStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TicketStatus.awaiting => const Color(0xffDFE699),
      TicketStatus.completed => const Color(0xff8FCFAD),
      TicketStatus.canceled || TicketStatus.rejected => const Color(0xffDBA0A0),
      TicketStatus.unknown => AppColors.gray,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Text(
          status.databaseValue.tr,
          style: AppTextStyle.latoBold13(
            context,
          ).copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}
