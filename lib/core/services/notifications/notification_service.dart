import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:service_reminder/features/assigned_services/domain/entities/assigned_service.dart';
import 'package:service_reminder/features/assigned_services/domain/assigned_service_status_rules.dart';

/// Channel identifiers
const _kChannelId = 'service_reminder_channel';
const _kChannelName = 'Service Reminders';
const _kChannelDesc =
    'Visit reminders, overdue alerts, and daily briefings';

/// Fixed notification IDs
const _kMorningBriefingId = 0;

/// Stable IDs per visit — keep reminder and overdue on separate ranges.
int _visitReminderNotifId(String visitId) =>
    visitId.hashCode.abs() % 900000 + 1000;

int _visitOverdueNotifId(String visitId) =>
    visitId.hashCode.abs() % 900000 + 1000000;

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ── Initialise ────────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_initialized) return;

    // Timezone setup
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      // Fallback to UTC if timezone lookup fails
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    _initialized = true;
  }

  // ── Permission request ────────────────────────────────────────────────────

  static Future<void> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('[NotificationService] Permission request error: $e');
    }
  }

  // ── Android notification details ──────────────────────────────────────────

  static AndroidNotificationDetails _androidDetails({
    String channelId = _kChannelId,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) {
    return AndroidNotificationDetails(
      channelId,
      _kChannelName,
      channelDescription: _kChannelDesc,
      importance: importance,
      priority: priority,
      icon: '@mipmap/ic_launcher',
    );
  }

  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static NotificationDetails get _details => NotificationDetails(
        android: _androidDetails(),
        iOS: _iosDetails,
      );

  // ── Morning briefing — daily at 08:00 ────────────────────────────────────

  static Future<void> scheduleMorningBriefing() async {
    await _plugin.cancel(_kMorningBriefingId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      8, // 08:00 AM
    );
    // If 8am already passed today, start tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _kMorningBriefingId,
      'Good morning! 🌅',
      'Open the app to check your visits for today.',
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
  }

  // ── Visit reminder — 30 min before scheduled time ─────────────────────────

  static Future<void> scheduleVisitReminder(AssignedService visit) async {
    final time = visit.scheduledTime?.trim();
    if (time == null || time.isEmpty) return;

    final id = _visitReminderNotifId(visit.id);
    await _plugin.cancel(id); // clear any previous reminder for this visit

    // Parse scheduled datetime
    final scheduledDt =
        AssignedServiceStatusRules.scheduledDateTime(visit.scheduledDate, time);
    final reminderDt = scheduledDt.subtract(const Duration(minutes: 30));

    if (reminderDt.isBefore(DateTime.now())) return; // already passed

    final tzReminder = tz.TZDateTime.from(reminderDt, tz.local);
    final customerName = visit.customerName ?? 'your customer';
    final timeLabel = _formatTime(scheduledDt);

    await _plugin.zonedSchedule(
      id,
      'Upcoming visit in 30 min',
      '$customerName — $timeLabel',
      tzReminder,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Overdue alert — fires 1 min after scheduled slot (visit not completed) ─

  static Future<void> scheduleOverdueAlert(AssignedService visit) async {
    final time = visit.scheduledTime?.trim();
    if (time == null || time.isEmpty) return;

    final scheduledDt =
        AssignedServiceStatusRules.scheduledDateTime(visit.scheduledDate, time);
    final overdueAt = scheduledDt.add(const Duration(minutes: 1));

    if (overdueAt.isBefore(DateTime.now())) return;

    final id = _visitOverdueNotifId(visit.id);
    await _plugin.cancel(id);

    final tzOverdue = tz.TZDateTime.from(overdueAt, tz.local);
    final customerName = visit.customerName ?? 'Customer';
    final timeLabel = _formatTime(scheduledDt);
    final service = visit.serviceOfferingName?.trim();
    final body = (service != null && service.isNotEmpty)
        ? '$customerName was due at $timeLabel · $service'
        : '$customerName was due at $timeLabel';

    await _plugin.zonedSchedule(
      id,
      'Visit overdue',
      body,
      tzOverdue,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Cancel a single visit's reminder + overdue ───────────────────────────

  static Future<void> cancelVisitReminder(String visitId) async {
    await _plugin.cancel(_visitReminderNotifId(visitId));
    await _plugin.cancel(_visitOverdueNotifId(visitId));
  }

  // ── Reschedule all reminders from a fresh visit list ─────────────────────
  /// Called after every dashboard refresh to keep notifications in sync.

  static Future<void> syncVisitReminders(
    List<AssignedService> visits,
  ) async {
    // Cancel ALL currently pending notifications except morning briefing,
    // then reschedule from the live list.
    final pending = await _plugin.pendingNotificationRequests();
    for (final n in pending) {
      if (n.id != _kMorningBriefingId) {
        await _plugin.cancel(n.id);
      }
    }

    for (final v in visits) {
      await scheduleVisitReminder(v);
      await scheduleOverdueAlert(v);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final min = m.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }
}
