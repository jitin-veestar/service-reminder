import 'package:service_reminder/features/services/data/dtos/service_record_dto.dart';
import 'package:service_reminder/features/services/domain/entities/service_record.dart';

abstract final class ServiceRecordMapper {
  static ServiceRecord fromJson(Map<String, dynamic> json) =>
      ServiceRecordDto.fromJson(json).toDomain();

  static List<ServiceRecord> fromJsonList(List<dynamic> json) =>
      json.map((e) => fromJson(e as Map<String, dynamic>)).toList();
}
