import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:flutter/material.dart';

import '../../Features/Home/presentation/pages/home_page.dart';

class MobileLayout extends StatelessWidget {
  const MobileLayout({super.key, required this.user});

  final Users user;
  @override
  Widget build(BuildContext context) {
    return Column(children: [Expanded(child: HomePage(user: user,))]);
  }
}
