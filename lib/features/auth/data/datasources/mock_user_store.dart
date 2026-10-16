import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/exceptions.dart';

/// Stands in for the backend `users` table while `USE_MOCK_API` is on.
///
/// Profiles are keyed by Firebase uid and persisted in shared preferences,
/// so `profile_complete` survives restarts like it would on the server.
@mock
@lazySingleton
class MockUserStore {
  const MockUserStore(this._auth, this._prefs);

  final FirebaseAuth _auth;
  final SharedPreferences _prefs;

  String currentUid() => _uid();

  String _uid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const ServerException('Not authenticated', statusCode: 401);
    }
    return uid;
  }

  String _key(String uid) => 'mock_api.users.$uid';

  String currentUserId() => 'usr_${_uid()}';

  Map<String, dynamic>? currentProfile() {
    final raw = _prefs.getString(_key(_uid()));
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveProfile(Map<String, dynamic> json) =>
      _prefs.setString(_key(_uid()), jsonEncode(json));
}
