import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';

class CustomLoginBtn extends StatelessWidget {
  const CustomLoginBtn({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Get.locale!.languageCode=='en'?Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Sign In'.tr, style: AppTextStyle.latoBold26(context)),
          SizedBox(width: MediaQuery.sizeOf(context).width * 0.05),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.green, AppColors.lightGreen],
                begin: Alignment.topLeft, // نقطة البداية
                end: Alignment.bottomRight, // نقطة النهاية
              ),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: IconButton(
              onPressed: onPressed,
              icon: SvgPicture.asset("assets/images/arrow.svg"),
            ),
          ),
        ],
      ):Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.green, AppColors.lightGreen],
                begin: Alignment.topLeft, // نقطة البداية
                end: Alignment.bottomRight, // نقطة النهاية
              ),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: IconButton(
              onPressed: onPressed,
              icon: SvgPicture.asset("assets/images/arrow.svg"),
            ),
          ),
          SizedBox(width: MediaQuery.sizeOf(context).width * 0.05),
          Text('Sign In'.tr, style: AppTextStyle.latoBold26(context)),


        ],
      )
    );
  }
}
