class ServiceOffering {
  final String id;
  final String technicianId;
  final String name;
  final String? description;
  final double? defaultPrice;
  final DateTime createdAt;

  const ServiceOffering({
    required this.id,
    required this.technicianId,
    required this.name,
    this.description,
    this.defaultPrice,
    required this.createdAt,
  });
}
