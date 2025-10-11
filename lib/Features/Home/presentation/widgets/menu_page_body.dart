import 'package:efs_misr/Features/Home/data/models/user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/constants.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/theme_service.dart';
import '../../../../core/utils/widgets/custom_menu_button_widget.dart';
import '../../../../core/utils/widgets/custome_back_shape_wedget.dart';

class MenuPageBody extends StatefulWidget {
  const MenuPageBody({super.key, required this.user});

  final Users user;

  @override
  State<MenuPageBody> createState() => _MenuPageBodyState();
}

class _MenuPageBodyState extends State<MenuPageBody> {
  String? _userImage;
  @override
  void initState() {
    super.initState();
    _userImage = widget.user.image;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    print(widget.user.image.toString());

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
              // شعار SVG على الخلفية
              CustomBackShapeWedget(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),

              // عناصر البروفايل فوق الخلفية
              Positioned(
                top: screenHeight * 0.06,
                child: SizedBox(
                  width: screenWidth,
                  child: Column(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          // final newImageUrl = await uploadUserImage(context, widget.user.id);
                          // if (newImageUrl != null) {
                          //   setState(() {
                          //     _userImage = newImageUrl; // يحدث الصورة فورًا
                          //   });
                          // }
                        },
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage:
                                  (_userImage != null && _userImage!.isNotEmpty)
                                  ? NetworkImage(_userImage!)
                                  : const AssetImage('assets/images/user.png')
                                        as ImageProvider,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: AppColors.green,
                                child: Icon(
                                  Icons.camera_alt,
                                  color: AppColors.white,
                                  size: 18.0,
                                  semanticLabel:
                                      'Text to announce in accessibility modes',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        "${widget.user.name}",
                        style: AppTextStyle.latoBold26(
                          context,
                        ).copyWith(color: AppColors.white),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            "${widget.user.position?.name}",
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
                            "${widget.user.id}",
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
                Text(
                  'General',
                  style: AppTextStyle.latoBold26(
                    context,
                  ).copyWith(color: AppColors.gray),
                ),
                Container(
                  padding: EdgeInsets.zero,
                  width: screenWidth,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Column(
                      children: [
                        CustomMenuButtonWidget(
                          title: 'Language'.tr,
                          icon: Icons.language,
                          children: [
                            ListTile(
                              title: Text(
                                "English",
                                style: AppTextStyle.latoBold23(context)
                                    .copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                              onTap: () {
                                Get.updateLocale(Locale('en'));
                              },
                            ),
                            ListTile(
                              title: Text(
                                "العربية",
                                style: AppTextStyle.latoBold23(context)
                                    .copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                              onTap: () {
                                Get.updateLocale(Locale('ar'));
                              },
                            ),
                          ],
                        ),
                        CustomMenuButtonWidget(
                          title: 'Dark mode'.tr,
                          icon: Icons.dark_mode,
                          children: [
                            ListTile(
                              title: Text(
                                'Light'.tr,
                                style: AppTextStyle.latoBold23(context)
                                    .copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                              onTap: () => {
                                ThemeService().switchTheme(ThemeMode.light),
                              },
                            ),
                            ListTile(
                              title: Text(
                                'Dark'.tr,
                                style: AppTextStyle.latoBold23(context)
                                    .copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                              onTap: () => {
                                ThemeService().switchTheme(ThemeMode.dark),
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(
                  width: screenWidth,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 0,
                      ),
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            Colors.transparent,
                          ),
                          foregroundColor: WidgetStatePropertyAll(
                            Theme.of(context).colorScheme.primary,
                          ),
                          elevation: WidgetStatePropertyAll(0),
                        ),
                        onPressed: () async {
                          await supabaseClient.auth.signOut();
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              spacing: 10,
                              children: [
                                Icon(Icons.exit_to_app, size: 25),
                                Text(
                                  "Log Out",
                                  style: AppTextStyle.latoBold23(context)
                                      .copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
