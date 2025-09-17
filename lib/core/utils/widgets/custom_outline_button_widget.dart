import 'package:flutter/material.dart';


class CustomOutlineButtonWidget extends StatelessWidget {
  const CustomOutlineButtonWidget({
    super.key,
    required this.screenWidth, this.text, this.color, this.foregroundcolor, this.onpressed, this.bordercolor, this.toppadding, this.textstyle,
  });

  final screenWidth;
  final text;
  final color;
  final foregroundcolor;
  final onpressed;
  final bordercolor;
  final toppadding;
  final textstyle;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(

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
          side: WidgetStatePropertyAll(BorderSide(color: bordercolor, width: 3)),
      ),
      
      

      onPressed: onpressed,
      child: Text(
        text,
        style: textstyle,
      ),
    );
  }
}