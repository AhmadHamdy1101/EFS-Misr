import 'package:flutter/material.dart';


class CustomOutlineButtonWidget extends StatelessWidget {
  const CustomOutlineButtonWidget({
    super.key,
    required this.screenWidth, this.text, this.color, this.foregroundColor, this.onPressed, required this.borderColor, required this.topPadding, this.textStyle,
  });

  final double? screenWidth;
  final String? text;
  final Color? color;
  final Color? foregroundColor;
  final VoidCallback? onPressed;
  final Color borderColor;
  final double topPadding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(

      style: ButtonStyle(
        
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: topPadding),
        ),
        backgroundColor: WidgetStatePropertyAll(
          color,
        ),
        foregroundColor: WidgetStatePropertyAll(
          foregroundColor,
        ),
          side: WidgetStatePropertyAll(BorderSide(color: borderColor, width: 3)),
      ),
      
      

      onPressed: onPressed,
      child: Text(
        text??'',
        style: textStyle,
      ),
    );
  }
}