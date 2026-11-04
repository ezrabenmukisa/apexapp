import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user_role.dart';

/// The user's role (Owner / Site manager), remembered per Firebase uid on
/// this phone.
///
/// The live API's `/users/me` has no `user_role` yet, so the role chosen on
/// Complete Profile lives here. It deliberately survives sign-out so a
/// returning user isn't asked again; on a new phone they choose it once.
@lazySingleton
class RoleLocalDataSource {
  const RoleLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  String _key(String uid) => 'apex.role.$uid';

  UserRole? read(String uid) => UserRole.fromApi(_prefs.getString(_key(uid)));

  Future<void> write(String uid, UserRole role) =>
      _prefs.setString(_key(uid), role.apiValue);
}
