import 'package:service_reminder/features/customers/domain/entities/customer.dart';
import 'package:service_reminder/features/customers/domain/repositories/customers_repository.dart';

class GetCustomerByIdUseCase {
  final CustomersRepository _repository;
  const GetCustomerByIdUseCase(this._repository);

  Future<Customer> call(String id) => _repository.getById(id);
}
