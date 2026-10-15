import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/efs_app.dart';
import 'constants/constants.dart';
import 'core/utils/singelton.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supbaseUrl, anonKey: supbaseKey);
  final prefs = await SharedPreferences.getInstance();
  setup(prefs: prefs);
  runApp(const EfsApp());
}
