import 'package:service_reminder/features/services/domain/entities/service_record.dart';

abstract interface class ServicesRepository {
  Future<ServiceRecord> create({
    required String customerId,
    required DateTime servicedAt,
    required DateTime nextServiceAt,
    String? notes,
    required bool filterChanged,
    required bool membraneChecked,
    required bool cleaningDone,
    required bool leakageFixed,
    required double amountCharged,
    String? catalogServiceId,
    String? audioStoragePath,
  });

  Future<List<ServiceRecord>> getByCustomerId(String customerId);
}
