
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_text_styles.dart';

class AddSuccessPageBody extends StatelessWidget {
  const AddSuccessPageBody({super.key, required this.message});

  final String message;

  // design here
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SizedBox(
        height: screenHeight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 20,
            children: [
              SvgPicture.asset('assets/images/submited.svg'),
              Text('Add Successful', style: AppTextStyle.latoBold26(context)),
              Text(message, style: AppTextStyle.latoBold26(context)),
              SizedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.green, AppColors.lightGreen],
                          begin: Alignment.topLeft, // نقطة البداية
                          end: Alignment.bottomRight, // نقطة النهاية
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                      ),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Colors.transparent,
                          ),
                          elevation: MaterialStateProperty.all<double>(0),
                        ),
                        child: Text(
                          'Add Another Account',
                          style: AppTextStyle.latoBold20(
                            context,
                          ).copyWith(color: AppColors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(
                    Colors.transparent,
                  ),
                  elevation: WidgetStateProperty.all<double>(0),
                ),
                child: Text(
                  'Back',
                  style: AppTextStyle.latoBold20(
                    context,
                  ).copyWith(color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
