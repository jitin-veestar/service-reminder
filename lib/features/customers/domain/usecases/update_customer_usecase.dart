import 'package:service_reminder/features/customers/domain/entities/customer.dart';
import 'package:service_reminder/features/customers/domain/repositories/customers_repository.dart';

class UpdateCustomerUseCase {
  final CustomersRepository _repository;
  const UpdateCustomerUseCase(this._repository);

  Future<Customer> call({
    required String id,
    required String name,
    String? phone,
    String? address,
    required int serviceFrequencyDays,
    required CustomerType customerType,
  }) =>
      _repository.update(
        id: id,
        name: name,
        phone: phone,
        address: address,
        serviceFrequencyDays: serviceFrequencyDays,
        customerType: customerType,
      );
}
