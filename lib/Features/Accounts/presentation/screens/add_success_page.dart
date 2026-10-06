import 'package:efs_misr/Features/Accounts/presentation/widgets/add_success_page_body.dart';
import 'package:flutter/material.dart';


class AddSuccessPage extends StatelessWidget {
  const AddSuccessPage({super.key, required this.message, required this.buttonTitle, required this.onPress, required this.secondPress});
  final String message;
  final String buttonTitle;
  final VoidCallback onPress;
  final VoidCallback secondPress;

  @override
  Widget build(BuildContext context) {
    return AddSuccessPageBody(message: message,buttonTitle: buttonTitle,onPress: onPress,secondPress: secondPress,);
  }
}