import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:flutter/material.dart';
import '../widgets/menu_page_body.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key, required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: MenuPageBody(user: user));
  }
}
