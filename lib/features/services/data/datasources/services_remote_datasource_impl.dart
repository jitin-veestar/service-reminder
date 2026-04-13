import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:service_reminder/core/constants/db_tables.dart';
import 'package:service_reminder/core/errors/app_exception.dart';
import 'package:service_reminder/features/services/data/datasources/services_remote_datasource.dart';
import 'package:service_reminder/features/services/data/dtos/service_record_dto.dart';
import 'package:service_reminder/features/services/data/mappers/service_record_mapper.dart';
import 'package:service_reminder/features/services/domain/entities/service_record.dart';

class ServicesRemoteDataSourceImpl implements ServicesRemoteDataSource {
  final SupabaseClient _client;
  const ServicesRemoteDataSourceImpl(this._client);

  String get _uid => _client.auth.currentUser!.id;

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
  }) async {
    try {
      final dto = ServiceRecordDto(
        id: '',
        customerId: customerId,
        technicianId: _uid,
        servicedAt: servicedAt,
        nextServiceAt: nextServiceAt,
        notes: notes,
        filterChanged: filterChanged,
        membraneChecked: membraneChecked,
        cleaningDone: cleaningDone,
        leakageFixed: leakageFixed,
        createdAt: DateTime.now(),
        amountCharged: amountCharged,
        catalogServiceId: catalogServiceId,
        audioStoragePath: audioStoragePath,
      );
      final response = await _client
          .from(DbTables.serviceHistory)
          .insert(dto.toInsertJson(_uid))
          .select()
          .single();
      return ServiceRecordMapper.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, code: e.code);
    }
  }
}
