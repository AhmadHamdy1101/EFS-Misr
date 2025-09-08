import 'package:flutter/material.dart';

import '../../../../core/utils/app_colors.dart';
import '../widgets/menu_page_body.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
        body: MenuPageBody());
  }
}