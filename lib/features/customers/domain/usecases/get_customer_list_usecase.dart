import 'package:service_reminder/features/customers/domain/entities/customer.dart';
import 'package:service_reminder/features/customers/domain/repositories/customers_repository.dart';

class GetCustomerListUseCase {
  final CustomersRepository _repository;
  const GetCustomerListUseCase(this._repository);

  Future<List<Customer>> call() => _repository.getAll();
}
