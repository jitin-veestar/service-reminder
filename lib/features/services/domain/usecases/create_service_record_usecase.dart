import 'package:service_reminder/features/services/domain/entities/service_record.dart';
import 'package:service_reminder/features/services/domain/repositories/services_repository.dart';

class CreateServiceRecordUseCase {
  final ServicesRepository _repository;
  const CreateServiceRecordUseCase(this._repository);

  Future<ServiceRecord> call({
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
  }) =>
      _repository.create(
        customerId: customerId,
        servicedAt: servicedAt,
        nextServiceAt: nextServiceAt,
        notes: notes,
        filterChanged: filterChanged,
        membraneChecked: membraneChecked,
        cleaningDone: cleaningDone,
        leakageFixed: leakageFixed,
        amountCharged: amountCharged,
        catalogServiceId: catalogServiceId,
        audioStoragePath: audioStoragePath,
      );
}
