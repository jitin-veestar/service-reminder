import 'package:service_reminder/features/service_catalog/data/datasources/service_offerings_remote_datasource.dart';
import 'package:service_reminder/features/service_catalog/domain/entities/service_offering.dart';
import 'package:service_reminder/features/service_catalog/domain/repositories/service_offerings_repository.dart';

class ServiceOfferingsRepositoryImpl implements ServiceOfferingsRepository {
  final ServiceOfferingsRemoteDataSource _remote;
  const ServiceOfferingsRepositoryImpl(this._remote);

  @override
  Future<List<ServiceOffering>> getAll() => _remote.getAll();

  @override
  Future<ServiceOffering> create({
    required String name,
    String? description,
    double? defaultPrice,
  }) =>
      _remote.create(
        name: name,
        description: description,
        defaultPrice: defaultPrice,
      );

  @override
  Future<ServiceOffering> update({
    required String id,
    required String name,
    String? description,
    double? defaultPrice,
  }) =>
      _remote.update(
        id: id,
        name: name,
        description: description,
        defaultPrice: defaultPrice,
      );

  @override
  Future<void> delete(String id) => _remote.delete(id);
}
