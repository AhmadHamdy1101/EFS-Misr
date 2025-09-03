import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';

class CustomListButton extends StatelessWidget {
  const CustomListButton({
    super.key,
    required this.buttonsData,
  });

  final List<Map<String, dynamic>> buttonsData;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120, // ارتفاع ثابت مناسب لكل الأجهزة
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView.builder(
            itemCount: buttonsData.length,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final button = buttonsData[index];
              final itemWidth = constraints.maxWidth * 0.13; // العرض النسبي
              final iconSize =
                  constraints.maxHeight * 0.21; // حجم الأيقونة نسبة للارتفاع

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GestureDetector(
                  onTap: button['onTap'],
                  child: SizedBox(
                    width: itemWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: iconSize + 19,
                          height: iconSize + 19,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: SvgPicture.asset(
                            button['icon'],
                            width: iconSize,
                            height: iconSize,
                            colorFilter: ColorFilter.mode(
                              button['color'],
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          child: Text(
                            button['title'],
                            style: AppTextStyle.latoBold16(
                              context,
                            ).copyWith(color: AppColors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}