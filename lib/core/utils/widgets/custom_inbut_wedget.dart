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
    this.textEditingController,
    this.textInputType,
    this.validator,
    this.onChanged,
    this.readOnly,
    this.onTap,
  });

  final String inbutIcon;
  final String inbutHintText;
  final bool changeToPass;
  final TextEditingController? textEditingController;
  final TextInputType? textInputType;
  final String? Function(String?)? validator;
  final String? Function(String?)? onChanged;
  final bool? readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Theme.of(context).buttonTheme.colorScheme?.primary,
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
      child: TextFormField(
        // readOnly: readOnly ?? false,
        onTap: onTap,
        onChanged: onChanged,
        validator: validator,
        cursorColor: AppColors.black,
        keyboardType: textInputType,
        controller: textEditingController,
        obscureText: changeToPass,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).buttonTheme.colorScheme?.primary,
          hintStyle: AppTextStyle.latoRegular16(
            context,
          ).copyWith(color: Theme.of(context).colorScheme.primary),
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
