/// Device push messaging (FCM) behind an interface.
///
/// The app ships with [DisabledPushService] because the project has no
/// Firebase configuration yet. In-app notifications work without it (they
/// arrive through Supabase realtime while the app is open). To enable push,
/// follow docs/notifications.md: add `firebase_core` + `firebase_messaging`,
/// run `flutterfire configure`, implement this interface with
/// `FirebaseMessaging`, and register it in `singelton.dart`.
abstract interface class PushService {
  /// Whether push is available on this build/device.
  bool get isAvailable;

  /// Asks for notification permission (where the OS requires it) and starts
  /// listening. [onToken] gets the current token and every refresh;
  /// [onOpened] gets the `data` of a notification the user tapped, including
  /// the one that launched the app.
  Future<void> start({
    required Future<void> Function(String token, String platform) onToken,
    required void Function(Map<String, dynamic> data) onOpened,
  });

  /// The current token, if any (used to unregister on sign-out).
  Future<String?> currentToken();

  /// Stops listening (sign-out). The token itself is removed server-side by
  /// the caller.
  Future<void> stop();
}

class DisabledPushService implements PushService {
  const DisabledPushService();

  @override
  bool get isAvailable => false;

  @override
  Future<void> start({
    required Future<void> Function(String token, String platform) onToken,
    required void Function(Map<String, dynamic> data) onOpened,
  }) async {}

  @override
  Future<String?> currentToken() async => null;

  @override
  Future<void> stop() async {}
}
