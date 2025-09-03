
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Features/Auth/domain/auth_repo.dart';
import 'Features/Auth/presentation/viewmodel/auth_cubit.dart';
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
    ], child: GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EFS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MainApp(),
    ));



  }
}
