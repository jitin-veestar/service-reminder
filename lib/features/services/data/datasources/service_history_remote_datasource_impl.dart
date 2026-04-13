import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:service_reminder/core/constants/db_tables.dart';
import 'package:service_reminder/core/errors/app_exception.dart';
import 'package:service_reminder/features/services/data/datasources/service_history_remote_datasource.dart';
import 'package:service_reminder/features/services/data/mappers/service_record_mapper.dart';
import 'package:service_reminder/features/services/domain/entities/service_record.dart';

class ServiceHistoryRemoteDataSourceImpl
    implements ServiceHistoryRemoteDataSource {
  final SupabaseClient _client;
  const ServiceHistoryRemoteDataSourceImpl(this._client);

  @override
  Future<List<ServiceRecord>> getByCustomerId(String customerId) async {
    try {
      final response = await _client
          .from(DbTables.serviceHistory)
          .select()
          .eq('customer_id', customerId)
          .order('serviced_at', ascending: false);
      return ServiceRecordMapper.fromJsonList(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, code: e.code);
    }
  }
}
