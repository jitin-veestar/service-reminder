import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:service_reminder/core/constants/app_constants.dart';
import 'package:service_reminder/core/constants/db_tables.dart';
import 'package:service_reminder/core/errors/app_exception.dart';

class ReportsRawData {
  /// service_history rows for the current selected period.
  final List<Map<String, dynamic>> serviceHistory;

  /// service_history rows for the previous period (comparison).
  final List<Map<String, dynamic>> prevServiceHistory;

  /// All service_history rows ever (used for active/inactive customer calc).
  final List<Map<String, dynamic>> allServiceHistory;

  /// assigned_services where status = 'completed', current period.
  final List<Map<String, dynamic>> assignedCompleted;

  /// assigned_services completed, previous period (comparison).
  final List<Map<String, dynamic>> prevAssigned;

  /// All customers (all-time, for breakdown stats).
  final List<Map<String, dynamic>> customers;

  const ReportsRawData({
    required this.serviceHistory,
    required this.prevServiceHistory,
    required this.allServiceHistory,
    required this.assignedCompleted,
    required this.prevAssigned,
    required this.customers,
  });
}

class ReportsRemoteDataSource {
  final SupabaseClient _client;
  const ReportsRemoteDataSource(this._client);

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  Future<ReportsRawData> fetch({
    required DateTime from,
    required DateTime to,
    required DateTime prevFrom,
    required DateTime prevTo,
  }) async {
    try {
      final uid = _client.auth.currentUser!.id;

      final fromStr = _dateFmt.format(from);
      final toStr = _dateFmt.format(to);
      final prevFromStr = _dateFmt.format(prevFrom);
      final prevToStr = _dateFmt.format(prevTo);

      final amountSel = AppConstants.servicesHasAmountChargedColumn
          ? ', amount_charged'
          : '';

      final results = await Future.wait([
        // 0 — current period service_history
        _client
            .from(DbTables.serviceHistory)
            .select(
                'id, customer_id, serviced_at, catalog_service_id$amountSel')
            .eq('technician_id', uid)
            .gte('serviced_at', '${fromStr}T00:00:00')
            .lte('serviced_at', '${toStr}T23:59:59')
            .order('serviced_at', ascending: false),

        // 1 — previous period service_history
        _client
            .from(DbTables.serviceHistory)
            .select('id, customer_id$amountSel')
            .eq('technician_id', uid)
            .gte('serviced_at', '${prevFromStr}T00:00:00')
            .lte('serviced_at', '${prevToStr}T23:59:59'),

        // 2 — all service_history (for active/inactive customer calculation)
        _client
            .from(DbTables.serviceHistory)
            .select('customer_id, next_service_at')
            .eq('technician_id', uid),

        // 3 — current period completed assigned_services
        _client
            .from(DbTables.assignedServices)
            .select(
                'id, customer_id, scheduled_date, scheduled_time, service_offering_name')
            .eq('technician_id', uid)
            .eq('status', 'completed')
            .gte('scheduled_date', fromStr)
            .lte('scheduled_date', toStr),

        // 4 — previous period completed assigned_services
        _client
            .from(DbTables.assignedServices)
            .select('id, customer_id')
            .eq('technician_id', uid)
            .eq('status', 'completed')
            .gte('scheduled_date', prevFromStr)
            .lte('scheduled_date', prevToStr),

        // 5 — all customers
        _client
            .from(DbTables.customers)
            .select('id, name, customer_type, service_frequency_days'),
      ]);

      List<Map<String, dynamic>> toList(dynamic d) =>
          (d as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

      return ReportsRawData(
        serviceHistory: toList(results[0]),
        prevServiceHistory: toList(results[1]),
        allServiceHistory: toList(results[2]),
        assignedCompleted: toList(results[3]),
        prevAssigned: toList(results[4]),
        customers: toList(results[5]),
      );
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, code: e.code);
    }
  }
}
