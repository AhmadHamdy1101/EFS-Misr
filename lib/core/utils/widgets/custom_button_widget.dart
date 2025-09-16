import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';

import '../app_text_styles.dart';

class CustomButtonWidget extends StatelessWidget {
  const CustomButtonWidget({
    super.key,
    required this.screenWidth, this.text, this.color, this.foregroundcolor, this.onpressed, this.toppadding, this.textstyle,
  });

  final screenWidth;
  final text;
  final color;
  final foregroundcolor;
  final onpressed;
  final toppadding;
  final textstyle;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: toppadding),
        ),
        backgroundColor: WidgetStatePropertyAll(
          color,
        ),
        foregroundColor: WidgetStatePropertyAll(
          foregroundcolor,
        ),
      ),
      onPressed: onpressed,
      child: Text(
        text,
        style: textstyle,
      ),
    );
  }
}