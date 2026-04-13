enum CustomerType { oneTime, amc }

class Customer {
  final String id;
  final String technicianId;
  final String name;
  final String? phone;
  final String? address;
  final DateTime createdAt;
  final int serviceFrequencyDays;
  final CustomerType customerType;

  /// From latest `service_history` row for this customer (list view only); null if none.
  final DateTime? nextServiceAt;

  const Customer({
    required this.id,
    required this.technicianId,
    required this.name,
    this.phone,
    this.address,
    required this.createdAt,
    this.serviceFrequencyDays = 120,
    this.customerType = CustomerType.oneTime,
    this.nextServiceAt,
  });

  Customer withNextService(DateTime? next) => Customer(
        id: id,
        technicianId: technicianId,
        name: name,
        phone: phone,
        address: address,
        createdAt: createdAt,
        serviceFrequencyDays: serviceFrequencyDays,
        customerType: customerType,
        nextServiceAt: next,
      );
}
