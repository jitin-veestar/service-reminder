import 'package:service_reminder/features/services/domain/entities/service_record.dart';

abstract interface class ServiceHistoryRemoteDataSource {
  Future<List<ServiceRecord>> getByCustomerId(String customerId);
}
