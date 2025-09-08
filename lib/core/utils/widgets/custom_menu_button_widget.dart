import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';

class CustomMenuButtonWidget extends StatelessWidget {
  const CustomMenuButtonWidget({
    super.key, required this.title, required this.icon, required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Icon(icon),
      title: Text(title, style: AppTextStyle.latoBold23(context),),
      children: children,
      iconColor:  AppColors.black,
      shape: RoundedRectangleBorder(side: BorderSide.none),
    );
  }
}

//
// ElevatedButton(
// style: ButtonStyle(
// backgroundColor: WidgetStatePropertyAll(
// Colors.transparent,
// ),
// foregroundColor: WidgetStatePropertyAll(
// AppColors.black,
// ),
// elevation: WidgetStatePropertyAll(0),
// ),
// onPressed: onPress,
// child: Row(
// crossAxisAlignment: CrossAxisAlignment.center,
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// Row(
// spacing: 10,
// children: [
// Icon(icon),
// Text(
// title,
// style: AppTextStyle.latoBold16(context),
// ),
// ],
// ),
// Icon(Icons.arrow_right_rounded),
// ],
// ),
// );