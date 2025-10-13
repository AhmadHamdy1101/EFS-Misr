import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/presentation/widgets/assets_page_details_body.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';

class AssetsDetailsPage extends StatelessWidget {
  const AssetsDetailsPage({super.key, required this.assets});
  final Assets assets;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: BackButton(color: Theme.of(context).colorScheme.primary),
        title: Text(
          'Assets Details'.tr,
          style: AppTextStyle.latoBold26(
            context,
          ).copyWith(color: AppColors.green),
        ),
      ),
      body: AssetsDetailsPageBody(assets: assets),
    );
  }
}
