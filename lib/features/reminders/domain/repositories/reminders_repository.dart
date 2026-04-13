import 'package:service_reminder/features/reminders/domain/entities/reminder.dart';

abstract interface class RemindersRepository {
  /// Returns customers whose most recent service is due or overdue.
  Future<List<Reminder>> getDueReminders();
}
