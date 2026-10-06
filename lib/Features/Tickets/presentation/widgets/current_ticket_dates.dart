import 'package:efs_misr/constants/screens_size.dart';
import 'package:efs_misr/core/Functions/GetDate_Function.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/models/tickets.dart';
import '../../../../core/utils/app_text_styles.dart';

class CurrentTicketDates extends StatelessWidget {
  const CurrentTicketDates({super.key, required this.currentTicket});

  final Tickets currentTicket;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(20.0),
        child: Row(
          spacing: 15,
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
                        'Request Date'.tr,
                        style: AppTextStyle.latoBold20(
                          context,
                        ).copyWith(color: AppColors.green),
                      ),
                      Text(
                        currentTicket.requestDate != null
                            ? getDateFromTimestamp(currentTicket.requestDate)
                            : '-',
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repair Date:'.tr,
                        style: AppTextStyle.latoBold20(
                          context,
                        ).copyWith(color: AppColors.green),
                      ),
                      Text(
                        currentTicket.repairDate != null
                            ? getDateFromTimestamp(currentTicket.repairDate)
                            : '-',
                      ),
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
                        'Request Date:'.tr,
                        style: AppTextStyle.latoBold20(
                          context,
                        ).copyWith(color: AppColors.green),
                      ),
                      Text(
                        currentTicket.requestDate != null
                            ? getDateFromTimestamp(currentTicket.requestDate)
                            : '-',
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Response Date:'.tr,
                        style: AppTextStyle.latoBold20(
                          context,
                        ).copyWith(color: AppColors.green),
                      ),
                      Text(
                        currentTicket.responseDate != null
                            ? getDateFromTimestamp(currentTicket.responseDate)
                            : '-',
                      ),
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
