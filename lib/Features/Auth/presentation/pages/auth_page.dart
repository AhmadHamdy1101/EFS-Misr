import 'package:efs_misr/Features/Auth/presentation/viewmodel/auth_cubit.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/app_text_styles.dart';
import 'package:efs_misr/core/utils/widgets/custom_inbut_wedget.dart';
import 'package:efs_misr/core/utils/widgets/custom_signin_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController email = TextEditingController();

  final TextEditingController password = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: BlocBuilder<AuthCubit, AuthCubitState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.green,
                padding: EdgeInsets.all(10),
              ),
            );
          }
          return SingleChildScrollView(
            child: Container(
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/SignIn.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 90.0),
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Company Logo ==================
                      SvgPicture.asset(
                        'assets/images/logo.svg',
                        width: MediaQuery.sizeOf(context).width * 0.5,
                      ),
                      Text(
                        'Hello'.tr,
                        style: AppTextStyle.interSemiBold64(context),
                      ),
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.03,
                      ),

                      Text(
                        "Sign in to your account".tr,
                        style: AppTextStyle.latoRegular19(context),
                      ),
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.06,
                      ),
                      // Inbut Area ======================
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.8,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            spacing: 40,
                            children: [
                              CustomInputWidget(
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Please Enter Your Email'.tr;
                                  }
                                  if (!RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+',
                                  ).hasMatch(value)) {
                                    return "Email is not valid".tr;
                                  }
                                  return null;
                                },
                                inbutIcon: 'assets/images/profile.svg',
                                inbutHintText: 'Email'.tr,
                                changeToPass: false,
                                textEditingController: email,
                                textInputType: TextInputType.emailAddress,
                              ),
                              // Password Inbut
                              CustomInputWidget(
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Please Enter Your Password'.tr;
                                  }
                                  return null;
                                },
                                inbutIcon: 'assets/images/Password.svg',
                                inbutHintText: 'Password'.tr,
                                changeToPass: true,
                                textEditingController: password,
                                textInputType: TextInputType.visiblePassword,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height * 0.02,
                              ),

                              CustomLoginBtn(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthCubit>().login(
                                      email: email.text,
                                      password: password.text,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

