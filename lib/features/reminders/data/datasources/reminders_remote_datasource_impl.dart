import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:service_reminder/core/constants/db_tables.dart';
import 'package:service_reminder/core/constants/reminder_defaults.dart';
import 'package:service_reminder/core/errors/app_exception.dart';
import 'package:service_reminder/features/reminders/data/datasources/reminders_remote_datasource.dart';
import 'package:service_reminder/features/reminders/data/mappers/reminder_mapper.dart';
import 'package:service_reminder/features/reminders/domain/entities/reminder.dart';

class RemindersRemoteDataSourceImpl implements RemindersRemoteDataSource {
  final SupabaseClient _client;
  const RemindersRemoteDataSourceImpl(this._client);

  @override
  Future<List<Reminder>> getDueReminders() async {
    try {
      // Fetch all services with customer data, newest service first.
      // RLS ensures we only see this technician's data.
      final response = await _client
          .from(DbTables.serviceHistory)
          .select('customer_id, serviced_at, next_service_at, customers(name, phone, address)')
          .order('serviced_at', ascending: false);

      // Deduplicate: keep only the most recent service per customer.
      final seen = <String>{};
      final latestRows = <Map<String, dynamic>>[];
      for (final row in response as List) {
        final customerId = row['customer_id'] as String;
        if (seen.add(customerId)) {
          latestRows.add(row as Map<String, dynamic>);
        }
      }

      // Threshold: today + dueSoonThresholdDays
      final threshold = DateTime.now().add(
        const Duration(days: ReminderDefaults.dueSoonThresholdDays),
      );
      final thresholdStr =
          '${threshold.year}-${threshold.month.toString().padLeft(2, '0')}-${threshold.day.toString().padLeft(2, '0')}';

      // Filter to customers due on or before the threshold.
      final due = latestRows.where((row) {
        final nextDate = row['next_service_at'] as String;
        return nextDate.compareTo(thresholdStr) <= 0;
      }).toList();

      final reminders = due.map(ReminderMapper.fromJson).toList();
      // Sort: most overdue first.
      reminders.sort((a, b) => a.nextServiceAt.compareTo(b.nextServiceAt));
      return reminders;
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, code: e.code);
    }
  }
}
