import 'package:service_reminder/features/service_catalog/domain/entities/service_offering.dart';

abstract interface class ServiceOfferingsRemoteDataSource {
  Future<List<ServiceOffering>> getAll();
  Future<ServiceOffering> create({
    required String name,
    String? description,
    double? defaultPrice,
  });
  Future<ServiceOffering> update({
    required String id,
    required String name,
    String? description,
    double? defaultPrice,
  });
  Future<void> delete(String id);
}
