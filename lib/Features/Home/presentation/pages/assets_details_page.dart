

import 'package:efs_misr/Features/Home/presentation/widgets/assets_page_details_body.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';

class AssetsDetailsPage extends StatefulWidget {
  const AssetsDetailsPage({super.key, this.Assetsid});
final Assetsid;
  @override
  State<AssetsDetailsPage> createState() => _AssetsDetailsPageState();
}

class _AssetsDetailsPageState extends State<AssetsDetailsPage> {



  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,

          centerTitle: true,
          title: Text(
            'Assets Details',
            style: AppTextStyle.latoBold26(
              context,
            ).copyWith(color: AppColors.green),
          ),
        ),
        backgroundColor: AppColors.AppBackground,body: AssetsDetailsPageBody()) ;
  }
}
