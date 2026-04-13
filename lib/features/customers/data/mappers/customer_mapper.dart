import 'package:service_reminder/features/customers/data/dtos/customer_dto.dart';
import 'package:service_reminder/features/customers/domain/entities/customer.dart';

abstract final class CustomerMapper {
  static Customer fromJson(Map<String, dynamic> json) =>
      CustomerDto.fromJson(json).toDomain();

  static List<Customer> fromJsonList(List<dynamic> json) =>
      json.map((e) => fromJson(e as Map<String, dynamic>)).toList();
}
