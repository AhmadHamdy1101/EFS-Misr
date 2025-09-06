import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'Features/Auth/presentation/viewmodel/auth_cubit.dart';
import 'core/layout/adaptive_layout.dart';
import 'core/layout/desktop_layout.dart';
import 'core/layout/mobile_layout.dart';
import 'core/layout/tablet_layout.dart';
import 'core/utils/app_colors.dart';
import 'features/Auth/presentation/pages/auth_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().checkSession();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthCubitState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return Center(
            child: CircularProgressIndicator(backgroundColor: AppColors.green),
          );
        }
        if (state is SessionExist) {
          return AdaptiveLayout(
            mobileLayout: (context) => MobileLayout(user: state.user),
            tabletLayout: (context) => TabletLayout(),
            desktopLayout: (context) => DesktopLayout(),
          );
        }
        if (state is LoginSuccess) {
          return AdaptiveLayout(
            mobileLayout: (context) => MobileLayout(user: state.user),
            tabletLayout: (context) => TabletLayout(),
            desktopLayout: (context) => DesktopLayout(),
          );
        }
        return AuthPage();
      },
      listener: (BuildContext context, AuthCubitState state) {
        if (state is LoginFailure) {
          Get.snackbar(
            'Error'.tr,
            state.errorMsg,
            colorText: AppColors.white,
            backgroundColor: Colors.red,
            snackPosition: SnackPosition.BOTTOM,
            snackStyle: SnackStyle.FLOATING,
            isDismissible: true,
          );
        }
      },
    );
  }
}
