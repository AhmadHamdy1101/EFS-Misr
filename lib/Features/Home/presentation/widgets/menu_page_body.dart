import 'dart:io';

import 'package:efs_misr/Features/Auth/presentation/viewmodel/auth_cubit.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:efs_misr/core/utils/singelton.dart';
import 'package:efs_misr/core/utils/theme_service.dart';
import 'package:efs_misr/core/utils/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/custom_menu_button_widget.dart';
import '../../../../core/utils/widgets/custome_back_shape_wedget.dart';
import '../viewmodel/image_cubit.dart';
import '../../../Notifications/presentation/controller/notifications_cubit.dart';

class MenuPageBody extends StatelessWidget {
  const MenuPageBody({super.key, required this.user});

  final UserEntity user;

  Future<void> _pickImage(BuildContext context) async {
    final imageCubit = context.read<ImageCubit>();
    // Resize on pick: a profile photo never needs more than 512px, and a
    // smaller file uploads much faster.
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    await imageCubit.uploadProfileImage(user: user, file: File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final themeService = getIt.get<ThemeService>();
    return BlocListener<ImageCubit, ImageState>(
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state is ImageUpdateSuccess) {
          context.read<AuthCubit>().updateCurrentUser(state.user);
        } else if (state is ImageUpdateFailed) {
          showAppSnackBar(messenger, state.errMsg, isError: true);
        }
      },
      child: CustomScrollView(
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
                          onTap: () => _pickImage(context),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: user.image.isNotEmpty
                                    ? NetworkImage(user.image)
                                    : const AssetImage('assets/images/user.png')
                                          as ImageProvider,
                                child: BlocBuilder<ImageCubit, ImageState>(
                                  builder: (context, state) =>
                                      state is ImageUpdateLoading
                                      ? const CircularProgressIndicator(
                                          color: AppColors.white,
                                        )
                                      : const SizedBox.shrink(),
                                ),
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
                          user.name,
                          style: AppTextStyle.latoBold26(
                            context,
                          ).copyWith(color: AppColors.white),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              user.position?.name ?? '',
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
                              "${user.id}",
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
                                  themeService.switchLocale(const Locale('en'));
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
                                  themeService.switchLocale(const Locale('ar'));
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
                                  themeService.switchTheme(ThemeMode.light),
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
                                  themeService.switchTheme(ThemeMode.dark),
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
                            final auth = context.read<AuthCubit>();
                            // While still signed in: stop this phone getting
                            // the old account's pushes.
                            await context
                                .read<NotificationsCubit>()
                                .unregisterDevice();
                            await auth.logout();
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
      ),
    );
  }
}
