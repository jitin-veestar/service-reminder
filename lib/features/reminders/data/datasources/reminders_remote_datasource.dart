import 'package:service_reminder/features/reminders/domain/entities/reminder.dart';

abstract interface class RemindersRemoteDataSource {
  Future<List<Reminder>> getDueReminders();
}
