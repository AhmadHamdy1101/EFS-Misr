import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Server view of this device's session (`public.session_status()`).
enum SessionCheck {
  /// This device holds the account's active session.
  current,

  /// The account signed in on another device; this session is revoked.
  replaced,

  /// Not claimed yet (signed in with an older build); claim it.
  unclaimed,

  /// Couldn't ask the server (offline). The database still refuses a
  /// replaced session, so the app carries on and checks again later.
  unknown,
}

/// One active device per account, enforced by the database
/// (supabase/migrations/20261028132627_single_active_session.sql). The
/// session id is taken from the signed JWT on the server, never sent by the
/// app, so this class only asks and listens; it can't grant anything.
abstract interface class SessionGuard {
  /// Makes this device's session the active one and revokes the others.
  /// Throws [SessionEndedException] if this session was already revoked.
  Future<void> claim({required String deviceId});

  Future<SessionCheck> check();

  /// Fires when the account's active session changes (another sign-in).
  /// The caller confirms with [check] before acting.
  Stream<void> watch(String authUserId);
}

class SessionEndedException implements Exception {
  const SessionEndedException();
}

class SupabaseSessionGuard implements SessionGuard {
  SupabaseSessionGuard(this._client);

  final SupabaseClient _client;

  @override
  Future<void> claim({required String deviceId}) async {
    try {
      await _client.rpc('claim_session', params: {'p_device_id': deviceId});
    } on PostgrestException catch (e) {
      if (e.code == 'SE001') throw const SessionEndedException();
      rethrow;
    }
  }

  @override
  Future<SessionCheck> check() async {
    try {
      final status = await _client.rpc<String?>('session_status');
      return switch (status) {
        'current' => SessionCheck.current,
        'replaced' => SessionCheck.replaced,
        'unclaimed' => SessionCheck.unclaimed,
        _ => SessionCheck.unknown,
      };
    } catch (error) {
      developer.log('Session check failed: $error', name: 'SessionGuard');
      return SessionCheck.unknown;
    }
  }

  @override
  Stream<void> watch(String authUserId) {
    final controller = StreamController<void>();
    final channel = _client.channel('user_sessions:$authUserId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: authUserId,
          ),
          callback: (_) => controller.add(null),
        )
        .subscribe();
    controller.onCancel = () => _client.removeChannel(channel);
    return controller.stream;
  }
}
