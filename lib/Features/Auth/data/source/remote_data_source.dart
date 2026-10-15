import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/models/supadart_header.dart';
import '../../../../core/models/user.dart';

abstract class AuthRemoteData {
  String? get currentUserId;
  Stream<AuthChangeEvent> get authEvents;
  Future<String> signIn({required String email, required String password});
  Future<void> signOut();
  Future<Users> getUserData({required String userId});
  Future<Users> uploadProfileImage({
    required BigInt id,
    required String userId,
    required File file,
    String? previousImageUrl,
  });
}

class AuthRemoteDataImpl extends AuthRemoteData {
  AuthRemoteDataImpl(this._client);

  final SupabaseClient _client;
  static const _bucket = 'images';

  @override
  String? get currentUserId => _client.auth.currentSession?.user.id;

  @override
  Stream<AuthChangeEvent> get authEvents =>
      _client.auth.onAuthStateChange.map((state) => state.event);

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final userId = res.user?.id;
    if (userId == null) throw const AuthException('Login failed: user missing');
    return userId;
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<Users> getUserData({required String userId}) {
    return _client.users
        .select(Users.selectColumns)
        .eq(Users.c_userid, userId)
        .single()
        .withConverter(Users.converterSingle);
  }

  @override
  Future<Users> uploadProfileImage({
    required BigInt id,
    required String userId,
    required File file,
    String? previousImageUrl,
  }) async {
    var ext = file.path.split('.').last.toLowerCase();
    if (ext == 'jpg') ext = 'jpeg';
    // A unique name per upload means a new URL, so cached old photos are never
    // shown, and two users with the same name can't overwrite each other.
    final path = '$userId-${DateTime.now().millisecondsSinceEpoch}.$ext';

    final storage = _client.storage.from(_bucket);
    await storage.upload(
      path,
      file,
      fileOptions: FileOptions(contentType: 'image/$ext'),
    );
    final imageUrl = storage.getPublicUrl(path);

    final user = await _client.users
        .update(Users.update(image: imageUrl))
        .eq(Users.c_id, id)
        .select(Users.selectColumns)
        .single()
        .withConverter(Users.converterSingle);

    await _removeOldImage(previousImageUrl);
    return user;
  }

  Future<void> _removeOldImage(String? url) async {
    const marker = '/object/public/$_bucket/';
    if (url == null || !url.contains(marker)) return;
    try {
      await _client.storage.from(_bucket).remove([url.split(marker).last]);
    } catch (_) {
      // Best effort: a leftover file is harmless.
    }
  }
}
