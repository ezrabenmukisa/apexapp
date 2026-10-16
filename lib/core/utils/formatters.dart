import 'package:intl/intl.dart';

/// Display formatting shared across screens. Money is a ledger: always in
/// the project currency, compact on cards ("28M") and exact on detail.
abstract final class Formatters {
  static final _grouped = NumberFormat('#,##0', 'en');

  /// `140M`, `2.5M`, `850K`, `1.2B`.
  static String compactMoney(num amount) {
    final a = amount.abs();
    String trim(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    if (a >= 1e9) return '${trim(amount / 1e9)}B';
    if (a >= 1e6) return '${trim(amount / 1e6)}M';
    if (a >= 1e3) return '${trim(amount / 1e3)}K';
    return trim(amount.toDouble());
  }

  /// `UGX 28,000,000`.
  static String money(num amount, {String currency = 'UGX'}) =>
      '$currency ${_grouped.format(amount)}';

  /// `28,000,000` (no currency, for inputs).
  static String grouped(num amount) => _grouped.format(amount);

  /// Parses user input such as `28,000,000` or `28 000 000`.
  static double? parseAmount(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9.]'), '');
    return digits.isEmpty ? null : double.tryParse(digits);
  }

  /// `2 Oct`.
  static String dayMonth(DateTime d) => DateFormat('d MMM').format(d);

  /// `2 Oct 2026`.
  static String date(DateTime d) => DateFormat('d MMM y').format(d);

  /// `2 Oct – 1 Nov`, or `2 – 22 Nov` within a month.
  static String dateRange(DateTime start, DateTime? end) {
    if (end == null) return '${dayMonth(start)} –';
    if (start.month == end.month && start.year == end.year) {
      return '${start.day} – ${dayMonth(end)}';
    }
    return '${dayMonth(start)} – ${dayMonth(end)}';
  }

  /// `10:42`.
  static String time(DateTime d) => DateFormat('HH:mm').format(d);

  /// `10:58 AM, 14 Oct`.
  static String timeAndDay(DateTime d) =>
      '${DateFormat('h:mm a').format(d)}, ${dayMonth(d)}';

  /// `14 OCT 2026 · 10:42 EAT` — machine-recorded proof data, in caps.
  static String proofTimestamp(DateTime d) {
    final local = d.toLocal();
    final zone = local.timeZoneName.toUpperCase();
    return '${DateFormat('d MMM y').format(local).toUpperCase()} · '
        '${DateFormat('HH:mm').format(local)} $zone';
  }

  /// `0.40441 N, 32.45940 E`.
  static String coordinates(double lat, double lng) =>
      '${lat.abs().toStringAsFixed(5)} ${lat >= 0 ? 'N' : 'S'}, '
      '${lng.abs().toStringAsFixed(5)} ${lng >= 0 ? 'E' : 'W'}';

  /// `Good morning` / `Good afternoon` / `Good evening`.
  static String greeting(DateTime now) => switch (now.hour) {
    < 12 => 'Good morning',
    < 17 => 'Good afternoon',
    _ => 'Good evening',
  };

  /// Whole days from [now] until [date] (negative when overdue).
  static int daysUntil(DateTime date, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    return _dateOnly(date).difference(today).inDays;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
