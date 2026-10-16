import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/app_user.dart';
import '../models/app_user_model.dart';

/// Caches the signed-in user's profile so the app opens offline on site.
///
/// Stored in the platform keystore, keyed by Firebase uid, and wiped on
/// sign-out.
@lazySingleton
class SessionLocalDataSource {
  const SessionLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;

  static const _userKey = 'apex.cached_user';
  static const _uidKey = 'apex.cached_uid';

  Future<AppUser?> cachedUser({required String uid}) async {
    if (await _storage.read(key: _uidKey) != uid) return null;
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    return AppUserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> cacheUser(AppUser user, {required String uid}) async {
    await _storage.write(key: _uidKey, value: uid);
    await _storage.write(
      key: _userKey,
      value: jsonEncode(AppUserModel.toJson(user)),
    );
  }

  Future<void> clear() async {
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _uidKey);
  }
}
