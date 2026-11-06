/// Pure-Dart date/time helpers (no Flutter dependency).
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
