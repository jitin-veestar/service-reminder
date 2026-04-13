import 'package:service_reminder/features/reminders/data/dtos/reminder_dto.dart';
import 'package:service_reminder/features/reminders/domain/entities/reminder.dart';

abstract final class ReminderMapper {
  static Reminder fromJson(Map<String, dynamic> json) =>
      ReminderDto.fromJson(json).toDomain();
}
