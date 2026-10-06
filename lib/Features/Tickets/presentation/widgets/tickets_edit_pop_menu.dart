import 'package:efs_misr/core/models/supadart_exports.dart';
import 'package:flutter/material.dart';


import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/ticket_overview_widget.dart';


class TicketsEditPopMenu extends StatelessWidget {
  const TicketsEditPopMenu({
    super.key,
    required this.screenWidth,
    required this.screenHeight, required this.tickets,
  });

  final double screenWidth;
  final double screenHeight;
  final Tickets tickets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PopupMenuButton(
                icon: Icon(
                  Icons.more_horiz,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    // Handle edit action
                  } else if (value == 'delete') {
                    // Handle delete action
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        'Edit',
                        style: AppTextStyle.latoBold20(context).copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: AppTextStyle.latoBold20(context).copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ];
                },
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
