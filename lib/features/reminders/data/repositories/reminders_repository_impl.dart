import 'package:service_reminder/features/reminders/data/datasources/reminders_remote_datasource.dart';
import 'package:service_reminder/features/reminders/domain/entities/reminder.dart';
import 'package:service_reminder/features/reminders/domain/repositories/reminders_repository.dart';

class RemindersRepositoryImpl implements RemindersRepository {
  final RemindersRemoteDataSource _remote;
  const RemindersRepositoryImpl(this._remote);

  @override
  Future<List<Reminder>> getDueReminders() => _remote.getDueReminders();
}
