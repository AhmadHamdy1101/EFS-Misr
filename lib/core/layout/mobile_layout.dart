import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:flutter/material.dart';

import '../../Features/Home/presentation/pages/home_page.dart';

class MobileLayout extends StatelessWidget {
  const MobileLayout({super.key, required this.user, this.homeKey});

  final UserEntity user;

  /// Shared across layouts so the home state (selected tab, scroll) survives
  /// a breakpoint change such as rotating the device.
  final Key? homeKey;

  @override
  Widget build(BuildContext context) => HomePage(key: homeKey, user: user);
}
