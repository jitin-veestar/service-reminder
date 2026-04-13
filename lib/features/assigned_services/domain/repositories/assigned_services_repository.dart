import 'package:service_reminder/features/assigned_services/domain/entities/assigned_service.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/today_visit_summary.dart';

abstract interface class AssignedServicesRepository {
  /// Open assignments in the dashboard window (excludes completed/cancelled).
  Future<List<AssignedService>> getDashboardVisits();

  Future<TodayVisitSummary> getTodayVisitSummary();

  Future<AssignedService?> getActiveAssignmentForCustomer(String customerId);

  /// All assignments for [customerId], newest first (any status).
  Future<List<AssignedService>> getAssignmentsForCustomer(String customerId);

  /// All completed visits for the current technician, newest first.
  Future<List<AssignedService>> getCompletedVisits();

  Future<AssignedService> create(AssignedService service);

  Future<AssignedService> update(AssignedService service);

  Future<void> delete(String id);
}
