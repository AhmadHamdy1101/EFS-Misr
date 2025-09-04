import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/utils/app_text_styles.dart';

final List<Map<String, dynamic>> TicketData = [
  {
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

class TicketDetailsPageBody extends StatelessWidget {
  final Tickets ticket;
  const TicketDetailsPageBody({super.key, required this.ticket});

  // design here
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.AppBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,

        centerTitle: true,
        title: Text(
          'Tickets Details',
          style: AppTextStyle.latoBold26(
            context,
          ).copyWith(color: AppColors.green),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: screenWidth*0.03),
              child: Column(
                spacing: 20,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: AppColors.white,
                    child: Container(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                    "${ticket.id}",
                                    style: AppTextStyle.latoBold20(context),
                                  ),
                                  Row(
                                    spacing: 4,
                                    children: [
                                      Text(
                                        '2358',
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
                                      Text(
                                        '${ticket.branchObject?.name}',
                                        style: AppTextStyle.latoBold16(
                                          context,
                                        ).copyWith(color: AppColors.green),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${ticket.branchObject?.area}',
                                    style: AppTextStyle.latoRegular19(context),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      "${ticket.status}",
                                      style: AppTextStyle.latoRegular16(context),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: screenHeight * 0.01,
                                        horizontal: screenWidth * 0.04,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffDFE699),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Text(
                                        '${ticket.status}',
                                        style: AppTextStyle.latoBold16(
                                          context,
                                        ).copyWith(color: AppColors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Text('${ticket.comment}'),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    "Ticket Overview",
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),),
                  Card(
                    color: AppColors.white,

                    child: Container(
                      padding: EdgeInsets.all(20.0),
                      child:
                          Row(
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
                                      Text('Request Date',style: AppTextStyle.latoBold20(context).copyWith(color: AppColors.green)),
                                      Text("${ticket.requestDate}")
                                    ],),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Repair Date:',style: AppTextStyle.latoBold20(context).copyWith(color: AppColors.green)),
                                        Text("${ticket.repairDate}")
                                      ],),

                                  ],
                                ),
                              ),
                              Container(
                                height: screenHeight * 0.13,
                                width: 1,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
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
                                        Text('Request Date: ',style: AppTextStyle.latoBold20(context).copyWith(color: AppColors.green)),
                                        Text("${ticket.requestDate}")
                                      ],),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Response Date:',style: AppTextStyle.latoBold20(context).copyWith(color: AppColors.green)),
                                        Text("${ticket.responseDate}")
                                      ],),

                                  ],
                                ),
                              ),

                            ],
                          ),

                    ),
                  ),
                  Card(
                    color: AppColors.white,

                    child: Container(
                      padding: EdgeInsets.all(20.0),
                      child:
                      Row(
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
                                    Text('Priority:',style: AppTextStyle.latoBold20(context).copyWith(color: AppColors.green)),
                                    Text("${ticket.priority}")
                                  ],),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Closed By:',style: AppTextStyle.latoBold20(context).copyWith(color: AppColors.green)),
                                    Text("----")
                                  ],),

                              ],
                            ),
                          ),
                          Container(
                            height: screenHeight * 0.13,
                            width: 1,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
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
                                    Text('Engineer:',style: AppTextStyle.latoBold20(context).copyWith(color: AppColors.green)),
                                    Text("----")
                                  ],),

                              ],
                            ),
                          ),

                        ],
                      ),

                    ),
                  ),
                  Card(
                    color: AppColors.white,

                    child: Container(
                      padding: EdgeInsets.all(20.0),
                      width: screenWidth,
                      child:
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Damage Description:',style: AppTextStyle.latoBold20(context).copyWith(color: AppColors.green)),
                          Text("${ticket.damageDescription}")
                        ],),


                    ),
                  ),
                  Card(
                    color: AppColors.white,

                    child: Container(
                      padding: EdgeInsets.all(20.0),
                      width: screenWidth,
                      child:
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Attachment :',style: AppTextStyle.latoBold20(context).copyWith(color: AppColors.green)),
                          Text("${ticket.attachment}")
                        ],),


                    ),
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
