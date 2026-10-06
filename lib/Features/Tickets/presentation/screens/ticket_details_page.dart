import 'package:efs_misr/Features/Tickets/presentation/widgets/ticket_details_page_body.dart';
import 'package:efs_misr/constants/screens_size.dart';
import 'package:efs_misr/generated/app_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

import '../../../../core/models/tickets.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../Home/presentation/widgets/qr_view_ticket.dart';

class TicketDetailsPage extends StatelessWidget {
  const TicketDetailsPage({super.key, required this.tickets});
final Tickets tickets;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        elevation: 5,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () {
          Get.to(QRScanTicketPage(ticketId: tickets.id));
        },
        child: SvgPicture.asset(
          AppImages.images.qrCodeScanner.path,
          width:ScreensSize(context).screenWidth *0.07,
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        leading: BackButton(color: Theme.of(context).colorScheme.primary),
        title: Text(
          'Tickets Details'.tr,
          style: AppTextStyle.latoBold26(
            context,
          ).copyWith(color: AppColors.green),
        ),
      ),
      body: TicketDetailsPageBody(ticket: tickets,),
    );
  }
}