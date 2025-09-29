import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/presentation/widgets/edit_accounts_page_body.dart';
import 'package:flutter/material.dart';

class EditAccountPage extends StatelessWidget {
  const EditAccountPage({super.key, required this.user});
  final Users user ;

  @override
  Widget build(BuildContext context) {
    return EditAccountPageBody(user: user);
  }
}