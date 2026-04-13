/// A customer who is due or overdue for their next RO service.
class Reminder {
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final DateTime nextServiceAt;
  final DateTime lastServiceAt;

  const Reminder({
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.nextServiceAt,
    required this.lastServiceAt,
  });
}
