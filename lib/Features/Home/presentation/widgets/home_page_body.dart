
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/custom_profile_wedget.dart';
import '../../../../core/utils/widgets/custome_back_shape_wedget.dart';
import '../../../../core/utils/widgets/custome_overview_widget.dart';
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
class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key});


  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: screenHeight * 0.3,
                width: screenWidth,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.green, AppColors.lightgreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),
              // شعار SVG على الخلفية
              CustomBackShapeWedget(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
              // عناصر البروفايل فوق الخلفية
              CustomProfileWidget(
                screenWidth: screenWidth,
                image: "assets/images/profile.jpg",
                name: 'Mohamed Said',
                position: 'Oporation',
                onPress: () {},
              ),
              // الجزء اللي في نص Stack
              CustomOverviewWidget(
                screenHeight: screenWidth,
                screenWidth: screenWidth,
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 190)),

        SliverToBoxAdapter(
          // fillOverscroll: true,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            color: AppColors.white,
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                spacing: 20,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tickets Overview",
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    ],
                  ),
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: TicketData.length,
                    itemBuilder: (context, index) {
                      return Container(
                          margin: EdgeInsets.only(bottom: screenHeight*0.05),
                          child: TicketOverViewWidget(screenWidth:screenWidth, screenHeight: screenHeight, TicketData: TicketData[index]));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

      ],

    );

  }
}
