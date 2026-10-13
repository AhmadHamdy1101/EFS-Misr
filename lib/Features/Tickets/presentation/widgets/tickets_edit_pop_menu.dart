import 'package:efs_misr/Features/Tickets/domain/entities/ticket_entity.dart';
import 'package:efs_misr/Features/Tickets/presentation/controller/tickets_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_text_styles.dart';
import 'ticket_overview_widget.dart';

class TicketsEditPopMenu extends StatelessWidget {
  const TicketsEditPopMenu({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.tickets,
  });

  final double screenWidth;
  final double screenHeight;
  final TicketEntity tickets;

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ticket?'.tr),
        content: Text('This action cannot be undone.'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete'.tr),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await context.read<TicketsCubit>().deleteTicket(
      ticketId: tickets.id,
    );
    if (!context.mounted) return;
    result.fold(
      (failure) => messenger.showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) => messenger.showSnackBar(
        SnackBar(content: Text('Ticket deleted'.tr)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onSelected: (value) {
                  if (value == 'delete') _confirmDelete(context);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete'.tr,
                      style: AppTextStyle.latoBold20(context),
                    ),
                  ),
                ],
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              TicketOverViewWidget(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                ticketData: tickets,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
