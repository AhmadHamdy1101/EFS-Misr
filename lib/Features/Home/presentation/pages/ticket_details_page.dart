import 'package:flutter/material.dart';

import '../widgets/ticket_details_page_body.dart';

class TicketDetailsPage extends StatelessWidget {
  const TicketDetailsPage({super.key, this.TicketId});
final TicketId;
  @override
  Widget build(BuildContext context) {
    print(TicketId);
    return TicketDetailsPageBody();
  }
}