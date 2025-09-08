import 'package:efs_misr/auth_gate.dart';
import 'package:flutter/material.dart';
import 'core/utils/app_colors.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.appBackground, body: AuthGate());
  }
}
