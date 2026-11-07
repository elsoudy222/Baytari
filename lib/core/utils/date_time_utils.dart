/// Pure-Dart date/time helpers (no Flutter dependency).
///
/// The format is always `yyyy-MM-dd` / `HH:mm` with zero-padding
/// (`padLeft(2, '0')`), so `2026-11-7` becomes `2026-11-07` and dates
/// sort correctly as plain strings. These are ready for M4/M5
/// (appointments, schedules) and are not used by any M0 screen yet.
abstract final class DateTimeUtils {
  /// Formats a date as `yyyy-MM-dd`, e.g. `2026-11-07`.
  static String formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Formats a time as `HH:mm`, e.g. `15:00`.
  static String formatTime(DateTime date) {
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
