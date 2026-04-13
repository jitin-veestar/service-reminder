import 'package:service_reminder/features/customers/domain/entities/customer.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/service_note.dart';

enum AssignedServiceStatus { draft, booked, overdue, completed, scheduled, cancelled }

extension AssignedServiceStatusX on AssignedServiceStatus {
  String get label => switch (this) {
        AssignedServiceStatus.draft => 'Draft',
        AssignedServiceStatus.booked => 'Booked',
        AssignedServiceStatus.overdue => 'Overdue',
        AssignedServiceStatus.completed => 'Completed',
        AssignedServiceStatus.scheduled => 'Scheduled',
        AssignedServiceStatus.cancelled => 'Cancelled',
      };

  static AssignedServiceStatus fromString(String value) =>
      AssignedServiceStatus.values.firstWhere(
        (e) => e.name == value.toLowerCase(),
        orElse: () => AssignedServiceStatus.draft,
      );
}

class AssignedService {
  final String id;
  final String technicianId;
  final String customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? serviceOfferingId;
  final String? serviceOfferingName;
  final DateTime scheduledDate;

  /// Time in "HH:mm" format, e.g. "10:30"
  final String? scheduledTime;

  final AssignedServiceStatus status;
  final List<ServiceNote> notes;
  final DateTime createdAt;

  /// From joined `customers` row (dashboard / detail).
  final CustomerType? customerType;
  final int? serviceFrequencyDays;

  const AssignedService({
    required this.id,
    required this.technicianId,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.serviceOfferingId,
    this.serviceOfferingName,
    required this.scheduledDate,
    this.scheduledTime,
    this.status = AssignedServiceStatus.draft,
    this.notes = const [],
    required this.createdAt,
    this.customerType,
    this.serviceFrequencyDays,
  });

  AssignedService copyWith({
    String? id,
    String? technicianId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? serviceOfferingId,
    String? serviceOfferingName,
    DateTime? scheduledDate,
    String? scheduledTime,
    AssignedServiceStatus? status,
    List<ServiceNote>? notes,
    DateTime? createdAt,
    CustomerType? customerType,
    int? serviceFrequencyDays,
  }) {
    return AssignedService(
      id: id ?? this.id,
      technicianId: technicianId ?? this.technicianId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      serviceOfferingId: serviceOfferingId ?? this.serviceOfferingId,
      serviceOfferingName: serviceOfferingName ?? this.serviceOfferingName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      customerType: customerType ?? this.customerType,
      serviceFrequencyDays: serviceFrequencyDays ?? this.serviceFrequencyDays,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'customer_id': customerId,
        'service_offering_id': serviceOfferingId,
        'service_offering_name': serviceOfferingName,
        'scheduled_date': scheduledDate.toIso8601String().substring(0, 10),
        'scheduled_time': scheduledTime,
        'status': status.name,
        'notes': notes.map((n) => n.toJson()).toList(),
      };

  factory AssignedService.fromJson(Map<String, dynamic> json) {
    final customersData = json['customers'] as Map<String, dynamic>?;
    final typeStr = customersData?['customer_type'] as String?;
    return AssignedService(
      id: json['id'] as String,
      technicianId: json['technician_id'] as String,
      customerId: json['customer_id'] as String,
      customerName: customersData?['name'] as String?,
      customerPhone: customersData?['phone'] as String?,
      customerAddress: customersData?['address'] as String?,
      serviceOfferingId: json['service_offering_id'] as String?,
      serviceOfferingName: json['service_offering_name'] as String?,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      scheduledTime: json['scheduled_time'] as String?,
      status: AssignedServiceStatusX.fromString(
        (json['status'] as String?) ?? 'draft',
      ),
      notes: (json['notes'] as List? ?? [])
          .map((n) => ServiceNote.fromJson(n as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      customerType: typeStr == null
          ? null
          : (typeStr == 'amc' ? CustomerType.amc : CustomerType.oneTime),
      serviceFrequencyDays: (customersData?['service_frequency_days'] as num?)
          ?.toInt(),
    );
  }
}
