/// Form validators shared by the auth screens. Return null when valid.
abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phone = RegExp(r'^\+?[0-9 ()-]{7,20}$');

  static String? required(String? value, String field) =>
      (value?.trim().isEmpty ?? true) ? 'Enter your $field' : null;

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    return _email.hasMatch(v) ? null : 'That email address doesn\'t look right';
  }

  static String? optionalPhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    return _phone.hasMatch(v)
        ? null
        : 'Use international format, e.g. +256 772 123456';
  }

  static String? password(String? value) =>
      (value?.length ?? 0) < 6 ? 'Use at least 6 characters' : null;
}
