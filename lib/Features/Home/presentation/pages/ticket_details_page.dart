import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:flutter/material.dart';

import '../widgets/ticket_details_page_body.dart';

class TicketDetailsPage extends StatelessWidget {
  const TicketDetailsPage({super.key, required this.tickets});
final Tickets tickets;
  @override
  Widget build(BuildContext context) {
    return TicketDetailsPageBody(ticket: tickets,);
  }
}