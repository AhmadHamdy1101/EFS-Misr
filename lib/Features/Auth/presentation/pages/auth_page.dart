

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/widgets/custom_inbut_wedget.dart';
import '../../../../core/utils/widgets/custom_signin_button.dart';
import '../../../Home/presentation/pages/home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController email = TextEditingController();

  final TextEditingController password = TextEditingController();

  @override
  Widget build(BuildContext context) {

        return Scaffold(
          backgroundColor: AppColors.AppBackground,
          resizeToAvoidBottomInset: false,
          body: SingleChildScrollView(
            child: Container(
              width: MediaQuery
                  .sizeOf(context)
                  .width,
              height: MediaQuery
                  .sizeOf(context)
                  .height,
              decoration: BoxDecoration(

                image: DecorationImage(
                    image: AssetImage("assets/images/SignIn.png"),
                    fit: BoxFit.cover),

              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 90.0),
                child: SizedBox(
                  width: MediaQuery
                      .sizeOf(context)
                      .width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      // Company Logo ==================
                      SvgPicture.asset(
                        'assets/images/logo.svg',
                        width: MediaQuery
                            .sizeOf(context)
                            .width * 0.5,
                      ),
                      Text('Hello',
                          style: AppTextStyle.interSemiBold64(context)),
                      SizedBox(height: MediaQuery
                          .sizeOf(context)
                          .height * 0.03),

                      Text(
                        "Sign in to your account",
                        style: AppTextStyle.latoRegular19(context),
                      ),
                      SizedBox(height: MediaQuery
                          .sizeOf(context)
                          .height * 0.06),
                      // Inbut Area ======================
                      SizedBox(
                        width: MediaQuery
                            .sizeOf(context)
                            .width * 0.8,
                        child: Column(
                          spacing: 40,
                          children: [
                            //   UserName Inbut
                            CustomInputWidget(
                              inbutIcon: 'assets/images/profile.svg',
                              inbutHintText: 'Username',
                              changeToPass: false,
                              textEditingController: email,
                              textInputType: TextInputType.emailAddress,
                            ),
                            // Password Inbut
                            CustomInputWidget(
                              inbutIcon: 'assets/images/Password.svg',
                              inbutHintText: 'Password',
                              changeToPass: true,
                              textEditingController: password,
                              textInputType: TextInputType.visiblePassword,
                            ),
                            SizedBox(
                              height: MediaQuery
                                  .sizeOf(context)
                                  .height * 0.02,
                            ),

                            //     sign In Button
                            CustomLoginBtn(
                              onPressed: () {
                               Get.to(HomePage());
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
      // listener: (BuildContext context, AuthCubitState state) {
      //   if (state is LoginSuccess) {
      //     Get.to(() =>
      //         HomePage());
      //         } else
      //         if (state is LoginFailure)
      //     {
      //       Get.snackbar(
      //         "Error",
      //         state.errorMsg,
      //         backgroundColor: Colors.red,
      //         colorText: AppColors.white,
      //       );
      //     }
      //   },
    // );
  // }
}


