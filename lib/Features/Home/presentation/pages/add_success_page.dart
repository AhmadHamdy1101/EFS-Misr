import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/presentation/widgets/add_success_page_body.dart';
import 'package:flutter/material.dart';

import '../widgets/ticket_details_page_body.dart';

class AddSuccessPage extends StatelessWidget {
  const AddSuccessPage({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return AddSuccessPageBody(message: message);
  }
}