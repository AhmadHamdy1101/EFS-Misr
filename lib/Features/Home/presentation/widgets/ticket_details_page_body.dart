import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/assets_tickets_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/tickets_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/widgets/QRViewTicket.dart';
import 'package:efs_misr/core/Functions/GetDate_Function.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/widgets/custom_button_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_inbut_wedget.dart';
import 'package:efs_misr/core/utils/widgets/custom_outline_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_text_styles.dart';

class TicketDetailsPageBody extends StatelessWidget {
  final Tickets ticket;

  const TicketDetailsPageBody({super.key, required this.ticket});

  // design here
  @override
  Widget build(BuildContext context) {
    final TextEditingController DamagesComment = TextEditingController();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        elevation: 5,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () {
          Get.to(QRScanTicketPage(ticketId: ticket.id));
        },
        child: SvgPicture.asset(
          'assets/images/Qr code scanner.svg',
          width: screenWidth * 0.07,
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Tickets Details'.tr,
          style: AppTextStyle.latoBold26(
            context,
          ).copyWith(color: AppColors.green),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: 20,
                horizontal: screenWidth * 0.03,
              ),
              child: Column(
                spacing: 20,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Container(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        spacing: 10,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            spacing: 15,
                            children: [
                              Container(
                                padding: EdgeInsets.all(screenWidth * 0.03),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGreen.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: ClipRRect(
                                  child: SvgPicture.asset(
                                    'assets/images/ticket.svg',
                                    color: AppColors.green,
                                    width: screenWidth * 0.1,
                                    height: screenWidth * 0.1,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    spacing: 5,
                                    children: [
                                      Text(
                                        "Ticket No.".tr,
                                        style: AppTextStyle.latoBold20(context),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        softWrap: false,
                                      ),
                                      Text(
                                        "${ticket.orecalId}".tr,
                                        style: AppTextStyle.latoBold20(context),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        softWrap: false,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    spacing: 4,
                                    children: [
                                      Text(
                                        '${ticket.branchObject?.branchId}',
                                        style: AppTextStyle.latoBold16(
                                          context,
                                        ).copyWith(color: AppColors.green),
                                      ),
                                      Container(
                                        width: screenWidth * 0.012,
                                        height: screenHeight * 0.006,
                                        decoration: BoxDecoration(
                                          color: AppColors.green,
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${ticket.branchObject?.name}',
                                        style: AppTextStyle.latoBold16(
                                          context,
                                        ).copyWith(color: AppColors.green),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${ticket.branchObject?.area}',
                                    style: AppTextStyle.latoRegular19(context),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      "Status".tr,
                                      style: AppTextStyle.latoRegular16(
                                        context,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: screenHeight * 0.01,
                                        horizontal: screenWidth * 0.04,
                                      ),
                                      decoration: BoxDecoration(
                                        color: '${ticket.status}' == 'Awaiting'
                                            ? const Color(0xffDFE699)
                                            : '${ticket.status}' == 'Completed'
                                            ? const Color(0xff8FCFAD)
                                            : const Color(0xffDBA0A0),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Text(
                                        '${ticket.status}'.tr,
                                        style: AppTextStyle.latoBold13(
                                          context,
                                        ).copyWith(color: AppColors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Text('${ticket.comment}'.tr),
                          if (ticket.status == 'Awaiting')
                            Row(
                              spacing: 10,
                              children: [
                                Expanded(
                                  child: CustomOutlineButtonWidget(
                                    screenWidth: screenWidth,
                                    color: Colors.transparent,
                                    foregroundColor: AppColors.green,
                                    onPressed: () {
                                      context
                                          .read<TicketsCubit>()
                                          .updateTicketStatus(
                                            ticket.id.toString(),
                                            "Canceled",
                                          );
                                    },
                                    text: 'Canceled',
                                    borderColor: AppColors.green,
                                    topPadding: 15.0,
                                    textStyle: AppTextStyle.latoBold20(context),
                                  ),
                                ),
                                Expanded(
                                  child: CustomButtonWidget(
                                    screenWidth: screenWidth,
                                    text: 'Complete',
                                    onpressed: () {
                                      context
                                          .read<TicketsCubit>()
                                          .updateTicketStatus(
                                            ticket.id.toString(),
                                            "Complete",
                                          );
                                    },
                                    foregroundcolor: AppColors.white,
                                    color: AppColors.green,
                                    toppadding: 15.0,
                                    textstyle: AppTextStyle.latoBold20(context),
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    "Ticket Details".tr,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Card(
                    child: Container(
                      padding: EdgeInsets.all(20.0),
                      child: Row(
                        spacing: 15,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              spacing: 10,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Request Date'.tr,
                                      style: AppTextStyle.latoBold20(
                                        context,
                                      ).copyWith(color: AppColors.green),
                                    ),
                                    Text(
                                      getDateFromTimestamp(ticket.requestDate!),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Repair Date:'.tr,
                                      style: AppTextStyle.latoBold20(
                                        context,
                                      ).copyWith(color: AppColors.green),
                                    ),
                                    Text(
                                      getDateFromTimestamp(
                                        ticket.repairDate ?? DateTime.now(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: screenHeight * 0.13,
                            width: 1,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                              color: AppColors.gray,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              spacing: 10,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Request Date:'.tr,
                                      style: AppTextStyle.latoBold20(
                                        context,
                                      ).copyWith(color: AppColors.green),
                                    ),
                                    Text(
                                      getDateFromTimestamp(ticket.requestDate!),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Response Date:'.tr,
                                      style: AppTextStyle.latoBold20(
                                        context,
                                      ).copyWith(color: AppColors.green),
                                    ),
                                    Text(
                                      getDateFromTimestamp(
                                        ticket.responseDate ?? DateTime.now(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: Container(
                      padding: EdgeInsets.all(20.0),
                      child: Row(
                        spacing: 15,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              spacing: 10,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Priority:'.tr,
                                      style: AppTextStyle.latoBold20(
                                        context,
                                      ).copyWith(color: AppColors.green),
                                    ),
                                    Text("${ticket.priority}"),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Closed By:'.tr,
                                      style: AppTextStyle.latoBold20(
                                        context,
                                      ).copyWith(color: AppColors.green),
                                    ),
                                    Text('${ticket.user!.name}'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: screenHeight * 0.13,
                            width: 1,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                              color: AppColors.gray,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              spacing: 10,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Engineer:'.tr,
                                      style: AppTextStyle.latoBold20(
                                        context,
                                      ).copyWith(color: AppColors.green),
                                    ),
                                    Text(ticket.user!.name!),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: Container(
                      padding: EdgeInsets.all(20.0),
                      width: screenWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Damage Description:'.tr,
                                style: AppTextStyle.latoBold20(
                                  context,
                                ).copyWith(color: AppColors.green),
                              ),

                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        backgroundColor: AppColors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: SingleChildScrollView(
                                          // 👈 يضمن إن مفيش overflow
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              spacing: 10,
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .stretch, // 👈 بدل stretch
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [CloseButton()],
                                                ),

                                                CustomInputWidget(
                                                  inbutIcon:
                                                      "assets/images/comment.svg",
                                                  inbutHintText:
                                                      "Damage Description",
                                                  changeToPass: false,
                                                  textEditingController:
                                                      DamagesComment,
                                                ),
                                                CustomButtonWidget(
                                                  screenWidth: screenWidth,
                                                  toppadding: 10.0,
                                                  textstyle:
                                                      AppTextStyle.latoBold20(
                                                        context,
                                                      ),
                                                  foregroundcolor:
                                                      AppColors.white,
                                                  onpressed: () {
                                                    Navigator.pop(
                                                      context,
                                                    ); // يقفل الـ Dialog بعد الضغط
                                                  },
                                                  text: 'Submit',
                                                  color: AppColors.green,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Text(
                                  'Edit',
                                  style: AppTextStyle.latoBold20(
                                    context,
                                  ).copyWith(color: AppColors.gray),
                                ),
                              ),
                            ],
                          ),
                          Text("${ticket.damageDescription}"),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: Container(
                      padding: EdgeInsets.all(20.0),
                      width: screenWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attachment:'.tr,
                            style: AppTextStyle.latoBold20(
                              context,
                            ).copyWith(color: AppColors.green),
                          ),
                          Text("${ticket.attachment}"),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    "Assets".tr,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: BlocBuilder<AssetsTicketsCubit, AssetsTicketsState>(
              builder: (context, state) {
                if (state is GetAssetsTicketsFailure) {
                  return Center(child: Text(state.message),);
                }
                if (state is GetAssetsTicketsLoading) {
                  return Center(child: CircularProgressIndicator(color: AppColors.green,),);
                }
                if (state is GetAssetsTicketsSuccess) {
                  final data = state.assetsAndTickets;
                  return ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                        return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.all(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 20,
                          ),
                          child: Row(
                            spacing: 15,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(screenWidth * 0.03),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGreen.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: ClipRRect(
                                  child: SvgPicture.asset(
                                    'assets/images/Chair.svg',
                                    color: AppColors.green,
                                    width: screenWidth * 0.1,
                                    height: screenWidth * 0.1,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("${data[index].type}".tr),
                                      Text('${data[index].barcode}'),
                                    ],
                                  ),
                                  Text(
                                    '${data[index].branchObject?.name}'.tr,
                                    style: AppTextStyle.latoRegular16(
                                      context,
                                    ).copyWith(color: AppColors.green),
                                  ),
                                  Text(
                                    '${data[index].branchObject?.area}'.tr,
                                    style: AppTextStyle.latoRegular16(
                                      context,
                                    ).copyWith(color: AppColors.gray),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );

                    },
                  );
                }
                return Text('No Assets Added Yet');
              },

            ),
          ),
        ],
      ),
    );
  }
}
