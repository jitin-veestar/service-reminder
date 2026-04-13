import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:service_reminder/core/constants/db_tables.dart';
import 'package:service_reminder/core/errors/app_exception.dart';
import 'package:service_reminder/features/service_catalog/data/datasources/service_offerings_remote_datasource.dart';
import 'package:service_reminder/features/service_catalog/data/dtos/service_offering_dto.dart';
import 'package:service_reminder/features/service_catalog/data/mappers/service_offering_mapper.dart';
import 'package:service_reminder/features/service_catalog/domain/entities/service_offering.dart';

class ServiceOfferingsRemoteDataSourceImpl
    implements ServiceOfferingsRemoteDataSource {
  final SupabaseClient _client;
  const ServiceOfferingsRemoteDataSourceImpl(this._client);

  String get _uid => _client.auth.currentUser!.id;

  @override
  Future<List<ServiceOffering>> getAll() async {
    try {
      final response = await _client
          .from(DbTables.services)
          .select()
          .eq('technician_id', _uid)
          .order('created_at', ascending: false);
      return ServiceOfferingMapper.fromJsonList(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, code: e.code);
    }
  }

  @override
  Future<ServiceOffering> create({
    required String name,
    String? description,
    double? defaultPrice,
  }) async {
    try {
      final dto = ServiceOfferingDto(
        id: '',
        technicianId: _uid,
        name: name,
        description: description,
        defaultPrice: defaultPrice,
        createdAt: DateTime.now(),
      );
      final response = await _client
          .from(DbTables.services)
          .insert(dto.toInsertJson(_uid))
          .select()
          .single();
      return ServiceOfferingMapper.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, code: e.code);
    }
  }

  @override
  Future<ServiceOffering> update({
    required String id,
    required String name,
    String? description,
    double? defaultPrice,
  }) async {
    try {
      final dto = ServiceOfferingDto(
        id: id,
        technicianId: _uid,
        name: name,
        description: description,
        defaultPrice: defaultPrice,
        createdAt: DateTime.now(),
      );
      final response = await _client
          .from(DbTables.services)
          .update(dto.toUpdateJson())
          .eq('id', id)
          .eq('technician_id', _uid)
          .select()
          .single();
      return ServiceOfferingMapper.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, code: e.code);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _client
          .from(DbTables.services)
          .delete()
          .eq('id', id)
          .eq('technician_id', _uid);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, code: e.code);
    }
  }
}
