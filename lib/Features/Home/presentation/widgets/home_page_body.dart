
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/custom_profile_wedget.dart';
import '../../../../core/utils/widgets/custome_back_shape_wedget.dart';
import '../../../../core/utils/widgets/custome_overview_widget.dart';

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
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 30),
                        padding: EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.lightgray,width: 3))),
                        child: Column(
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
                                        color: AppColors.lightgreen.withOpacity(
                                          0.25,
                                        ),
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
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Ticket No. 20156",
                                          style: AppTextStyle.latoBold20(context),
                                        ),
                                        Row(
                                          spacing: 2,
                                          children: [
                                            Text(
                                              "Branch id",
                                              style: AppTextStyle.latoBold16(
                                                context,
                                              ).copyWith(color: AppColors.green),
                                            ),
                                            Container(
                                              width: screenWidth * 0.012,
                                              height: screenHeight * 0.006,
                                              decoration: BoxDecoration(
                                                color: AppColors.green,
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                              ),
                                            ),
                                            Text(
                                              "Branch Name",
                                              style: AppTextStyle.latoBold16(
                                                context,
                                              ).copyWith(color: AppColors.green),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          "Area",
                                          style: AppTextStyle.latoRegular19(
                                            context,
                                          ),
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
                                        color: Color(0xffDFE699),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Text(
                                        "Awaiting",
                                        style: AppTextStyle.latoBold16(
                                          context,
                                        ).copyWith(color: AppColors.white),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text("Comment"),
                            Container(
                              padding: EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: AppColors.lightgray,
                                borderRadius: BorderRadius.circular(10),
                              ),

                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      spacing: 10,

                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Requset Date'),
                                            Text("20 August 2025"),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Response Date:'),
                                            Text("20 August 2025"),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text('Priority: '),
                                            Text("A"),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: screenHeight * 0.12,
                                    width: 1.5,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                      color: AppColors.gray,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Column(
                                        spacing: 10,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Repair Date: '),
                                              Text("20 August 2025"),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Closed By:'),
                                              Text("----"),
                                            ],
                                          ), Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text('Engineer:'),
                                              Text("----"),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
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
