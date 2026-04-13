import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:service_reminder/core/services/notifications/notification_service.dart';
import 'package:service_reminder/core/services/supabase/supabase_client_provider.dart';
import 'package:service_reminder/core/utils/id_utils.dart';
import 'package:service_reminder/features/assigned_services/data/datasources/assigned_services_remote_datasource_impl.dart';
import 'package:service_reminder/features/assigned_services/data/repositories/assigned_services_repository_impl.dart';
import 'package:service_reminder/features/assigned_services/domain/assigned_service_status_rules.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/assigned_service.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/service_note.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/today_visit_summary.dart';
import 'package:service_reminder/features/assigned_services/domain/repositories/assigned_services_repository.dart';
import 'package:service_reminder/features/customers/domain/entities/customer.dart';

// ── Dependency providers ──────────────────────────────────────────────────────

final assignedServicesRepositoryProvider =
    Provider<AssignedServicesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AssignedServicesRepositoryImpl(
    AssignedServicesRemoteDataSourceImpl(client),
  );
});

// ── Dashboard visits ──────────────────────────────────────────────────────────

/// Open visits in the dashboard window plus today's totals (includes completed today).
class DashboardVisitsData {
  final List<AssignedService> visits;
  final TodayVisitSummary todaySummary;

  const DashboardVisitsData({
    required this.visits,
    required this.todaySummary,
  });
}

final dashboardVisitsProvider =
    AsyncNotifierProvider<DashboardVisitsNotifier, DashboardVisitsData>(
  DashboardVisitsNotifier.new,
);

/// Open assignment used to pre-fill Record Service (date + catalog service).
final activeAssignmentForCustomerProvider =
    FutureProvider.family<AssignedService?, String>((ref, customerId) {
  return ref
      .read(assignedServicesRepositoryProvider)
      .getActiveAssignmentForCustomer(customerId);
});

/// All completed visits for the current technician, newest first.
final completedVisitsProvider =
    FutureProvider<List<AssignedService>>((ref) {
  return ref.read(assignedServicesRepositoryProvider).getCompletedVisits();
});

/// All assignments for a customer (any status), newest first.
/// Used to display reschedule history in the customer history page.
final customerAssignmentsProvider =
    FutureProvider.family<List<AssignedService>, String>((ref, customerId) {
  return ref
      .read(assignedServicesRepositoryProvider)
      .getAssignmentsForCustomer(customerId);
});

class DashboardVisitsNotifier extends AsyncNotifier<DashboardVisitsData> {
  @override
  Future<DashboardVisitsData> build() => _fetch();

  Future<DashboardVisitsData> _fetch() async {
    final repo = ref.read(assignedServicesRepositoryProvider);
    final visitsFuture = repo.getDashboardVisits();
    final summaryFuture = repo.getTodayVisitSummary();
    final visits = await visitsFuture;
    final summary = await summaryFuture;

    // Keep local notifications in sync with the latest visit list.
    NotificationService.syncVisitReminders(visits).ignore();

    return DashboardVisitsData(visits: visits, todaySummary: summary);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> createVisit(AssignedService service) async {
    await ref.read(assignedServicesRepositoryProvider).create(service);
    await refresh();
  }

  Future<AssignedService> patchVisit(AssignedService service) async {
    final updated =
        await ref.read(assignedServicesRepositoryProvider).update(service);
    await refresh();
    return updated;
  }

  Future<void> cancelVisit(AssignedService visit) async {
    // Cancel reminder immediately — don't wait for refresh.
    NotificationService.cancelVisitReminder(visit.id).ignore();
    await ref.read(assignedServicesRepositoryProvider).update(
          visit.copyWith(status: AssignedServiceStatus.cancelled),
        );
    await refresh();
  }

  Future<void> rescheduleVisit(
    AssignedService visit, {
    required DateTime newDate,
    required String? newTime,
    required String reason,
  }) async {
    final note = ServiceNote(
      id: IdUtils.tempId(),
      noteTime: DateTime.now(),
      message: reason,
      status: 'rescheduled',
    );
    final newStatus = newTime != null
        ? AssignedServiceStatusRules.persistedAfterTimeSet(newDate, newTime)
        : AssignedServiceStatus.draft;
    await ref.read(assignedServicesRepositoryProvider).update(
          visit.copyWith(
            scheduledDate: newDate,
            scheduledTime: newTime,
            status: newStatus,
            notes: [...visit.notes, note],
          ),
        );
    await refresh();
  }

  /// Marks [visit] completed and optionally creates a follow-up assignment.
  /// [oneTimeFollowUpMonths]: only for one-time customers; `null` = no follow-up.
  Future<void> completeVisit(
    AssignedService visit, {
    int? oneTimeFollowUpMonths,
  }) async {
    // Cancel reminder immediately — visit is done.
    NotificationService.cancelVisitReminder(visit.id).ignore();
    final repo = ref.read(assignedServicesRepositoryProvider);
    await repo.update(
      visit.copyWith(status: AssignedServiceStatus.completed),
    );

    final type = visit.customerType ?? CustomerType.oneTime;
    if (type == CustomerType.amc) {
      final days = visit.serviceFrequencyDays ?? 120;
      final t = DateTime.now().add(Duration(days: days));
      final next = DateTime(t.year, t.month, t.day);
      await repo.create(_followUpFrom(visit, next));
    } else if (oneTimeFollowUpMonths != null) {
      final raw = AssignedServiceStatusRules.addCalendarMonths(
        DateTime.now(),
        oneTimeFollowUpMonths,
      );
      final next = DateTime(raw.year, raw.month, raw.day);
      await repo.create(_followUpFrom(visit, next));
    }
    await refresh();
  }

  AssignedService _followUpFrom(AssignedService visit, DateTime scheduledDate) {
    return AssignedService(
      id: '',
      technicianId: visit.technicianId,
      customerId: visit.customerId,
      customerName: visit.customerName,
      customerPhone: visit.customerPhone,
      serviceOfferingId: visit.serviceOfferingId,
      serviceOfferingName: visit.serviceOfferingName,
      scheduledDate: scheduledDate,
      scheduledTime: null,
      status: AssignedServiceStatus.draft,
      notes: const [],
      createdAt: DateTime.now(),
      customerType: visit.customerType,
      serviceFrequencyDays: visit.serviceFrequencyDays,
    );
  }
}
