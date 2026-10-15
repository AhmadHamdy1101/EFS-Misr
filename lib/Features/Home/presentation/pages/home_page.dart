import 'package:efs_misr/Features/Home/presentation/widgets/qr_view.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/widgets/custom_navigation_bar.dart';
import '../../../Tickets/presentation/screens/ticket_page.dart';
import '../widgets/home_page_body.dart';
import '../../../Accounts/presentation/screens/acounts_page.dart';
import '../../../Assets_data/presentation/screens/assets_page.dart';
import 'menu_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user});

  final UserEntity user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  bool get _isAdmin => widget.user.role == 'Admin';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final tabs = <(String, Widget)>[
      ("assets/images/home.svg", HomePageBody(user: widget.user)),
      ("assets/images/assets.svg", const AssetsPage()),
      ("assets/images/ticket.svg", const TicketPage()),
      if (_isAdmin) ("assets/images/profile.svg", const AccountsPage()),
      ("assets/images/menu.svg", MenuPage(user: widget.user)),
    ];
    final index = selectedIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        elevation: 5,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => Get.to(() => const QRScanPage()),
        child: SvgPicture.asset(
          'assets/images/Qr code scanner.svg',
          width: screenWidth * 0.07,
        ),
      ),
      // IndexedStack keeps every tab alive, so switching tabs doesn't refetch
      // data or lose search text and scroll position.
      body: IndexedStack(
        index: index,
        children: [for (final tab in tabs) tab.$2],
      ),
      bottomNavigationBar: CustomBottomNav(
        icons: [for (final tab in tabs) tab.$1],
        selectedIndex: index,
        onPressed: (i) => setState(() => selectedIndex = i),
      ),
    );
  }
}
