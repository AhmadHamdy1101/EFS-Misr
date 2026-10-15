import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Features/Splash/presentation/splash_screen.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_translations.dart';
import '../core/utils/singelton.dart';
import '../core/utils/theme_service.dart';
import 'app_providers.dart';

class EfsApp extends StatelessWidget {
  const EfsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = getIt.get<ThemeService>();
    return AppProviders(
      child: GetMaterialApp(
        title: 'EFS',
        debugShowCheckedModeBanner: false,
        translations: AppTranslations(),
        locale: themeService.locale,
        fallbackLocale: const Locale('en'),
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeService.themeMode,
        home: const SplashScreen(),
      ),
    );
  }
}
