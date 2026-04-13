import 'package:intl/intl.dart';
import 'package:service_reminder/core/constants/reminder_defaults.dart';

abstract final class DateTimeUtils {
  static final _dateFormatter = DateFormat('dd MMM yyyy');
  static final _shortDateFormatter = DateFormat('dd MMM');
  static final _time12h = DateFormat('h:mm a');

  static String formatDate(DateTime date) => _dateFormatter.format(date);
  static String formatShortDate(DateTime date) => _shortDateFormatter.format(date);

  /// Converts stored `scheduled_time` (`HH:mm`, 24-hour) to 12-hour, e.g. `2:30 PM`.
  static String formatTime12HourFromHhMm(String hhmm24) {
    final trimmed = hhmm24.trim();
    final parts = trimmed.split(':');
    if (parts.isEmpty) return trimmed;
    final h = int.tryParse(parts[0].trim());
    final m = parts.length > 1 ? int.tryParse(parts[1].trim()) : 0;
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return trimmed;
    }
    return _time12h.format(DateTime(2000, 1, 1, h, m));
  }

  /// Returns a date 90 days after [from].
  static DateTime nextServiceDate(DateTime from) =>
      from.add(const Duration(days: ReminderDefaults.nextServiceDays));

  static bool isOverdue(DateTime date) => date.isBefore(_today());

  static bool isDueToday(DateTime date) {
    final today = _today();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  static bool isDueSoon(DateTime date) {
    final today = _today();
    final limit = today.add(
      const Duration(days: ReminderDefaults.dueSoonThresholdDays),
    );
    return !isOverdue(date) && !isDueToday(date) && date.isBefore(limit);
  }

  /// Negative = overdue, 0 = today, positive = days remaining.
  static int daysUntil(DateTime date) {
    final today = _today();
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  static String relativeDateLabel(DateTime date) {
    final days = daysUntil(date);
    if (days < 0) return '${days.abs()} day${days.abs() == 1 ? '' : 's'} overdue';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
