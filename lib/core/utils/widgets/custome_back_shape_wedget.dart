
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
class CustomBackShapeWedget extends StatelessWidget {
  const CustomBackShapeWedget({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: SvgPicture.asset(
        "assets/images/logoIcon.svg",
        width: screenWidth * 0.3,
        height: screenHeight * 0.3,
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Colors.white.withOpacity(0.2),
          BlendMode.srcIn,
        ),
      ),
    );
  }
}