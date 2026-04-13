import 'package:service_reminder/features/customers/domain/entities/customer.dart';
import 'package:service_reminder/features/customers/domain/repositories/customers_repository.dart';

class CreateCustomerUseCase {
  final CustomersRepository _repository;
  const CreateCustomerUseCase(this._repository);

  Future<Customer> call({
    required String name,
    String? phone,
    String? address,
    required int serviceFrequencyDays,
    required CustomerType customerType,
  }) =>
      _repository.create(
        name: name,
        phone: phone,
        address: address,
        serviceFrequencyDays: serviceFrequencyDays,
        customerType: customerType,
      );
}
