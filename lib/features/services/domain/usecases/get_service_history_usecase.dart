import 'package:service_reminder/features/services/domain/entities/service_record.dart';
import 'package:service_reminder/features/services/domain/repositories/services_repository.dart';

class GetServiceHistoryUseCase {
  final ServicesRepository _repository;
  const GetServiceHistoryUseCase(this._repository);

  Future<List<ServiceRecord>> call(String customerId) =>
      _repository.getByCustomerId(customerId);
}
