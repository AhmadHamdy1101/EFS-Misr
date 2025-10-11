import 'package:efs_misr/Features/Auth/domain/auth_repo.dart';
import 'package:efs_misr/Features/Auth/presentation/viewmodel/auth_cubit.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:efs_misr/Features/Home/presentation/pages/SplashScreen.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/accounts_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/assets_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/assets_repair_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/assets_tickets_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/qrcode_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/tickets_cubit.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants/constants.dart';
import 'core/utils/singelton.dart';
import 'core/utils/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supbaseUrl, anonKey: supbaseKey);
  final themeService = ThemeService();
  final themeMode = await themeService.loadThemeFromBox();
  setup();
  runApp(MyApp(themeMode: themeMode));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.themeMode});
  final ThemeMode themeMode;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit(getIt.get<AuthRepo>())),
        BlocProvider(
          create: (context) =>
              TicketsCubit(getIt.get<HomeRepo>())..getTickets(),
        ),
        BlocProvider(
          create: (context) => AssetsCubit(getIt.get<HomeRepo>())..getAssets(),
        ),
        BlocProvider(create: (context) => QrcodeCubit(getIt.get<HomeRepo>())),
        BlocProvider(create: (context) => AccountsCubit(getIt.get<HomeRepo>())),
        BlocProvider(
          create: (context) => AssetsTicketsCubit(getIt.get<HomeRepo>()),
        ),
        BlocProvider(
          create: (context) => AssetsRepairCubit(getIt.get<HomeRepo>()),
        ),
      ],
      child: GetMaterialApp(
        translations: AppTranslations(),
        locale: Locale('en'),
        debugShowCheckedModeBanner: false,
        title: 'EFS',
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: AppColors.white,
          scaffoldBackgroundColor: AppColors.appBackground,
          cardColor: AppColors.white,
          appBarTheme: AppBarTheme(backgroundColor: Colors.transparent),
          cardTheme: CardThemeData(
            color: AppColors.white,
            shadowColor: AppColors.black,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: AppColors.black),
            bodyMedium: TextStyle(color: AppColors.black),
            titleLarge: TextStyle(color: AppColors.black),
          ),
          buttonTheme: ButtonThemeData(
            colorScheme: ColorScheme(
              brightness: Brightness.light,
              primary: AppColors.white,
              onPrimary: AppColors.white,
              secondary: AppColors.green,
              onSecondary: AppColors.green,
              error: Colors.red,
              onError: Colors.red,
              surface: const Color(0xff1f2a3b),
              onSurface: const Color(0xff1f2a3b),
            ),
          ),
          colorScheme: ColorScheme.light(
            primary: AppColors.black,
            tertiary: AppColors.lightGray,
            secondary: AppColors.green,
            brightness: Brightness.light,
            error: Colors.red,
            onPrimary: AppColors.green,
            onSecondary: AppColors.white,
            onError: Colors.red,
            surface: AppColors.white,
            onSurface: AppColors.white,
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: AppColors.white,
          ),
          // colorScheme: ColorScheme.fromSeed(seedColor: AppColors.appBackground),
        ),
        darkTheme: ThemeData(
          primaryColor: AppColors.scafolddark,
          colorScheme: ColorScheme.dark(
            primary: AppColors.white,
            tertiary: AppColors.gray,
            // 👈 لون إضافي
            secondary: AppColors.green,
            brightness: Brightness.dark,
            error: Colors.red,
            onPrimary: AppColors.green,
            onSecondary: AppColors.white,
            onError: Colors.red,
            surface: AppColors.buttondark,
            onSurface: AppColors.white,
          ),
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.scafolddark,
          cardColor: AppColors.black,
          appBarTheme: AppBarTheme(backgroundColor: AppColors.scafolddark),
          shadowColor: AppColors.white,
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.transparent,
          ),
          buttonTheme: ButtonThemeData(
            colorScheme: ColorScheme(
              brightness: Brightness.dark,
              primary: AppColors.buttondark,
              onPrimary: AppColors.buttondark,
              secondary: AppColors.green,
              onSecondary: AppColors.green,
              error: Colors.red,
              onError: Colors.red,
              surface: const Color(0xff1f2a3b),
              onSurface: const Color(0xff1f2a3b),
            ),
          ),
          cardTheme: CardThemeData(
            color: AppColors.buttondark,
            shadowColor: AppColors.white.withOpacity(0.25),
          ),
        ),
        themeMode: widget.themeMode,
        home: SplashScreen(),
      ),
    );
  }
}
