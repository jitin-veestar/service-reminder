import 'package:service_reminder/features/service_catalog/data/dtos/service_offering_dto.dart';
import 'package:service_reminder/features/service_catalog/domain/entities/service_offering.dart';

abstract final class ServiceOfferingMapper {
  static ServiceOffering fromJson(Map<String, dynamic> json) =>
      ServiceOfferingDto.fromJson(json).toDomain();

  static List<ServiceOffering> fromJsonList(List<dynamic> json) =>
      json.map((e) => fromJson(e as Map<String, dynamic>)).toList();
}
