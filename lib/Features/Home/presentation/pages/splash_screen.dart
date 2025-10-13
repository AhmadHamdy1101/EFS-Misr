import 'dart:async';

import 'package:efs_misr/Features/Home/presentation/viewmodel/check_internet_cubit.dart';
import 'package:efs_misr/main_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Animations
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // Start animation
    _controller.forward();

    // Navigate after 3 seconds
    // Timer(const Duration(seconds: 3), () {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (context) => const MainApp()),
    //   );
    // });
  }

  @override
  void dispose() {
    _controller.dispose(); // clean up
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckInternetCubit, CheckInternetState>(
      listener: (context, state) {
        if (state is InternetConnected) {
          Timer(const Duration(seconds: 3), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainApp()),
            );
          });
        }
        if (state is InternetDisconnected) {
          _showNoInternetDialog(context);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SvgPicture.asset(
                'assets/images/iconlogo.svg',
                width: 150,
                height: 150,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('لا يوجد اتصال بالإنترنت'),
        content: const Text('يرجى التأكد من اتصالك ثم إعادة المحاولة'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Cubit هيتابع لوحده الاتصال
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}
