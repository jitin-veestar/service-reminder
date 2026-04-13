import 'package:service_reminder/features/assigned_services/data/datasources/assigned_services_remote_datasource.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/assigned_service.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/today_visit_summary.dart';
import 'package:service_reminder/features/assigned_services/domain/repositories/assigned_services_repository.dart';

class AssignedServicesRepositoryImpl implements AssignedServicesRepository {
  final AssignedServicesRemoteDataSource _remote;

  AssignedServicesRepositoryImpl(this._remote);

  @override
  Future<List<AssignedService>> getDashboardVisits() =>
      _remote.getDashboardVisits();

  @override
  Future<TodayVisitSummary> getTodayVisitSummary() =>
      _remote.getTodayVisitSummary();

  @override
  Future<AssignedService?> getActiveAssignmentForCustomer(String customerId) =>
      _remote.getActiveAssignmentForCustomer(customerId);

  @override
  Future<List<AssignedService>> getAssignmentsForCustomer(String customerId) =>
      _remote.getAssignmentsForCustomer(customerId);

  @override
  Future<AssignedService> create(AssignedService service) =>
      _remote.create(service);

  @override
  Future<AssignedService> update(AssignedService service) =>
      _remote.update(service);

  @override
  Future<List<AssignedService>> getCompletedVisits() =>
      _remote.getCompletedVisits();

  @override
  Future<void> delete(String id) => _remote.delete(id);
}
