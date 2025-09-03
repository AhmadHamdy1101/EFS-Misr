import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';

class TicketOverViewWidget extends StatelessWidget {
  const TicketOverViewWidget({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.TicketData,
  });

  final double screenWidth;
  final double screenHeight;
  final Map<String, dynamic> TicketData;

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
              "Ticket No. ${TicketData['TicketNo'] ?? ''}",
              style: AppTextStyle.latoBold20(context),
            ),
            Row(
              spacing: 4,
              children: [
                Text(
                  TicketData['BranchId'] ?? '',
                  style: AppTextStyle.latoBold16(context)
                      .copyWith(color: AppColors.green),
                ),
                Container(
                  width: screenWidth * 0.012,
                  height: screenHeight * 0.006,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                Text(
                  TicketData['BranchName'] ?? '',
                  style: AppTextStyle.latoBold16(context)
                      .copyWith(color: AppColors.green),
                ),
              ],
            ),
            Text(
              TicketData['Area'] ?? '',
              style: AppTextStyle.latoRegular19(context),
            ),
          ],
        ),
      ],
    ),
    Column(
    children: [
    Text(
    "Status",
    style: AppTextStyle.latoRegular16(context),
    ),
    Container(
    padding: EdgeInsets.symmetric(
    vertical: screenHeight * 0.01,
    horizontal: screenWidth * 0.04,
    ),
    decoration: BoxDecoration(
    color: TicketData['Status'] == 'Awaiting'
    ? const Color(0xffDFE699)
        : TicketData['Status'] == 'Completed'
    ? const Color(0xff8FCFAD)
        : const Color(0xffDBA0A0),
    borderRadius: BorderRadius.circular(50),
    ),
    child: Text(
    TicketData['Status'] ?? 'Unknown',
    style: AppTextStyle.latoBold16(context)
        .copyWith(color: AppColors.white),
    ),
    ),
    ],
    ),
    ],
    ),
    const SizedBox(height: 10),
    Text("Comment"),
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
    _buildInfoRow('Request Date', TicketData['RequestDate']),
    _buildInfoRow('Response Date', TicketData['ResponseDate']),
    _buildInfoRow('Priority', TicketData['Priority']),
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
    _buildInfoRow('Repair Date', TicketData['RepairDate']),
    _buildInfoRow('Closed By', TicketData['ClosedBy']),
    _buildInfoRow('Engineer', TicketData['Engineer']),
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
      children: [
        Text(label),
        Text(value ?? '----'),
      ],
    );
  }
}
