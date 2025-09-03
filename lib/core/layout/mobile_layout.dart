import 'package:flutter/material.dart';

import '../../Features/Home/presentation/pages/home_page.dart';

class MobileLayout extends StatelessWidget {
  const MobileLayout({super.key, required this.userID});

  final String userID;
  @override
  Widget build(BuildContext context) {
    return Column(children: [Expanded(child: HomePage())]);
  }
}
