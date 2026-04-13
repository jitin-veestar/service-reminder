import 'package:service_reminder/features/reminders/domain/entities/reminder.dart';
import 'package:service_reminder/features/reminders/domain/repositories/reminders_repository.dart';

class GetDueRemindersUseCase {
  final RemindersRepository _repository;
  const GetDueRemindersUseCase(this._repository);

  Future<List<Reminder>> call() => _repository.getDueReminders();
}
