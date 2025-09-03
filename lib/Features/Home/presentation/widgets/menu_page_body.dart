
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../constants/constants.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/custom_menu_button_widget.dart';
import '../../../../core/utils/widgets/custom_profile_wedget.dart';
import '../../../../core/utils/widgets/custome_back_shape_wedget.dart';
import '../../../../core/utils/widgets/custome_list_button.dart';
import '../../../../core/utils/widgets/custome_overview_widget.dart';
import '../pages/assets_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MenuPageBody extends StatefulWidget {
  const MenuPageBody({super.key});

  @override
  State<MenuPageBody> createState() => _MenuPageBodyState();
}

class _MenuPageBodyState extends State<MenuPageBody> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final List<Map<String, dynamic>> attendants = [
      {
        'name': 'Mohamed Said',
        'image': 'assets/images/profile.jpg',
        'position': 'operation',
        'status': 'Check In',
        'location': 'New Cairo,Egypt',
        'time': '8:00 AM',
      },
      {
        'name': 'Mohamed Said',
        'image': 'assets/images/profile.jpg',
        'position': 'operation',
        'status': 'Check Out',
        'location': 'New Cairo,Egypt',
        'time': '8:00 AM',
      },
    ];
    final List<Map<String, dynamic>> buttonsData = [
      {
        'title': 'Cash',
        'icon': 'assets/images/cash.svg',
        'color': Color(0xffDE5A5A),
        'onTap': () {},
      },
      {
        'title': 'Overtime',
        'icon': "assets/images/Overtime.svg",
        'color': Color(0xff20CF74),
        'onTap': () {
          Get.to(AssetsPage());
        },
      },
      {
        'title': 'Vacations',
        'icon': "assets/images/vecation.svg",
        'color': Color(0xffD0CD21),
        'onTap': () {},
      },
      {
        'title': 'Deductions',
        'icon': "assets/images/deductions.svg",
        'color': Color(0xff008C43),
        'onTap': () {},
      },
    ];

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
                    colors: [AppColors.green, AppColors.lightgreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),
              // شعار SVG على الخلفية
              CustomBackShapeWedget(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),

              // عناصر البروفايل فوق الخلفية
              Positioned(
                top: 60,
                child: Container(
                  width: screenWidth,
                  child: Column(
                    spacing: 20,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset(
                          'assets/images/profile.jpg',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Text(
                        "Mohamed Said",
                        style: AppTextStyle.latoBold26(
                          context,
                        ).copyWith(color: AppColors.white),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            "Operation",
                            style: AppTextStyle.latoRegular16(
                              context,
                            ).copyWith(color: AppColors.white),
                          ),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.white,
                            ),

                          ),
                          Text(
                            "124542",
                            style: AppTextStyle.latoRegular19(
                              context,
                            ).copyWith(color: AppColors.white),
                          ),

                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // الجزء اللي في نص Stack
            ],
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 15,
              children: [
                Text('General',style: AppTextStyle.latoBold16(context).copyWith(color: AppColors.gray),),
                Container(
                  padding: EdgeInsets.zero,
                  width: screenWidth,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    color: AppColors.white,
                    child: Column(
                      children: [
                        CustomMenuButtonWidget(title: 'Account Sitting', icon: Icons.account_circle,onPress: (){},),
                        CustomMenuButtonWidget(title: 'Language', icon:Icons.language,onPress: (){},),
                        CustomMenuButtonWidget(title: 'Dark mode', icon:Icons.dark_mode,onPress: (){},),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: screenWidth,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    color: AppColors.white,
                    child: Column(
                      children: [
                       CustomMenuButtonWidget(title: "Log Out", onPress: () async {await supabaseClient.auth.signOut();}, icon: Icons.exit_to_app)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


