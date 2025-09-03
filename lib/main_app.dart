import 'package:efs_misr/Features/Auth/presentation/pages/auth_page.dart';
import 'package:flutter/material.dart';

import 'core/utils/app_colors.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.AppBackground, body: AuthPage());
  }
}
