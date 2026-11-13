import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Features/Notifications/data/firebase_push_service.dart';
import 'Features/Notifications/data/push_service.dart';
import 'app/efs_app.dart';
import 'constants/constants.dart';
import 'core/utils/singelton.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supbaseUrl, anonKey: supbaseKey);
  final prefs = await SharedPreferences.getInstance();
  setup(prefs: prefs, push: await _startFirebase());
  runApp(const EfsApp());
}

/// Firebase is only used for push. If it can't start, the app still runs
/// with in-app (realtime) notifications.
Future<PushService?> _startFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return FirebasePushService();
  } catch (error) {
    developer.log('Firebase unavailable: $error', name: 'main');
    return null;
  }
}
