
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';

class CustomProfileWidget extends StatelessWidget {
  const CustomProfileWidget({
    super.key,
    required this.screenWidth, required this.image, required this.name, required this.position, this.onPress,
  });

  final double screenWidth;
  final String image;
  final String name;
  final String position;
  final VoidCallback? onPress;




  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 30,
      top: 40,
      child: SizedBox(
        width: screenWidth*0.85,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              spacing: 20,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    image,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyle.latoBold20(
                        context,
                      ).copyWith(color: AppColors.white),
                    ),
                    Text(
                      position,
                      style: AppTextStyle.latoRegular19(
                        context,
                      ).copyWith(color: AppColors.white),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 10),

            IconButton(onPressed: onPress, icon: SvgPicture.asset("assets/images/Notifecation.svg")),
          ],
        ),
      ),
    );
  }
}
