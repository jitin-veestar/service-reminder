import 'package:service_reminder/features/services/data/datasources/service_history_remote_datasource.dart';
import 'package:service_reminder/features/services/data/datasources/services_remote_datasource.dart';
import 'package:service_reminder/features/services/domain/entities/service_record.dart';
import 'package:service_reminder/features/services/domain/repositories/services_repository.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  final ServicesRemoteDataSource _services;
  final ServiceHistoryRemoteDataSource _history;

  const ServicesRepositoryImpl(this._services, this._history);

  @override
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
  }) =>
      _services.create(
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

  @override
  Future<List<ServiceRecord>> getByCustomerId(String customerId) =>
      _history.getByCustomerId(customerId);
}
