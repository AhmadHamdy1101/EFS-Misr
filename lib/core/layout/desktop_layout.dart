import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:flutter/material.dart';

import 'mobile_layout.dart';

/// Uses the mobile layout until a dedicated desktop design exists.
class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key, required this.user, this.homeKey});

  final UserEntity user;
  final Key? homeKey;

  @override
  Widget build(BuildContext context) =>
      MobileLayout(user: user, homeKey: homeKey);
}
