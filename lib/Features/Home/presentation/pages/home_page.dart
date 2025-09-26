import 'package:efs_misr/Features/Home/presentation/pages/ticket_page.dart';
import 'package:efs_misr/Features/Home/presentation/widgets/QRView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/widgets/custom_navigation_bar.dart';
import '../../data/models/user.dart';
import '../widgets/home_page_body.dart';
import 'acounts_page.dart';
import 'assets_page.dart';
import 'menu_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user});

  final Users user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconPaths = [
      "assets/images/home.svg",
      "assets/images/assets.svg",
      "assets/images/ticket.svg",
      "assets/images/profile.svg",
      "assets/images/menu.svg",
    ];
    final iconPathsUser = [
      "assets/images/home.svg",
      "assets/images/assets.svg",
      "assets/images/ticket.svg",
      "assets/images/menu.svg",
    ];

    final pages = [
      HomePageBody(user: widget.user),
      AssetsPage(),
      TicketPage(),
      AccontsPage(),
      MenuPage(user: widget.user),
    ];
    final pagesuser = [
      HomePageBody(user: widget.user),
      AssetsPage(),
      TicketPage(),
      MenuPage(user: widget.user),
    ];
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        elevation: 5,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () {
          Get.to(QRScanPage());
        },
        child: SvgPicture.asset(
          'assets/images/Qr code scanner.svg',
          width: screenWidth * 0.07,
        ),
      ),
      body: widget.user.role == 'Admin'? pages[selectedIndex]:pagesuser[selectedIndex],
      bottomNavigationBar: CustomBottomNav(
        icons: widget.user.role == 'Admin'? iconPaths:iconPathsUser,
        selectedIndex: selectedIndex,
        onPressed: _onItemTapped,
      ),
    );
  }
}
