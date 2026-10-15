import 'package:efs_misr/Features/Tickets/domain/entities/ticket_entity.dart';
import 'package:efs_misr/Features/Tickets/presentation/controller/tickets_cubit.dart';
import 'package:efs_misr/constants/screens_size.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_text_styles.dart';
import 'ticket_status_actions.dart';
import 'ticket_status_badge.dart';

class TicketHeader extends StatelessWidget {
  const TicketHeader({super.key, required this.ticket});

  final TicketEntity ticket;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketsCubit, TicketsState>(
      builder: (context, state) {
        final currentTicket = state is GetTicketsSuccess
            ? state.findTicket(ticket.id) ?? ticket
            : ticket;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TicketIcon(size: ScreensSize(context).screenWidth * 0.1),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${'Ticket No.'.tr} ${currentTicket.oricalID ?? '-'}',
                            style: AppTextStyle.latoBold20(context),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currentTicket.branchEntity?.branchId ?? '-'}  •  ${currentTicket.branchEntity?.name ?? '-'}',
                            style: AppTextStyle.latoBold16(
                              context,
                            ).copyWith(color: AppColors.green),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            currentTicket.branchEntity?.areaName ?? '-',
                            style: AppTextStyle.latoRegular19(context),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        Text('Status'.tr),
                        const SizedBox(height: 4),
                        TicketStatusBadge(status: currentTicket.status),
                      ],
                    ),
                  ],
                ),
                if (currentTicket.comment.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(currentTicket.comment.tr),
                ],
                const SizedBox(height: 12),
                TicketStatusActions(ticket: currentTicket),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TicketIcon extends StatelessWidget {
  const _TicketIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.3),
      decoration: BoxDecoration(
        color: AppColors.lightGreen.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(60),
      ),
      child: SvgPicture.asset(
        'assets/images/ticket.svg',
        colorFilter: const ColorFilter.mode(AppColors.green, BlendMode.srcIn),
        width: size,
        height: size,
      ),
    );
  }
}
