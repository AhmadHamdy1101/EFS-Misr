import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/ticket_page_body.dart';

class TicketPage extends StatelessWidget {
  const TicketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.AppBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: SizedBox(),
          centerTitle: true,
          title: Text(
            'Tickets'.tr,
            style: AppTextStyle.latoBold26(
              context,
            ).copyWith(color: AppColors.green),
          ),
        ),
        body: TicketPageBody());
  }
}