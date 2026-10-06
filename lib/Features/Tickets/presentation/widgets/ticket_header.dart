import 'package:efs_misr/constants/screens_size.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/widgets/custom_button_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_outline_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/models/tickets.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../controller/tickets_cubit.dart';

class TicketHeader extends StatelessWidget {
  const TicketHeader({super.key, required this.ticket});

  final Tickets ticket;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(20.0),
        child: BlocBuilder<TicketsCubit, TicketsState>(
          builder: (context, state) {
            if (state is GetTicketsSuccess) {
              final currentTicket = state.tickets.firstWhere(
                (t) => t.id == ticket.id,
                orElse: () => ticket,
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
                          ScreensSize(context).screenWidth * 0.03,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: ClipRRect(
                          child: SvgPicture.asset(
                            'assets/images/ticket.svg',
                            color: AppColors.green,
                            width: ScreensSize(context).screenWidth * 0.1,
                            height: ScreensSize(context).screenWidth * 0.1,
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
                                width: ScreensSize(context).screenWidth * 0.012,
                                height:
                                    ScreensSize(context).screenHeight * 0.006,
                                decoration: BoxDecoration(
                                  color: AppColors.green,
                                  borderRadius: BorderRadius.circular(50),
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
                              style: AppTextStyle.latoRegular16(context),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical:
                                    ScreensSize(context).screenHeight * 0.01,
                                horizontal:
                                    ScreensSize(context).screenWidth * 0.04,
                              ),
                              decoration: BoxDecoration(
                                color: '${currentTicket.status}' == 'Awaiting'
                                    ? const Color(0xffDFE699)
                                    : '${currentTicket.status}' == 'Completed'
                                    ? const Color(0xff8FCFAD)
                                    : const Color(0xffDBA0A0),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                '${currentTicket.status}'.tr,
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
                  if (currentTicket.status == 'Awaiting')
                    Row(
                      spacing: 10,
                      children: [
                        Expanded(
                          child: CustomOutlineButtonWidget(
                            screenWidth: ScreensSize(context).screenWidth,
                            color: Colors.transparent,
                            foregroundColor: AppColors.green,
                            onPressed: () {
                              context.read<TicketsCubit>().updateTicketStatus(
                                ticketId: ticket.id.toString(),
                                newStatus: "Canceled",
                                repairDate: DateTime.now(),
                              );
                            },
                            text: 'Cancel',
                            borderColor: AppColors.green,
                            topPadding: 15.0,
                            textStyle: AppTextStyle.latoBold20(context),
                          ),
                        ),
                        Expanded(
                          child: CustomButtonWidget(
                            screenWidth: ScreensSize(context).screenWidth,
                            text: 'Complete',
                            onpressed: () {
                              context.read<TicketsCubit>().updateTicketStatus(
                                ticketId: ticket.id.toString(),
                                newStatus: "Completed",
                                repairDate: DateTime.now(),
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
                      padding: EdgeInsets.all(
                        ScreensSize(context).screenWidth * 0.03,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: ClipRRect(
                        child: SvgPicture.asset(
                          'assets/images/ticket.svg',
                          color: AppColors.green,
                          width: ScreensSize(context).screenWidth * 0.1,
                          height: ScreensSize(context).screenWidth * 0.1,
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,

                          children: [
                            Text(
                              '${ticket.branchObject?.branchId ?? '-'}',
                              style: AppTextStyle.latoBold16(
                                context,
                              ).copyWith(color: AppColors.green),
                            ),
                            Container(
                              width: ScreensSize(context).screenWidth * 0.012,
                              height: ScreensSize(context).screenHeight * 0.006,
                              decoration: BoxDecoration(
                                color: AppColors.green,
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            Text(
                              ticket.branchObject?.id.toString() ?? '-',
                              style: AppTextStyle.latoBold16(
                                context,
                              ).copyWith(color: AppColors.green),
                            ),
                          ],
                        ),
                        Text(
                          ticket.branchObject?.areaObject?.name ?? '-',
                          style: AppTextStyle.latoRegular19(context),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "Status".tr,
                            style: AppTextStyle.latoRegular16(context),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical:
                                  ScreensSize(context).screenHeight * 0.01,
                              horizontal:
                                  ScreensSize(context).screenWidth * 0.04,
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
                          screenWidth: ScreensSize(context).screenWidth,
                          color: Colors.transparent,
                          foregroundColor: AppColors.green,
                          onPressed: () {
                            context.read<TicketsCubit>().updateTicketStatus(
                              ticketId: ticket.id.toString(),
                              newStatus: "Rejected",
                              repairDate: DateTime.now(),
                            );
                          },
                          text: 'Rejected',
                          borderColor: AppColors.green,
                          topPadding: 15.0,
                          textStyle: AppTextStyle.latoBold20(context),
                        ),
                      ),
                      Expanded(
                        child: CustomButtonWidget(
                          screenWidth: ScreensSize(context).screenWidth,
                          text: 'Complete',
                          onpressed: () {
                            context.read<TicketsCubit>().updateTicketStatus(
                              ticketId: ticket.id.toString(),
                              newStatus: "Completed",
                              repairDate: DateTime.now(),
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
            );
          },
        ),
      ),
    );
  }
}
