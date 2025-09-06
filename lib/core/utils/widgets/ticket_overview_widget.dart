import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';

class TicketOverViewWidget extends StatelessWidget {
  const TicketOverViewWidget({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.ticketData,
  });

  final double screenWidth;
  final double screenHeight;
  final Tickets ticketData;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              spacing: 15,
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: AppColors.lightgreen.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: ClipRRect(
                    child: SvgPicture.asset(
                      'assets/images/ticket.svg',
                      color: AppColors.green,
                      width: screenWidth * 0.1,
                      height: screenWidth * 0.1,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ticket No. ${ticketData.id}".tr,
                      style: AppTextStyle.latoBold20(context),
                    ),
                    Row(
                      spacing: 4,
                      children: [
                        Text(
                          '${ticketData.branchObject?.name}'.tr,
                          style: AppTextStyle.latoBold16(
                            context,
                          ).copyWith(color: AppColors.green),
                        ),
                        Container(
                          width: screenWidth * 0.012,
                          height: screenHeight * 0.006,
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${ticketData.priority}',
                            overflow: TextOverflow.clip,
                            style: AppTextStyle.latoBold16(
                              context,
                            ).copyWith(color: AppColors.green),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${ticketData.attachment}',
                      style: AppTextStyle.latoRegular19(context),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              children: [
                Text("Status".tr, style: AppTextStyle.latoRegular16(context)),
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.01,
                    horizontal: screenWidth * 0.04,
                  ),
                  decoration: BoxDecoration(
                    color: '${ticketData.status}' == 'Awaiting'
                        ? const Color(0xffDFE699)
                        : '${ticketData.status}' == 'Completed'
                        ? const Color(0xff8FCFAD)
                        : const Color(0xffDBA0A0),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '${ticketData.status}'.tr,
                    style: AppTextStyle.latoBold16(
                      context,
                    ).copyWith(color: AppColors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text("Comment".tr),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.lightgray,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    _buildInfoRow('Request Date'.tr, '${ticketData.requestDate}'),
                    _buildInfoRow(
                      'Response Date'.tr,
                      '${ticketData.responseDate}',
                    ),
                    _buildInfoRow('Priority'.tr, '${ticketData.priority}'),
                  ],
                ),
              ),
              Container(
                height: screenHeight * 0.12,
                width: 1.5,
                color: AppColors.gray,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      _buildInfoRow('Repair Date'.tr, '${ticketData.repairDate}'),
                      _buildInfoRow('Closed By'.tr, '${ticketData.closedBy}'),
                      _buildInfoRow('Engineer'.tr, '${ticketData.engineer}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(label), Text(value ?? '----')],
    );
  }
}
