import 'package:service_reminder/features/assigned_services/domain/entities/assigned_service.dart';

/// Display + persistence rules for [AssignedService.status].
///
/// - `cancelled` / `completed` always follow stored status.
/// - Date only (no time) → `draft`.
/// - Date + time, slot not yet passed → `booked`.
/// - Date + time, slot in the past → `overdue`.
abstract final class AssignedServiceStatusRules {
  static AssignedServiceStatus derive(AssignedService s, [DateTime? now]) {
    if (s.status == AssignedServiceStatus.cancelled) {
      return AssignedServiceStatus.cancelled;
    }
    if (s.status == AssignedServiceStatus.completed) {
      return AssignedServiceStatus.completed;
    }
    final time = s.scheduledTime?.trim();
    if (time == null || time.isEmpty) {
      return AssignedServiceStatus.draft;
    }
    final at = scheduledDateTime(s.scheduledDate, time);
    final n = now ?? DateTime.now();
    if (!at.isBefore(n)) {
      return AssignedServiceStatus.booked;
    }
    return AssignedServiceStatus.overdue;
  }

  /// Status to store when the user sets a time (before completion/cancel).
  static AssignedServiceStatus persistedAfterTimeSet(
    DateTime date,
    String timeStr,
  ) {
    final at = scheduledDateTime(date, timeStr.trim());
    if (!at.isBefore(DateTime.now())) {
      return AssignedServiceStatus.booked;
    }
    return AssignedServiceStatus.overdue;
  }

  static DateTime scheduledDateTime(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0].trim()) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1].trim()) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, h, m);
  }

  static DateTime addCalendarMonths(DateTime d, int months) =>
      DateTime(d.year, d.month + months, d.day);
}
