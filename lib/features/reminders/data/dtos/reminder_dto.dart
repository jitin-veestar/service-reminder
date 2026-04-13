import 'package:service_reminder/features/reminders/domain/entities/reminder.dart';

/// Parses a services row joined with customers data.
class ReminderDto {
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final DateTime nextServiceAt;
  final DateTime lastServiceAt;

  const ReminderDto({
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.nextServiceAt,
    required this.lastServiceAt,
  });

  factory ReminderDto.fromJson(Map<String, dynamic> json) {
    final customer = json['customers'] as Map<String, dynamic>;
    return ReminderDto(
      customerId: json['customer_id'] as String,
      customerName: customer['name'] as String,
      customerPhone: customer['phone'] as String?,
      customerAddress: customer['address'] as String?,
      nextServiceAt: DateTime.parse(json['next_service_at'] as String),
      lastServiceAt: DateTime.parse(json['serviced_at'] as String),
    );
  }

  Reminder toDomain() => Reminder(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        nextServiceAt: nextServiceAt,
        lastServiceAt: lastServiceAt,
      );
}
