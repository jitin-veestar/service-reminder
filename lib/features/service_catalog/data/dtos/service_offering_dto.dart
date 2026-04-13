import 'package:service_reminder/features/service_catalog/domain/entities/service_offering.dart';

class ServiceOfferingDto {
  final String id;
  final String technicianId;
  final String name;
  final String? description;
  final double? defaultPrice;
  final DateTime createdAt;

  const ServiceOfferingDto({
    required this.id,
    required this.technicianId,
    required this.name,
    this.description,
    this.defaultPrice,
    required this.createdAt,
  });

  factory ServiceOfferingDto.fromJson(Map<String, dynamic> json) {
    return ServiceOfferingDto(
      id: json['id'] as String,
      technicianId: json['technician_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      defaultPrice: (json['default_price'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson(String technicianId) => {
        'technician_id': technicianId,
        'name': name.trim(),
        if (description != null && description!.trim().isNotEmpty)
          'description': description!.trim(),
        if (defaultPrice != null) 'default_price': defaultPrice,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name.trim(),
        'description': description?.trim(),
        'default_price': defaultPrice,
      };

  ServiceOffering toDomain() => ServiceOffering(
        id: id,
        technicianId: technicianId,
        name: name,
        description: description,
        defaultPrice: defaultPrice,
        createdAt: createdAt,
      );
}
