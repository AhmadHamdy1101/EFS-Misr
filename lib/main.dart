
import 'package:efs_misr/Features/Auth/domain/auth_repo.dart';
import 'package:efs_misr/Features/Auth/presentation/viewmodel/auth_cubit.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/accounts_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/assets_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/qrcode_cubit.dart';
import 'package:efs_misr/Features/Home/presentation/viewmodel/tickets_cubit.dart';
import 'package:efs_misr/core/utils/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/constants.dart';
import 'core/utils/singelton.dart';
import 'main_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supbaseUrl, anonKey: supbaseKey);
  setup();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(providers: [
      BlocProvider(create: (context) => AuthCubit(getIt.get<AuthRepo>())),
      BlocProvider(create: (context) => TicketsCubit(getIt.get<HomeRepo>())..getTickets()),
      BlocProvider(create: (context) => AssetsCubit(getIt.get<HomeRepo>())..getAssets()),
      BlocProvider(create: (context) => QrcodeCubit(getIt.get<HomeRepo>())),
      BlocProvider(create: (context) => AccountsCubit(getIt.get<HomeRepo>())),
    ], child: GetMaterialApp(
      translations: AppTranslations(),
      locale: Locale('en'),
      debugShowCheckedModeBanner: false,
      title: 'EFS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MainApp(),
    ));



  }
}
