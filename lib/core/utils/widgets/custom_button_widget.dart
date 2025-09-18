import 'package:flutter/material.dart';


class CustomButtonWidget extends StatelessWidget {
  const CustomButtonWidget({
    super.key,
    required this.screenWidth, this.text, this.color, this.foregroundcolor, this.onpressed, required this.toppadding, required this.textstyle,
  });

  final double screenWidth;
  final String? text;
  final Color? color;
  final Color? foregroundcolor;
  final VoidCallback? onpressed;
  final double toppadding;
  final TextStyle textstyle;

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
        text!,
        style: textstyle,
      ),
    );
  }
}