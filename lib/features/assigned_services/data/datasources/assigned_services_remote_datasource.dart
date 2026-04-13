import 'package:service_reminder/features/assigned_services/domain/entities/assigned_service.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/today_visit_summary.dart';

abstract interface class AssignedServicesRemoteDataSource {
  Future<List<AssignedService>> getDashboardVisits();

  /// All assignments on today's date (any status except cancelled), for summary stats.
  Future<TodayVisitSummary> getTodayVisitSummary();

  /// Next open assignment for [customerId] (not completed/cancelled), by [scheduled_date].
  Future<AssignedService?> getActiveAssignmentForCustomer(String customerId);

  /// All assignments for [customerId], newest first (any status).
  Future<List<AssignedService>> getAssignmentsForCustomer(String customerId);

  /// All completed visits for the current technician, newest first.
  Future<List<AssignedService>> getCompletedVisits();

  Future<AssignedService> create(AssignedService service);
  Future<AssignedService> update(AssignedService service);
  Future<void> delete(String id);
}
