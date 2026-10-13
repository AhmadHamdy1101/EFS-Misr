import 'package:efs_misr/Features/Tickets/domain/entities/ticket_entity.dart';
import 'package:efs_misr/Features/Tickets/presentation/controller/tickets_cubit.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/widgets/custom_button_widget.dart';
import 'package:efs_misr/core/utils/widgets/custom_outline_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_text_styles.dart';

class TicketStatusActions extends StatefulWidget {
  const TicketStatusActions({super.key, required this.ticket});

  final TicketEntity ticket;

  @override
  State<TicketStatusActions> createState() => _TicketStatusActionsState();
}

class _TicketStatusActionsState extends State<TicketStatusActions> {
  bool _isUpdating = false;

  Future<void> _updateStatus(TicketStatus status) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    final result = await context.read<TicketsCubit>().updateTicketStatus(
      ticketId: widget.ticket.id,
      status: status,
    );
    if (!mounted) return;
    setState(() => _isUpdating = false);
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket status updated'.tr)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ticket.status != TicketStatus.awaiting) {
      return const SizedBox.shrink();
    }

    final width = MediaQuery.sizeOf(context).width;
    return Row(
      children: [
        Expanded(
          child: CustomOutlineButtonWidget(
            screenWidth: width,
            color: Colors.transparent,
            foregroundColor: AppColors.green,
            onPressed: _isUpdating
                ? null
                : () => _updateStatus(TicketStatus.canceled),
            text: 'Cancel'.tr,
            borderColor: AppColors.green,
            topPadding: 15,
            textStyle: AppTextStyle.latoBold20(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomButtonWidget(
            screenWidth: width,
            text: 'Complete'.tr,
            onpressed: _isUpdating
                ? null
                : () => _updateStatus(TicketStatus.completed),
            foregroundcolor: AppColors.white,
            color: AppColors.green,
            toppadding: 15,
            textstyle: AppTextStyle.latoBold20(context),
          ),
        ),
      ],
    );
  }
}
