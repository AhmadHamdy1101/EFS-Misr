import 'package:efs_misr/constants/screens_size.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/models/tickets.dart';
import '../../../../core/utils/app_text_styles.dart';

class TicketAttachment extends StatelessWidget {
  const TicketAttachment({super.key, required this.ticket});

  final Tickets ticket;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(20.0),
        width: ScreensSize(context).screenWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attachment:'.tr,
              style: AppTextStyle.latoBold20(
                context,
              ).copyWith(color: AppColors.green),
            ),
            Text(ticket.attachment ?? 'No Attachment'),
          ],
        ),
      ),
    );
  }
}
