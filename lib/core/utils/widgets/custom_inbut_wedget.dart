
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';

class CustomInputWidget extends StatelessWidget {
  const CustomInputWidget({
    super.key,
    required this.inbutIcon,
    required this.inbutHintText,
    required this.changeToPass,
    required this.textEditingController,
    this.textInputType,
  });
  final String inbutIcon;
  final String inbutHintText;
  final bool changeToPass;
  final TextEditingController textEditingController;
  final TextInputType? textInputType;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40), // pill shape
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        cursorColor: AppColors.black,
        keyboardType: textInputType,
        controller: textEditingController,
        obscureText: changeToPass,
        decoration: InputDecoration(
          hintStyle: AppTextStyle.latoRegular16(context),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(9.0),
            child: SvgPicture.asset(inbutIcon),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 30, // العرض المطلوب
            minHeight: 30, // الطول المطلوب
          ),
          hintText: inbutHintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
