import 'package:intl/intl.dart';

import 'package:service_reminder/core/constants/app_constants.dart';
import 'package:service_reminder/features/services/domain/entities/service_record.dart';

class ServiceRecordDto {
  final String id;
  final String customerId;
  final String technicianId;
  final DateTime servicedAt;
  final DateTime nextServiceAt;
  final String? notes;
  final bool filterChanged;
  final bool membraneChecked;
  final bool cleaningDone;
  final bool leakageFixed;
  final DateTime createdAt;
  final double amountCharged;
  final String? catalogServiceId;
  final String? audioStoragePath;

  const ServiceRecordDto({
    required this.id,
    required this.customerId,
    required this.technicianId,
    required this.servicedAt,
    required this.nextServiceAt,
    this.notes,
    required this.filterChanged,
    required this.membraneChecked,
    required this.cleaningDone,
    required this.leakageFixed,
    required this.createdAt,
    this.amountCharged = 0.0,
    this.catalogServiceId,
    this.audioStoragePath,
  });

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  factory ServiceRecordDto.fromJson(Map<String, dynamic> json) {
    return ServiceRecordDto(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      technicianId: json['technician_id'] as String,
      servicedAt: DateTime.parse(json['serviced_at'] as String),
      nextServiceAt: DateTime.parse(json['next_service_at'] as String),
      notes: json['notes'] as String?,
      filterChanged: (json['filter_changed'] as bool?) ?? false,
      membraneChecked: (json['membrane_checked'] as bool?) ?? false,
      cleaningDone: (json['cleaning_done'] as bool?) ?? false,
      leakageFixed: (json['leakage_fixed'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      amountCharged: (json['amount_charged'] as num?)?.toDouble() ?? 0.0,
      catalogServiceId: json['catalog_service_id'] as String?,
      audioStoragePath: json['audio_storage_path'] as String?,
    );
  }

  /// JSON for INSERT — id and created_at are server-generated.
  Map<String, dynamic> toInsertJson(String technicianId) => {
        'customer_id': customerId,
        'technician_id': technicianId,
        'serviced_at': _dateFmt.format(servicedAt),
        'next_service_at': _dateFmt.format(nextServiceAt),
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        'filter_changed': filterChanged,
        'membrane_checked': membraneChecked,
        'cleaning_done': cleaningDone,
        'leakage_fixed': leakageFixed,
        if (AppConstants.servicesHasAmountChargedColumn)
          'amount_charged': amountCharged,
        if (AppConstants.serviceHistoryHasExtendedFields) ...{
          if (catalogServiceId != null) 'catalog_service_id': catalogServiceId,
          if (audioStoragePath != null && audioStoragePath!.isNotEmpty)
            'audio_storage_path': audioStoragePath,
        },
      };

  /// First visit for a new **one-time** customer: visit date = account creation day,
  /// next due = that day + [serviceFrequencyDays].
  static Map<String, dynamic> initialOneTimeVisitInsertJson({
    required String customerId,
    required String technicianId,
    required DateTime customerCreatedAt,
    required int serviceFrequencyDays,
  }) {
    final visit = DateTime(
      customerCreatedAt.year,
      customerCreatedAt.month,
      customerCreatedAt.day,
    );
    final next = DateTime(
      visit.year,
      visit.month,
      visit.day + serviceFrequencyDays,
    );
    return {
      'customer_id': customerId,
      'technician_id': technicianId,
      'serviced_at': _dateFmt.format(visit),
      'next_service_at': _dateFmt.format(next),
      'filter_changed': true,
      'membrane_checked': false,
      'cleaning_done': true,
      'leakage_fixed': false,
      if (AppConstants.servicesHasAmountChargedColumn) 'amount_charged': 0.0,
    };
  }

  ServiceRecord toDomain() => ServiceRecord(
        id: id,
        customerId: customerId,
        technicianId: technicianId,
        servicedAt: servicedAt,
        nextServiceAt: nextServiceAt,
        notes: notes,
        filterChanged: filterChanged,
        membraneChecked: membraneChecked,
        cleaningDone: cleaningDone,
        leakageFixed: leakageFixed,
        createdAt: createdAt,
        amountCharged: amountCharged,
        catalogServiceId: catalogServiceId,
        audioStoragePath: audioStoragePath,
      );
}
