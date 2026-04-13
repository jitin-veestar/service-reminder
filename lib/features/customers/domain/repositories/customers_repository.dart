import 'package:service_reminder/features/customers/domain/entities/customer.dart';

abstract interface class CustomersRepository {
  Future<List<Customer>> getAll();
  Future<Customer> getById(String id);
  Future<Customer> create({
    required String name,
    String? phone,
    String? address,
    required int serviceFrequencyDays,
    required CustomerType customerType,
  });

  Future<Customer> update({
    required String id,
    required String name,
    String? phone,
    String? address,
    required int serviceFrequencyDays,
    required CustomerType customerType,
  });
}
