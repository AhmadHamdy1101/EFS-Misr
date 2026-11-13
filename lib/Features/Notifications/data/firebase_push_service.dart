import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'push_service.dart';

// getToken / onTokenRefresh / deleteToken are deprecated in firebase_messaging
// 17 in favour of FID registration (register / onRegistered). send-push
// targets FCM HTTP v1 `message.token`, which takes registration tokens, so
// the token API stays until the sender moves to FID direct-send.
// ignore_for_file: deprecated_member_use

/// Web Push certificate (VAPID public key) from Firebase Console → Project
/// settings → Cloud Messaging → Web Push certificates. Passed at build time:
/// `flutter build web --dart-define=FCM_VAPID_KEY=<key>`. Without it push is
/// off on web; in-app notifications still arrive through Supabase realtime.
const fcmVapidKey = String.fromEnvironment('FCM_VAPID_KEY');

/// [PushService] backed by Firebase Cloud Messaging (Android and web).
///
/// Only receives: messages are sent by the `send-push` edge function, never
/// from the app. Foreground messages are ignored on purpose: the same
/// notification already reaches the open app through Supabase realtime and
/// is shown as an in-app banner, so showing the push too would duplicate it.
class FirebasePushService implements PushService {
  FirebasePushService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  final List<StreamSubscription<Object?>> _subs = [];

  @override
  bool get isAvailable => !kIsWeb || fcmVapidKey.isNotEmpty;

  static String get platform {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  String? get _vapidKey => kIsWeb ? fcmVapidKey : null;

  @override
  Future<void> start({
    required Future<void> Function(String token, String platform) onToken,
    required void Function(Map<String, dynamic> data) onOpened,
  }) async {
    await stop(deleteToken: false);
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        // Not an error: the in-app list and badge keep working.
        developer.log('Notification permission denied', name: 'Push');
        return;
      }

      _subs.add(
        FirebaseMessaging.onMessageOpenedApp.listen((m) => onOpened(m.data)),
      );
      final initial = kIsWeb
          ? webLaunchData(Uri.base)
          : (await _messaging.getInitialMessage())?.data;
      if (initial != null) onOpened(initial);

      _subs.add(
        _messaging.onTokenRefresh.listen((token) => onToken(token, platform)),
      );
      final token = await _messaging.getToken(vapidKey: _vapidKey);
      if (token != null) await onToken(token, platform);
    } catch (error) {
      // Missing Play services, blocked service worker, unsupported browser…
      developer.log('Push unavailable: $error', name: 'Push');
    }
  }

  static bool _webLaunchConsumed = false;

  /// On web a tapped push opens the app at the link set by `send-push`
  /// (`?efs_push=<id>&type=…&ticket_id=…`); the plugin doesn't report those
  /// taps, so the ids are read from the URL, once per page load.
  @visibleForTesting
  static Map<String, dynamic>? webLaunchData(Uri uri) {
    if (_webLaunchConsumed) return null;
    final params = uri.queryParameters;
    if (!params.containsKey('efs_push')) return null;
    _webLaunchConsumed = true;
    return {
      for (final e in params.entries)
        if (e.key == 'efs_push') 'notification_id': e.value else e.key: e.value,
    };
  }

  @visibleForTesting
  static void resetWebLaunch() => _webLaunchConsumed = false;

  @override
  Future<String?> currentToken() async {
    try {
      return await _messaging.getToken(vapidKey: _vapidKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> stop({bool deleteToken = true}) async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    if (!deleteToken) return;
    try {
      // The server-side row is removed by the caller before sign-out; this
      // makes the old token useless even if that call failed.
      await _messaging.deleteToken();
    } catch (_) {}
  }
}
