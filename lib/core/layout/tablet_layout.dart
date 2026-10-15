import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:flutter/material.dart';

import 'mobile_layout.dart';

/// Uses the mobile layout until a dedicated tablet design exists, so wide
/// screens (and phones turned sideways) never show a blank page.
class TabletLayout extends StatelessWidget {
  const TabletLayout({super.key, required this.user, this.homeKey});

  final UserEntity user;
  final Key? homeKey;

  @override
  Widget build(BuildContext context) =>
      MobileLayout(user: user, homeKey: homeKey);
}
