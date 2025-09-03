import 'package:efs_misr/Features/Home/presentation/pages/ticket_details_page.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/ticket_overview_widget.dart';

final List<Map<String, dynamic>> TicketData = [
  {
    'id' : '1',
    'TicketNo': '202156',
    'BranchId': 'BR-101',
    'BranchName': 'Cairo Branch',
    'Area': 'New Cairo',
    'Status': 'Awaiting',
    'RequestDate': '20 August 2025',
    'ResponseDate': '21 August 2025',
    'Priority': 'A',
    'RepairDate': '22 August 2025',
    'ClosedBy': '----',
    'Engineer': '----',
  },
  {
    'id': '2',
    'TicketNo': '202157',
    'BranchId': 'BR-102',
    'BranchName': 'Giza Branch',
    'Area': '6th October',
    'Status': 'Completed',
    'RequestDate': '18 August 2025',
    'ResponseDate': '19 August 2025',
    'Priority': 'B',
    'RepairDate': '',
  },
  {
    'id': '3',
    'TicketNo': '202157',
    'BranchId': 'BR-102',
    'BranchName': 'Giza Branch',
    'Area': '6th October',
    'Status': 'Rejected',
    'RequestDate': '18 August 2025',
    'ResponseDate': '19 August 2025',
    'Priority': 'B',
    'RepairDate': '',
  },
];

class TicketPageBody extends StatelessWidget {
  const TicketPageBody({super.key});

  // design here
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.AppBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,

        leading: SizedBox(),
        centerTitle: true,
        title: Text(
          'Tickets',
          style: AppTextStyle.latoBold26(
            context,
          ).copyWith(color: AppColors.green),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: TicketData.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {Get.to(TicketDetailsPage(TicketId: TicketData[index]['id'],));},
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                color: AppColors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TicketOverViewWidget(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    TicketData: TicketData[index],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
