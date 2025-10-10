import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/assets_repair_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/assets_tickets_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/tickets_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/widgets/QRViewTicket.dart';
import 'package:efs_misr/core/Functions/GetDate_Function.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/widgets/custom_button_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_dropdown_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_inbut_wedget.dart';
import 'package:efs_misr/core/utils/widgets/custom_outline_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/Functions/Capitalize_Function.dart';
import '../../../../core/utils/app_text_styles.dart';

class TicketDetailsPageBody extends StatefulWidget {
  final Tickets ticket;

  const TicketDetailsPageBody({super.key, required this.ticket});

  @override
  State<TicketDetailsPageBody> createState() => _TicketDetailsPageBodyState();
}

class _TicketDetailsPageBodyState extends State<TicketDetailsPageBody> {
  final TextEditingController damageComment = TextEditingController();
  final TextEditingController amount = TextEditingController();
  final TextEditingController comment = TextEditingController();
  final Data = [
    {'name': 'Spare Parts', 'value': 'Spare Parts'},
    {'name': 'No Spare Parts', 'value': 'No Spare Parts'},
  ];
  String? selectedValue;
  final selectedRepairValue = ''.obs;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        elevation: 5,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () {
          Get.to(QRScanTicketPage(ticketId: widget.ticket.id));
        },
        child: SvgPicture.asset(
          'assets/images/Qr code scanner.svg',
          width: screenWidth * 0.07,
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
                      child: BlocBuilder<TicketsCubit, TicketsState>(
                        builder: (context, state) {
                          if (state is GetTicketsSuccess) {
                            final currentTicket = state.tickets.firstWhere(
                              (t) => t.id == widget.ticket.id,
                              orElse: () => widget.ticket,
                            );
                            return Column(
                              spacing: 10,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  spacing: 15,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        screenWidth * 0.03,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.lightGreen.withOpacity(
                                          0.25,
                                        ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          spacing: 5,
                                          children: [
                                            Text(
                                              "Ticket No.".tr,
                                              style: AppTextStyle.latoBold20(
                                                context,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              softWrap: false,
                                            ),
                                            Text(
                                              "${widget.ticket.orecalId}".tr,
                                              style: AppTextStyle.latoBold20(
                                                context,
                                              ),
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
                                              '${widget.ticket.branchObject?.branchId}',
                                              style:
                                                  AppTextStyle.latoBold16(
                                                    context,
                                                  ).copyWith(
                                                    color: AppColors.green,
                                                  ),
                                            ),
                                            Container(
                                              width: screenWidth * 0.012,
                                              height: screenHeight * 0.006,
                                              decoration: BoxDecoration(
                                                color: AppColors.green,
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                              ),
                                            ),
                                            Text(
                                              '${widget.ticket.branchObject?.name}',
                                              style:
                                                  AppTextStyle.latoBold16(
                                                    context,
                                                  ).copyWith(
                                                    color: AppColors.green,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${widget.ticket.branchObject?.areaObject?.name}',
                                          style: AppTextStyle.latoRegular19(
                                            context,
                                          ),
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
                                              color:
                                                  '${currentTicket.status}' ==
                                                      'Awaiting'
                                                  ? const Color(0xffDFE699)
                                                  : '${currentTicket.status}' ==
                                                        'Completed'
                                                  ? const Color(0xff8FCFAD)
                                                  : const Color(0xffDBA0A0),
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                            ),
                                            child: Text(
                                              '${currentTicket.status}'.tr,
                                              style:
                                                  AppTextStyle.latoBold13(
                                                    context,
                                                  ).copyWith(
                                                    color: AppColors.white,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Text('${widget.ticket.comment}'.tr),
                                if (currentTicket.status == 'Awaiting')
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
                                                  ticketId: widget.ticket.id
                                                      .toString(),
                                                  newStatus: "Canceled",
                                                  repairDate: DateTime.now(),
                                                );
                                          },
                                          text: 'Cancel',
                                          borderColor: AppColors.green,
                                          topPadding: 15.0,
                                          textStyle: AppTextStyle.latoBold20(
                                            context,
                                          ),
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
                                                  ticketId: widget.ticket.id
                                                      .toString(),
                                                  newStatus: "Completed",
                                                  repairDate: DateTime.now(),
                                                );
                                          },
                                          foregroundcolor: AppColors.white,
                                          color: AppColors.green,
                                          toppadding: 15.0,
                                          textstyle: AppTextStyle.latoBold20(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Row(),
                              ],
                            );
                          }
                          return Column(
                            spacing: 10,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                spacing: 15,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(screenWidth * 0.03),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightGreen.withOpacity(
                                        0.25,
                                      ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        spacing: 5,
                                        children: [
                                          Text(
                                            "Ticket No.".tr,
                                            style: AppTextStyle.latoBold20(
                                              context,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            softWrap: false,
                                          ),
                                          Text(
                                            "${widget.ticket.orecalId}".tr,
                                            style: AppTextStyle.latoBold20(
                                              context,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            softWrap: false,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        spacing: 4,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,

                                        children: [
                                          Text(
                                            '${widget.ticket.branchObject?.branchId ?? '-'}',
                                            style: AppTextStyle.latoBold16(
                                              context,
                                            ).copyWith(color: AppColors.green),
                                          ),
                                          Container(
                                            width: screenWidth * 0.012,
                                            height: screenHeight * 0.006,
                                            decoration: BoxDecoration(
                                              color: AppColors.green,
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                            ),
                                          ),
                                          Text(
                                            widget.ticket.branchObject?.id.toString() ??
                                                '-',
                                            style: AppTextStyle.latoBold16(
                                              context,
                                            ).copyWith(color: AppColors.green),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        widget.ticket.branchObject?.areaObject?.name ?? '-',
                                        style: AppTextStyle.latoRegular19(
                                          context,
                                        ),
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
                                            color:
                                                '${widget.ticket.status}' ==
                                                    'Awaiting'
                                                ? const Color(0xffDFE699)
                                                : '${widget.ticket.status}' ==
                                                      'Completed'
                                                ? const Color(0xff8FCFAD)
                                                : const Color(0xffDBA0A0),
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                          ),
                                          child: Text(
                                            '${widget.ticket.status}'.tr,
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
                              Text('${widget.ticket.comment}'.tr),
                              if (widget.ticket.status == 'Awaiting')
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
                                                ticketId: widget.ticket.id
                                                    .toString(),
                                                newStatus: "Rejected",
                                                repairDate: DateTime.now(),
                                              );
                                        },
                                        text: 'Rejected',
                                        borderColor: AppColors.green,
                                        topPadding: 15.0,
                                        textStyle: AppTextStyle.latoBold20(
                                          context,
                                        ),
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
                                                ticketId: widget.ticket.id
                                                    .toString(),
                                                newStatus: "Completed",
                                                repairDate: DateTime.now(),
                                              );
                                        },
                                        foregroundcolor: AppColors.white,
                                        color: AppColors.green,
                                        toppadding: 15.0,
                                        textstyle: AppTextStyle.latoBold20(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Text(
                    "Tickets Details".tr,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  BlocBuilder<TicketsCubit, TicketsState>(
                    builder: (context, state) {
                      if (state is GetTicketsSuccess) {
                        final currentTicket = state.tickets.firstWhere(
                          (t) => t.id == widget.ticket.id,
                          orElse: () => widget.ticket,
                        );
                        return Card(
                          child: Container(
                            padding: EdgeInsets.all(20.0),
                            child: Row(
                              spacing: 15,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    spacing: 10,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Request Date'.tr,
                                            style: AppTextStyle.latoBold20(
                                              context,
                                            ).copyWith(color: AppColors.green),
                                          ),
                                          Text(
                                            currentTicket.requestDate != null
                                                ? getDateFromTimestamp(
                                                    currentTicket.requestDate,
                                                  )
                                                : '-',
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Repair Date:'.tr,
                                            style: AppTextStyle.latoBold20(
                                              context,
                                            ).copyWith(color: AppColors.green),
                                          ),
                                          Text(
                                            currentTicket.repairDate != null
                                                ? getDateFromTimestamp(
                                                    currentTicket.repairDate,
                                                  )
                                                : '-',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Request Date:'.tr,
                                            style: AppTextStyle.latoBold20(
                                              context,
                                            ).copyWith(color: AppColors.green),
                                          ),
                                          Text(
                                            currentTicket.requestDate != null
                                                ? getDateFromTimestamp(
                                                    currentTicket.requestDate,
                                                  )
                                                : '-',
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Response Date:'.tr,
                                            style: AppTextStyle.latoBold20(
                                              context,
                                            ).copyWith(color: AppColors.green),
                                          ),
                                          Text(
                                            currentTicket.responseDate != null
                                                ? getDateFromTimestamp(
                                                    currentTicket.responseDate,
                                                  )
                                                : '-',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Card(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Request Date'.tr,
                                          style: AppTextStyle.latoBold20(
                                            context,
                                          ).copyWith(color: AppColors.green),
                                        ),
                                        Text(
                                          widget.ticket.requestDate != null
                                              ? getDateFromTimestamp(
                                                  widget.ticket.requestDate,
                                                )
                                              : '-',
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Repair Date:'.tr,
                                          style: AppTextStyle.latoBold20(
                                            context,
                                          ).copyWith(color: AppColors.green),
                                        ),
                                        Text(
                                          widget.ticket.repairDate != null
                                              ? getDateFromTimestamp(
                                                  widget.ticket.repairDate,
                                                )
                                              : '-',
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Request Date:'.tr,
                                          style: AppTextStyle.latoBold20(
                                            context,
                                          ).copyWith(color: AppColors.green),
                                        ),
                                        Text(
                                          widget.ticket.requestDate != null
                                              ? getDateFromTimestamp(
                                                  widget.ticket.requestDate,
                                                )
                                              : '-',
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Response Date:'.tr,
                                          style: AppTextStyle.latoBold20(
                                            context,
                                          ).copyWith(color: AppColors.green),
                                        ),
                                        Text(
                                          widget.ticket.responseDate != null
                                              ? getDateFromTimestamp(
                                                  widget.ticket.responseDate,
                                                )
                                              : '-',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
                                    Text("${widget.ticket.priority}"),
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
                                    Text(widget.ticket.user?.name ?? '_'),
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
                                    Text(widget.ticket.user?.name ?? '_'),
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
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              spacing: 10,
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
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
                                                      damageComment,
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
                                                    context
                                                        .read<TicketsCubit>()
                                                        .updateTicketComment(
                                                          ticketId: widget
                                                              .ticket
                                                              .id
                                                              .toString(),
                                                          newComment:
                                                              damageComment
                                                                  .text,
                                                        );
                                                    Navigator.pop(context);
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
                          BlocBuilder<TicketsCubit, TicketsState>(
                            builder: (context, state) {
                              if (state is GetTicketsSuccess) {
                                final currentTicket = state.tickets.firstWhere(
                                  (t) => t.id == widget.ticket.id,
                                  orElse: () => widget.ticket,
                                );
                                return Text(
                                  currentTicket.damageDescription ??
                                      'No Damage',
                                );
                              }
                              return Text(
                                widget.ticket.damageDescription ?? 'No Damage',
                              );
                            },
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
                          Text(
                            'Attachment:'.tr,
                            style: AppTextStyle.latoBold20(
                              context,
                            ).copyWith(color: AppColors.green),
                          ),
                          Text(widget.ticket.attachment ?? 'No Attachment'),
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
                  return Center(child: Text(state.message));
                }
                if (state is GetAssetsTicketsLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.green),
                  );
                }
                if (state is GetAssetsTicketsSuccess) {
                  final data = state.assetsAndTickets;
                  return ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    spacing: 20,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(height: 3),
                                      Text(
                                        capitalizeEachWord('add Cost'),
                                        style: AppTextStyle.latoBold26(
                                          context,
                                        ).copyWith(color: AppColors.green),
                                      ),
                                      CustomInputWidget(
                                        inbutIcon: 'assets/images/id.svg',
                                        iconColor: AppColors.green,
                                        inbutHintText: 'Comment',
                                        changeToPass: false,
                                        textEditingController: comment,
                                      ),
                                      CustomDropdownWidget(
                                        inbutIcon: 'assets/images/repair.svg',
                                        iconColor: AppColors.green,
                                        inbutHintText: 'Repair Type',
                                        selectedValue: selectedValue,
                                        Data: Data,
                                        onChanged: (value) {
                                          selectedRepairValue.value = value!;
                                        },
                                      ),
                                      CustomInputWidget(
                                        inbutIcon:
                                            'assets/images/deductions.svg',
                                        iconColor: AppColors.green,
                                        inbutHintText: 'Amount',
                                        changeToPass: false,
                                        textEditingController: amount,
                                      ),
                                      SizedBox(
                                        width: screenWidth,
                                        child: CustomButtonWidget(
                                          screenWidth: screenWidth * 0.5,
                                          toppadding: 10,
                                          onpressed: () async {
                                            context
                                                .read<TicketsCubit>()
                                                .addAssetsRepair(
                                                  variation:
                                                      selectedRepairValue.value,
                                                  comment: comment.text,
                                                  assetsId: data[index].id,
                                                  ticketId: widget.ticket.id,
                                                  amount: num.parse(
                                                    amount.text,
                                                  ),
                                                );
                                            await context
                                                .read<AssetsRepairCubit>()
                                                .getAssetsRepairDetails(
                                                  ticketID: widget.ticket.id,
                                                );
                                          },
                                          text: 'Add',
                                          foregroundcolor: Theme.of(
                                            context,
                                          ).buttonTheme.colorScheme?.primary,
                                          color: Theme.of(
                                            context,
                                          ).buttonTheme.colorScheme?.secondary,
                                          textstyle: AppTextStyle.latoBold20(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Card(
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
                            child: Column(
                              children: [
                                Row(
                                  spacing: 15,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        screenWidth * 0.03,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.lightGreen.withOpacity(
                                          0.25,
                                        ),
                                        borderRadius: BorderRadius.circular(60),
                                      ),
                                      child: ClipRRect(
                                        child: SvgPicture.asset(
                                          'assets/images/${data[index].type}.svg',
                                          color: AppColors.green,
                                          width: screenWidth * 0.1,
                                          height: screenWidth * 0.1,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text("${data[index].type}".tr),
                                              Text('${data[index].barcode}'),
                                            ],
                                          ),
                                          Text(
                                            '${data[index].branchObject?.name}'
                                                .tr,
                                            style: AppTextStyle.latoRegular16(
                                              context,
                                            ).copyWith(color: AppColors.green),
                                          ),
                                          Text(
                                            '${data[index].branchObject?.area}'
                                                .tr,
                                            style: AppTextStyle.latoRegular16(
                                              context,
                                            ).copyWith(color: AppColors.gray),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      spacing: 5,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Total',
                                          style: AppTextStyle.latoBold26(
                                            context,
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: AppColors.green,
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                          ),
                                          child: BlocBuilder<TicketsCubit, TicketsState>(
                                            builder: (context, state) {
                                              if (state is GetTicketsSuccess) {
                                                final currentTicket = state
                                                    .tickets
                                                    .firstWhere(
                                                      (t) =>
                                                          t.id ==
                                                          widget.ticket.id,
                                                      orElse: () =>
                                                          widget.ticket,
                                                    );
                                                return Text(
                                                  '${currentTicket.amount ?? 0} EGP',
                                                  style:
                                                      AppTextStyle.latoBold16(
                                                        context,
                                                      ).copyWith(
                                                        color: AppColors.white,
                                                      ),
                                                );
                                              }
                                              return Text(
                                                '${widget.ticket.amount ?? 0} EGP',
                                                style:
                                                    AppTextStyle.latoBold16(
                                                      context,
                                                    ).copyWith(
                                                      color: AppColors.white,
                                                    ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),

                                // ***************** data assets repair here **************************//
                                SizedBox(
                                  width: Get.width,
                                  child: BlocBuilder<AssetsRepairCubit, AssetsRepairState>(
                                    buildWhen: (previous, current) =>
                                        current is GetAssetsRepairDataSuccess ||
                                        current is GetAssetsRepairDataLoading ||
                                        current is GetAssetsRepairDataFailed,
                                    builder: (context, state) {
                                      if (state is GetAssetsRepairDataLoading) {
                                        return CircularProgressIndicator();
                                      }
                                      if (state is GetAssetsRepairDataFailed) {
                                        return Text(state.errMsg);
                                      }
                                      if (state is GetAssetsRepairDataSuccess) {
                                        return ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: state.assetsRepair.length,
                                          itemBuilder: (context, index) {
                                            return Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  state
                                                          .assetsRepair[index]
                                                          .comment ??
                                                      '-',
                                                ),
                                                Row(
                                                  spacing: 5,
                                                  children: [
                                                    Text(
                                                      state
                                                          .assetsRepair[index]
                                                          .amount
                                                          .toString(),
                                                      style:
                                                          AppTextStyle.latoBold20(
                                                            context,
                                                          ).copyWith(
                                                            color:
                                                                AppColors.green,
                                                          ),
                                                    ),
                                                    Text(
                                                      'EGP',
                                                      style:
                                                          AppTextStyle.latoBold20(
                                                            context,
                                                          ).copyWith(
                                                            color:
                                                                AppColors.green,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                      return Text('No Spare parts');
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return Center(
                  child: Text(
                    'No Assets Added Yet',
                    style: AppTextStyle.latoBold23(
                      context,
                    ).copyWith(color: Colors.green),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
