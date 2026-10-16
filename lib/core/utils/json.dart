/// Helpers for the API's JSON conventions.
abstract final class Json {
  /// `date` fields are ISO dates without time: `2026-10-02`.
  static String? date(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';

  static DateTime? parseDate(Object? value) =>
      value is String && value.isNotEmpty ? DateTime.parse(value) : null;

  static DateTime parseDateTime(Object? value) =>
      DateTime.parse(value as String).toLocal();

  static double? toDouble(Object? value) => switch (value) {
    num() => value.toDouble(),
    String() => double.tryParse(value),
    _ => null,
  };

  static String? blankToNull(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  static List<String> stringList(Object? value) =>
      value is List ? [for (final v in value) v.toString()] : const [];

  /// List endpoints return either a bare array or `{"items": [...]}`.
  static List<Map<String, dynamic>> items(Object? data) {
    final list = switch (data) {
      List() => data,
      {'items': final List items} => items,
      _ => const [],
    };
    return [for (final e in list) Map<String, dynamic>.from(e as Map)];
  }
}
