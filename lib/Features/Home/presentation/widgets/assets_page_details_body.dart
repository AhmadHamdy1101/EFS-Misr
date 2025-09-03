import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';

class AssetsDetailsPageBody extends StatelessWidget {
  const AssetsDetailsPageBody({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            color: AppColors.white,
            margin: const EdgeInsets.all(12),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                spacing: 10,
                children: [
                  Row(
                    spacing: 15,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: AppColors.lightgreen.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: ClipRRect(
                          child: SvgPicture.asset(
                            'assets/images/Chair.svg',
                            color: AppColors.green,
                            width: screenWidth * 0.1,
                            height: screenWidth * 0.1,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [Text("AC:"), Text('9154567945')]),
                          Text(
                            'Branch Name',
                            style: AppTextStyle.latoRegular16(
                              context,
                            ).copyWith(color: AppColors.green),
                          ),
                          Text(
                            'New Cairo',
                            style: AppTextStyle.latoRegular16(
                              context,
                            ).copyWith(color: AppColors.gray),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          spacing: 10,
                          children: [
                            Text("Total Spend"),
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.01,
                                horizontal: screenWidth * 0.04,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xff8FCFAD),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                "1,000 EGP",
                                style: AppTextStyle.latoBold16(
                                  context,
                                ).copyWith(color: AppColors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: screenWidth,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColors.lightgray,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text('Room: Manager Room'),
                            Text('Type: Career 2.5 horse power'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            color: AppColors.white,
            margin: const EdgeInsets.all(12),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                spacing: 10,
                children: [
                  Row(
                    spacing: 15,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal:screenWidth * 0.03 ,vertical: screenHeight*0.01),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(60),
                          boxShadow: [BoxShadow(color: AppColors.black.withAlpha(30),spreadRadius: 0,blurRadius: 11.2)]
                        ),
                        child: ClipRRect(
                          child: SvgPicture.asset(
                            'assets/images/deductions.svg',
                            color: AppColors.green,
                            width: screenWidth * 0.09,
                            height: screenWidth * 0.09,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
    padding: EdgeInsets.symmetric(vertical: 5,horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              borderRadius: BorderRadius.circular(50)
                            ),
                            child: Text('Spare Parts',style: AppTextStyle.latoRegular15(context).copyWith(color: AppColors.white),),
                          ),
                          Text(
                            '10 August 2025',
                            style: AppTextStyle.latoBold16(
                              context,
                            ),
                          ),
                          Text(
                            'Comment',
                            style: AppTextStyle.latoRegular16(
                              context,
                            ).copyWith(color: AppColors.gray),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Text(
                          "1,000 EGP",
                          style: AppTextStyle.latoBold26(
                            context,
                          ).copyWith(color: AppColors.green),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
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
