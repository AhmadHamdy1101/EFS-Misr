import 'package:efs_misr/constants/screens_size.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/models/tickets.dart';
import '../../../../core/utils/app_text_styles.dart';

class TicketPriority extends StatelessWidget {
  const TicketPriority({super.key, required this.ticket});

  final Tickets ticket;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(20.0),
        child: Row(
          spacing: 15,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority:'.tr,
                        style: AppTextStyle.latoBold20(
                          context,
                        ).copyWith(color: AppColors.green),
                      ),
                      Text("${ticket.priority}"),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Closed By:'.tr,
                        style: AppTextStyle.latoBold20(
                          context,
                        ).copyWith(color: AppColors.green),
                      ),
                      Text(ticket.user?.name ?? '_'),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: ScreensSize(context).screenHeight * 0.13,
              width: 1,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: AppColors.gray,
              ),
            ),
            Expanded(
              child: Column(
                spacing: 10,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Engineer:'.tr,
                        style: AppTextStyle.latoBold20(
                          context,
                        ).copyWith(color: AppColors.green),
                      ),
                      Text(ticket.user?.name ?? '_'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
