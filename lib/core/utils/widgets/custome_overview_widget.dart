
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';
import '../app_text_styles.dart';
class CustomOverviewWidget extends StatelessWidget {
   const CustomOverviewWidget({
    super.key,
    required this.screenHeight,
    required this.screenWidth, required this.totalTickets, required this.doneTickets, required this.awaitTickets,
  });

  final double screenHeight;
  final double screenWidth;


  final int totalTickets;
  final int doneTickets;
  final int awaitTickets;

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    final formattedDate = DateFormat('d - MMM - yyyy').format(now);
    return Positioned(
      top: screenHeight * 0.15,
      left: screenWidth * 0.035,
      child: Container(
        width: screenWidth * 0.93,
        
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: Theme.of(context).colorScheme.surface,
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
              "Today Overview".tr,
              style: AppTextStyle.latoBold26(
                context,
              ).copyWith(color: AppColors.gray),
            ),
            Text(
              formattedDate,
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
                color: Theme.of(context).colorScheme.tertiary,
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
                        "Total \n Tickets".tr,
                        style: AppTextStyle.latoBold26(context),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "$totalTickets",
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
                        "Done \n Tickets".tr,
                        style: AppTextStyle.latoBold26(context),
                        textAlign: TextAlign.center,

                      ),
                      Text(
                        "$doneTickets",
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
                        "Awaiting \n Tickets".tr,
                        style: AppTextStyle.latoBold26(context),
                        textAlign: TextAlign.center,

                      ),
                      Text(
                        "$awaitTickets",
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