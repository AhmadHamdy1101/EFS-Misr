import 'package:flutter/material.dart';

import '../../../../core/utils/app_colors.dart';
import '../../data/models/user.dart';
import '../widgets/menu_page_body.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key, required this.user});
  final  Users user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: MenuPageBody(user: user));
  }
}