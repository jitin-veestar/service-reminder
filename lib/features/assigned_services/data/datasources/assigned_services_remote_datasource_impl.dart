import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:service_reminder/core/constants/app_constants.dart';
import 'package:service_reminder/core/constants/db_tables.dart';
import 'package:service_reminder/features/assigned_services/data/datasources/assigned_services_remote_datasource.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/assigned_service.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/today_visit_summary.dart';

class AssignedServicesRemoteDataSourceImpl
    implements AssignedServicesRemoteDataSource {
  final SupabaseClient _client;

  AssignedServicesRemoteDataSourceImpl(this._client);

  String get _userId => _client.auth.currentUser!.id;

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  static String _customersEmbedSelect() {
    final parts = <String>['name', 'phone', 'address'];
    if (AppConstants.customersHasCustomerTypeColumn) {
      parts.add('customer_type');
    }
    if (AppConstants.customersHasServiceFrequencyDaysColumn) {
      parts.add('service_frequency_days');
    }
    return parts.join(', ');
  }

  @override
  Future<List<AssignedService>> getDashboardVisits() async {
    final today = DateTime.now();
    final startStr =
        _dateFmt.format(today.subtract(const Duration(days: 45)));
    final endStr = _dateFmt.format(today.add(const Duration(days: 7)));

    final data = await _client
        .from(DbTables.assignedServices)
        .select('*, customers(${_customersEmbedSelect()})')
        .eq('technician_id', _userId)
        .gte('scheduled_date', startStr)
        .lte('scheduled_date', endStr)
        .not('status', 'in', '("completed","cancelled")')
        .order('scheduled_date')
        .order('scheduled_time', nullsFirst: false);

    return (data as List)
        .map((row) => AssignedService.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TodayVisitSummary> getTodayVisitSummary() async {
    final todayStr = _dateFmt.format(DateTime.now());
    final data = await _client
        .from(DbTables.assignedServices)
        .select('status')
        .eq('technician_id', _userId)
        .eq('scheduled_date', todayStr);

    var scheduledToday = 0;
    var completedToday = 0;
    for (final row in data as List) {
      final st = (row as Map<String, dynamic>)['status'] as String?;
      if (st == null || st == 'cancelled') continue;
      scheduledToday++;
      if (st == 'completed') completedToday++;
    }
    return TodayVisitSummary(
      scheduledTodayCount: scheduledToday,
      completedTodayCount: completedToday,
    );
  }

  @override
  Future<AssignedService?> getActiveAssignmentForCustomer(
    String customerId,
  ) async {
    final data = await _client
        .from(DbTables.assignedServices)
        .select('*, customers(name, phone)')
        .eq('technician_id', _userId)
        .eq('customer_id', customerId)
        .not('status', 'in', '("completed","cancelled")')
        .order('scheduled_date')
        .limit(1)
        .maybeSingle();
    if (data == null) return null;
    return AssignedService.fromJson(data);
  }

  @override
  Future<List<AssignedService>> getAssignmentsForCustomer(
    String customerId,
  ) async {
    final data = await _client
        .from(DbTables.assignedServices)
        .select('*, customers(${_customersEmbedSelect()})')
        .eq('technician_id', _userId)
        .eq('customer_id', customerId)
        .order('scheduled_date', ascending: false);

    return (data as List)
        .map((row) => AssignedService.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AssignedService> create(AssignedService service) async {
    final data = await _client
        .from(DbTables.assignedServices)
        .insert({...service.toInsertJson(), 'technician_id': _userId})
        .select('*, customers(${_customersEmbedSelect()})')
        .single();

    return AssignedService.fromJson(data);
  }

  @override
  Future<AssignedService> update(AssignedService service) async {
    final data = await _client
        .from(DbTables.assignedServices)
        .update({
          'service_offering_id': service.serviceOfferingId,
          'service_offering_name': service.serviceOfferingName,
          'scheduled_date':
              service.scheduledDate.toIso8601String().substring(0, 10),
          'scheduled_time': service.scheduledTime,
          'status': service.status.name,
          'notes': service.notes.map((n) => n.toJson()).toList(),
        })
        .eq('id', service.id)
        .select('*, customers(${_customersEmbedSelect()})')
        .single();

    return AssignedService.fromJson(data);
  }

  @override
  Future<List<AssignedService>> getCompletedVisits() async {
    final data = await _client
        .from(DbTables.assignedServices)
        .select('*, customers(${_customersEmbedSelect()})')
        .eq('technician_id', _userId)
        .eq('status', 'completed')
        .order('scheduled_date', ascending: false);

    return (data as List)
        .map((row) => AssignedService.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(DbTables.assignedServices).delete().eq('id', id);
  }
}
