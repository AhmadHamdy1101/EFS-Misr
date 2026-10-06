import 'package:efs_misr/Features/Tickets/presentation/widgets/ticket_attachment.dart';
import 'package:efs_misr/Features/Tickets/presentation/widgets/ticket_damage_comment.dart';
import 'package:efs_misr/Features/Tickets/presentation/widgets/ticket_dates.dart';
import 'package:efs_misr/Features/Tickets/presentation/widgets/ticket_header.dart';
import 'package:efs_misr/Features/Tickets/presentation/widgets/ticket_priority.dart';
import 'package:efs_misr/constants/screens_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/models/tickets.dart';

class TicketDetailsContainer extends StatelessWidget {
  const TicketDetailsContainer({
    super.key,
    required this.ticket,
    required this.damageComment,
  });

  final Tickets ticket;
  final TextEditingController damageComment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 20,
        horizontal: ScreensSize(context).screenWidth * 0.03,
      ),
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TicketHeader(ticket: ticket),
          Text(
            "Tickets Details".tr,
            style: TextStyle(
              fontSize: ScreensSize(context).screenWidth * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
          TicketDates(ticket: ticket),
          TicketPriority(ticket: ticket),
          TicketDamageComment(damageComment: damageComment, ticket: ticket),
          TicketAttachment(ticket: ticket),
          Text(
            "Assets".tr,
            style: TextStyle(
              fontSize: ScreensSize(context).screenWidth * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
