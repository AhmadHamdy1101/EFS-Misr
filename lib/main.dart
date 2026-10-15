import 'package:efs_misr/Features/Assets_data/domain/repo/assets_data_repo.dart';
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_repair_repository.dart';
import 'package:efs_misr/Features/Assets_data/domain/usecases/add_asset_repair_use_case.dart';
import 'package:efs_misr/Features/Auth/domain/auth_repo.dart';
import 'package:efs_misr/Features/Auth/presentation/viewmodel/auth_cubit.dart';
import 'package:efs_misr/Features/Accounts/domain/accounts_repo.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/check_internet_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/image_cubit.dart';
import 'package:efs_misr/Features/Splash/presentation/splash_screen.dart';
import 'package:efs_misr/Features/Accounts/presentation/controller/accounts_cubit.dart';
import 'package:efs_misr/Features/Assets_data/presentation/controller/assets_tickets_cubit.dart';
import 'package:efs_misr/Features/Assets_data/presentation/controller/qrcode_cubit.dart';
import 'package:efs_misr/Features/Tickets/domain/repo/tickets_repo.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Features/Assets_data/presentation/controller/assets_cubit.dart';
import 'Features/Assets_data/presentation/controller/assets_repair_cubit.dart';
import 'Features/Tickets/presentation/controller/tickets_cubit.dart';
import 'constants/constants.dart';
import 'core/utils/singelton.dart';
import 'core/utils/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supbaseUrl, anonKey: supbaseKey);
  final prefs = await SharedPreferences.getInstance();
  setup(prefs: prefs);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = getIt.get<ThemeService>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => CheckInternetCubit(Connectivity())),
        BlocProvider(create: (context) => AuthCubit(getIt.get<AuthRepo>())),
        BlocProvider(
          create: (context) =>
              TicketsCubit(ticketsRepo: getIt.get<TicketsRepo>()),
        ),
        BlocProvider(
          create: (context) => AssetsCubit(getIt.get<AssetsDataRepo>()),
        ),
        BlocProvider(
          create: (context) => QrcodeCubit(getIt.get<AssetsDataRepo>()),
        ),
        BlocProvider(
          create: (context) => AccountsCubit(getIt.get<AccountsRepo>()),
        ),
        BlocProvider(
          create: (context) => AssetsTicketsCubit(
            getIt.get<AssetsDataRepo>(),
            getIt.get<AssetsRepairRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) => AssetsRepairCubit(
            assetsRepairRepository: getIt.get<AssetsRepairRepository>(),
            addAssetRepair: getIt.get<AddAssetRepairUseCase>(),
          ),
        ),
        BlocProvider(create: (context) => ImageCubit(getIt.get<AuthRepo>())),
      ],
      child: GetMaterialApp(
        translations: AppTranslations(),
        locale: themeService.locale,
        fallbackLocale: const Locale('en'),
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
            onPrimary: AppColors.white,
            onSecondary: AppColors.white,
            onError: Colors.red,
            surface: AppColors.white,
            onSurface: AppColors.black,
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
            shadowColor: AppColors.white.withValues(alpha: 0.25),
          ),
        ),
        themeMode: themeService.themeMode,
        home: const SplashScreen(),
      ),
    );
  }
}
