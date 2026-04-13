import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:service_reminder/core/constants/db_tables.dart';
import 'package:service_reminder/core/errors/app_exception.dart';
import 'package:service_reminder/features/customers/data/datasources/customers_remote_datasource.dart';
import 'package:service_reminder/features/customers/data/dtos/customer_dto.dart';
import 'package:service_reminder/features/customers/data/mappers/customer_mapper.dart';
import 'package:service_reminder/features/customers/domain/entities/customer.dart';
import 'package:service_reminder/features/services/data/dtos/service_record_dto.dart';

class CustomersRemoteDataSourceImpl implements CustomersRemoteDataSource {
  final SupabaseClient _client;
  const CustomersRemoteDataSourceImpl(this._client);

  String get _uid => _client.auth.currentUser!.id;

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  /// Keeps reminders accurate when [service_frequency_days] changes on the customer.
  Future<void> _resyncLatestServiceNextDue({
    required String customerId,
    required int frequencyDays,
  }) async {
    final rows = await _client
        .from(DbTables.serviceHistory)
        .select('id, serviced_at')
        .eq('customer_id', customerId)
        .eq('technician_id', _uid)
        .order('serviced_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return;
    final row = (rows as List).first as Map<String, dynamic>;
    final serviced = DateTime.parse(row['serviced_at'] as String);
    final day = DateTime(serviced.year, serviced.month, serviced.day);
    final next = DateTime(day.year, day.month, day.day + frequencyDays);
    await _client
        .from(DbTables.serviceHistory)
        .update({'next_service_at': _dateFmt.format(next)})
        .eq('id', row['id'] as String)
        .eq('technician_id', _uid);
  }

  @override
  Future<List<Customer>> getAll() async {
    try {
      final response = await _client
          .from(DbTables.customers)
          .select()
          .order('created_at', ascending: false);
      final customers = CustomerMapper.fromJsonList(response);

      final serviceRows = await _client
          .from(DbTables.serviceHistory)
          .select('customer_id, next_service_at, serviced_at')
          .order('serviced_at', ascending: false);

      final nextByCustomerId = <String, DateTime>{};
      for (final row in serviceRows as List) {
        final m = row as Map<String, dynamic>;
        final cid = m['customer_id'] as String;
        if (nextByCustomerId.containsKey(cid)) continue;
        nextByCustomerId[cid] =
            DateTime.parse(m['next_service_at'] as String);
      }

      return customers
          .map((c) => c.withNextService(nextByCustomerId[c.id]))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, code: e.code);
    }
  }

  @override
  Future<Customer> getById(String id) async {
    try {
      final response = await _client
          .from(DbTables.customers)
          .select()
          .eq('id', id)
          .single();
      return CustomerMapper.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, code: e.code);
    }
  }

  @override
  Future<Customer> create({
    required String name,
    String? phone,
    String? address,
    required int serviceFrequencyDays,
    required CustomerType customerType,
  }) async {
    try {
      final dto = CustomerDto(
        id: '',           // ignored — server generates it
        technicianId: _uid,
        name: name.trim(),
        phone: phone?.trim(),
        address: address?.trim(),
        createdAt: DateTime.now(),
        serviceFrequencyDays: serviceFrequencyDays,
        customerType: customerType,
      );
      final response = await _client
          .from(DbTables.customers)
          .insert(dto.toInsertJson(_uid))
          .select()
          .single();
      final customer = CustomerMapper.fromJson(response);

      // One-time: treat the creation day as the first service visit so reminders
      // and history align with the chosen service frequency.
      if (customerType == CustomerType.oneTime) {
        await _client.from(DbTables.serviceHistory).insert(
              ServiceRecordDto.initialOneTimeVisitInsertJson(
                customerId: customer.id,
                technicianId: _uid,
                customerCreatedAt: customer.createdAt,
                serviceFrequencyDays: customer.serviceFrequencyDays,
              ),
            );
      }

      return customer;
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, code: e.code);
    }
  }

  @override
  Future<Customer> update({
    required String id,
    required String name,
    String? phone,
    String? address,
    required int serviceFrequencyDays,
    required CustomerType customerType,
  }) async {
    try {
      final existing = await getById(id);
      final dto = CustomerDto(
        id: id,
        technicianId: existing.technicianId,
        name: name.trim(),
        phone: phone?.trim(),
        address: address?.trim(),
        createdAt: existing.createdAt,
        serviceFrequencyDays: serviceFrequencyDays,
        customerType: customerType,
      );
      final response = await _client
          .from(DbTables.customers)
          .update(dto.toUpdateJson())
          .eq('id', id)
          .eq('technician_id', _uid)
          .select()
          .single();
      return CustomerMapper.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, code: e.code);
    }
  }
}
