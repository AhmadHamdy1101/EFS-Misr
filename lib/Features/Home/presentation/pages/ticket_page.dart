import 'package:flutter/material.dart';

import '../widgets/ticket_page_body.dart';

class TicketPage extends StatelessWidget {
  const TicketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: TicketPageBody());
  }
}