
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';
class CustomOverviewWidget extends StatelessWidget {
  const CustomOverviewWidget({
    super.key,
    required this.screenHeight,
    required this.screenWidth,
  });

  final double screenHeight;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: screenHeight * 0.39,
      left: screenWidth * 0.035,
      child: Container(
        width: screenWidth * 0.93,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 12.7,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          spacing: 5,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today Overview",
              style: AppTextStyle.latoBold26(
                context,
              ).copyWith(color: AppColors.gray),
            ),
            Text(
              '2 Sep 2025',
              style: AppTextStyle.latoBold26(
                context,
              ).copyWith(color: AppColors.green),
            ),
            SizedBox(height: 10,),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 20,
              ),
              decoration: BoxDecoration(
                color: AppColors.lightgray,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    spacing: 6,
                    children: [
                      Text(
                        "Total \n Ticket",
                        style: AppTextStyle.latoBold26(context),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "20",
                        style: AppTextStyle.latoBold26(context).copyWith(color: AppColors.green),
                      ),

                    ],
                  ),
                  Container(
                    height: screenHeight * 0.1,
                    width: 1,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                      color: AppColors.gray,
                    ),
                  ),
                  Column(
                    spacing: 6,
                    children: [
                      Text(
                        "Done \n Ticket",
                        style: AppTextStyle.latoBold26(context),
                        textAlign: TextAlign.center,

                      ),
                      Text(
                        "20",
                        style: AppTextStyle.latoBold26(context).copyWith(color: AppColors.green),
                      ),

                    ],
                  ),
                  Container(
                    height: screenHeight * 0.1,
                    width: 1,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                      color: AppColors.gray,
                    ),
                  ),
                  Column(
                    spacing: 6,
                    children: [
                      Text(
                        "Awaiting \n Ticket",
                        style: AppTextStyle.latoBold26(context),
                        textAlign: TextAlign.center,

                      ),
                      Text(
                        "20",
                        style: AppTextStyle.latoBold26(context).copyWith(color: AppColors.green),
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