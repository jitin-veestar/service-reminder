import 'package:service_reminder/features/customers/data/datasources/customers_remote_datasource.dart';
import 'package:service_reminder/features/customers/domain/entities/customer.dart';
import 'package:service_reminder/features/customers/domain/repositories/customers_repository.dart';

class CustomersRepositoryImpl implements CustomersRepository {
  final CustomersRemoteDataSource _remote;
  const CustomersRepositoryImpl(this._remote);

  @override
  Future<List<Customer>> getAll() => _remote.getAll();

  @override
  Future<Customer> getById(String id) => _remote.getById(id);

  @override
  Future<Customer> create({
    required String name,
    String? phone,
    String? address,
    required int serviceFrequencyDays,
    required CustomerType customerType,
  }) =>
      _remote.create(
        name: name,
        phone: phone,
        address: address,
        serviceFrequencyDays: serviceFrequencyDays,
        customerType: customerType,
      );

  @override
  Future<Customer> update({
    required String id,
    required String name,
    String? phone,
    String? address,
    required int serviceFrequencyDays,
    required CustomerType customerType,
  }) =>
      _remote.update(
        id: id,
        name: name,
        phone: phone,
        address: address,
        serviceFrequencyDays: serviceFrequencyDays,
        customerType: customerType,
      );
}
