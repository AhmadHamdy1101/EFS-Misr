import 'package:efs_misr/constants/screens_size.dart';
import 'package:efs_misr/core/models/assets_repair.dart';
import 'package:efs_misr/generated/app_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/Functions/GetDate_Function.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';

class AssetsRepairCard extends StatelessWidget {
  const AssetsRepairCard({super.key, required this.assetsRepair});

  final AssetsRepair assetsRepair;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.all(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          spacing: 10,
          children: [
            Row(
              spacing: 15,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withAlpha(30),
                        spreadRadius: 0,
                        blurRadius: 11.2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    child: SvgPicture.asset(AppImages.images.deductions.path),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          assetsRepair.variation ?? 'No Type'.tr,
                          style: AppTextStyle.latoRegular15(
                            context,
                          ).copyWith(color: AppColors.white),
                        ),
                      ),
                      Text(
                        getDateFromTimestamp(assetsRepair.createdAt),
                        style: AppTextStyle.latoBold16(context),
                      ),
                      Text(
                        '${assetsRepair.comment}',
                        style: AppTextStyle.latoRegular16(
                          context,
                        ).copyWith(color: AppColors.gray),
                      ),
                    ],
                  ),
                ),
                Text(
                  "${assetsRepair.amount ?? 0}",
                  style: AppTextStyle.latoBold26(
                    context,
                  ).copyWith(color: AppColors.green),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "EGP".tr,
                  style: AppTextStyle.latoBold26(
                    context,
                  ).copyWith(color: AppColors.green),
                  textAlign: TextAlign.center,
                ),
                SizedBox(width: ScreensSize(context).screenWidth * 0.01),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
