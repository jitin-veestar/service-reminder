import 'package:service_reminder/features/services/domain/entities/checklist_item.dart';

class ServiceRecord {
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
  /// FK to `services` catalog row when set.
  final String? catalogServiceId;
  /// Path in the `service-recordings` Storage bucket.
  final String? audioStoragePath;

  const ServiceRecord({
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

  List<ChecklistItem> get checklistItems => Checklist.fromBooleans(
        filterChanged: filterChanged,
        membraneChecked: membraneChecked,
        cleaningDone: cleaningDone,
        leakageFixed: leakageFixed,
      );

  int get checklistDoneCount =>
      checklistItems.where((c) => c.isChecked).length;
}
