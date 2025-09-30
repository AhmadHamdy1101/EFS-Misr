import 'package:efs_misr/Features/Home/presentation/pages/SplashScreen.dart';
import 'package:efs_misr/auth_gate.dart';
import 'package:flutter/material.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( body: AuthGate());
  }
}
