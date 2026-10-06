import 'package:efs_misr/Features/Tickets/presentation/widgets/current_ticket_dates.dart';
import 'package:efs_misr/constants/screens_size.dart';
import 'package:efs_misr/core/Functions/GetDate_Function.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/models/tickets.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../controller/tickets_cubit.dart';

class TicketDates extends StatelessWidget {
  const TicketDates({super.key, required this.ticket});

  final Tickets ticket;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketsCubit, TicketsState>(
      builder: (context, state) {
        if (state is GetTicketsSuccess) {
          final currentTicket = state.tickets.firstWhere(
            (t) => t.id == ticket.id,
            orElse: () => ticket,
          );
          return CurrentTicketDates(currentTicket: currentTicket);
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request Date'.tr,
                            style: AppTextStyle.latoBold20(
                              context,
                            ).copyWith(color: AppColors.green),
                          ),
                          Text(
                            ticket.requestDate != null
                                ? getDateFromTimestamp(ticket.requestDate)
                                : '-',
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
                            ticket.repairDate != null
                                ? getDateFromTimestamp(ticket.repairDate)
                                : '-',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: ScreensSize(context).screenHeight * 0.13,
                  width: 1,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
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
                            ticket.requestDate != null
                                ? getDateFromTimestamp(ticket.requestDate)
                                : '-',
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
                            ticket.responseDate != null
                                ? getDateFromTimestamp(ticket.responseDate)
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
    );
  }
}
