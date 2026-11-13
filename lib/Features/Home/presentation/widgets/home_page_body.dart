import 'package:efs_misr/Features/Home/presentation/widgets/all_tickets_list_view.dart';
import 'package:efs_misr/Features/Home/presentation/widgets/tickets_over_view_widget.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:efs_misr/Features/Notifications/presentation/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/widgets/custom_profile_wedget.dart';
import '../../../../core/utils/widgets/custome_back_shape_wedget.dart';

class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key, required this.user});

  final UserEntity user;

  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: screenHeight * 0.3,
                width: screenWidth,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.green, AppColors.lightGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),
              CustomBackShapeWedget(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
              CustomProfileWidget(
                screenWidth: screenWidth,
                image: (widget.user.image.isNotEmpty)
                    ? Image.network(
                        widget.user.image,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'assets/images/user.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                name: widget.user.name,
                position: widget.user.position?.name ?? '',
                trailing: NotificationBell(
                  icon: SvgPicture.asset("assets/images/Notifecation.svg"),
                ),
              ),
              TicketsOverViewWidget(
                screenHeight: screenHeight,
                screenWidth: screenWidth,
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: screenHeight >= 600 ? 150 : 15),
        ),
        SliverToBoxAdapter(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tickets Overview".tr,
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  AllTicketsListView(
                    screenHeight: screenHeight,
                    screenWidth: screenWidth,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
