/// The user's role, from `User.user_role` in the Apex ER diagram.
///
/// Drives which shell the app shows. Per-project permissions are still
/// enforced by the backend through each project's `current_user_role`.
enum UserRole {
  /// Plans the project and reviews evidence.
  owner('OWNER'),

  /// Site manager / contractor: submits evidence from site.
  manager('MANAGER');

  const UserRole(this.apiValue);

  final String apiValue;

  /// Parses the API enum. Accepts `PROJECT_MANAGER`, which the contract uses
  /// for project membership, as a synonym for [manager].
  static UserRole? fromApi(Object? value) => switch (value) {
    'OWNER' => owner,
    'MANAGER' || 'PROJECT_MANAGER' => manager,
    _ => null,
  };
}
