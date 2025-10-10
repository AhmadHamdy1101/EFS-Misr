import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/core/Functions/Capitalize_Function.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../Functions/GetDate_Function.dart';
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
          spacing: 5,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              spacing: 15,
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen.withOpacity(0.25),
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
                    SizedBox(
                      height: 24,
                      width: screenWidth * 0.32,
                      child: Row(
                        spacing: 5,
                        children: [
                          Text(
                            "Ticket No.".tr,
                            style: AppTextStyle.latoBold16(context),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            softWrap: false,
                          ),
                          Text(
                            "${ticketData.orecalId}".tr,
                            style: AppTextStyle.latoBold16(context),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            softWrap: false,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      spacing: 4,
                      children: [
                        SizedBox(
                          child: Text(
                            '${ticketData.branchObject?.branchId}'.tr,
                            style: AppTextStyle.latoBold16(
                              context,
                            ).copyWith(color: AppColors.green),
                          ),
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
                            capitalizeEachWord('${ticketData.branchObject?.name}'),
                            overflow: TextOverflow.clip,
                            style: AppTextStyle.latoBold16(
                              context,
                            ).copyWith(color: AppColors.green),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 24,
                      width: screenWidth * 0.32,
                      child: Text(
                        capitalizeEachWord('${ticketData.branchObject?.areaObject!.name}'),
                        style: AppTextStyle.latoRegular19(context),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
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
        Text(
          '${ticketData.comment}'.tr,
          style: AppTextStyle.latoBold20(context),
        ),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary,
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
                    _buildInfoRow(
                      'Request Date'.tr,
                      getDateFromTimestamp(ticketData.requestDate!),
                      context,
                    ),
                    _buildInfoRow(
                      'Response Date'.tr,
                      getDateFromTimestamp(
                        ticketData.responseDate ?? DateTime.now(),
                      ),
                      context,
                    ),
                    _buildInfoRow(
                      'Priority'.tr,
                      '${ticketData.priority}',
                      context,
                    ),
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
                      _buildInfoRow(
                        'Repair Date'.tr,
                        getDateFromTimestamp(
                          ticketData.repairDate ?? DateTime.now(),
                        ),
                        context,
                      ),
                      _buildInfoRow(
                        'Closed By'.tr,
                        ticketData.user?.name ?? '__',
                        context,
                      ),
                      _buildInfoRow(
                        'Engineer'.tr,
                        ticketData.user?.name ?? '__',
                        context,
                      ),
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

  Widget _buildInfoRow(String label, dynamic value, context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyle.latoBold23(context)),
        Text(value ?? '----'),
      ],
    );
  }
}
