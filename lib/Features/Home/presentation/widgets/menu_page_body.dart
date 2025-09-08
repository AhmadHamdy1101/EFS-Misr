
import 'package:efs_misr/Features/Home/data/models/user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../constants/constants.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/custom_menu_button_widget.dart';
import '../../../../core/utils/widgets/custome_back_shape_wedget.dart';

class MenuPageBody extends StatefulWidget {
  const MenuPageBody({super.key, required this.user});

  final Users user;

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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset(
                          'assets/images/user.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
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
                        CustomMenuButtonWidget(title: 'Language'.tr, icon:Icons.language,children: [
                          ListTile(title: Text("English",style: AppTextStyle.latoBold23(context),), onTap: () { Get.updateLocale(Locale('en'));}),
                          ListTile(title: Text("العربية",style: AppTextStyle.latoBold23(context),), onTap: () { Get.updateLocale(Locale('ar'));}),
                        ],),
                        CustomMenuButtonWidget(title: 'Dark mode'.tr, icon:Icons.dark_mode,children: [
                          ListTile(title: Text('Light'.tr,style: AppTextStyle.latoBold23(context),), onTap: () {},),
                          ListTile(title: Text('Dark'.tr,style: AppTextStyle.latoBold23(context),), onTap: () {},)
                        ],),
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
                    color: AppColors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 0),
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            Colors.transparent,
                          ),
                          foregroundColor: WidgetStatePropertyAll(
                            AppColors.black,
                          ),
                          elevation: WidgetStatePropertyAll(0),
                        ),
                        onPressed: () async {await supabaseClient.auth.signOut();},
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              spacing: 10,
                              children: [
                                Icon(Icons.exit_to_app,size: 25,),
                                Text(
                                  "Log Out",
                                  style: AppTextStyle.latoBold23(context),
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
