abstract final class DbTables {
  static const customers = 'customers';

  /// RO visit records (checklist, dates, amounts) — was often named `services`.
  static const serviceHistory = 'service_history';

  /// Technician-defined offerings (name, description, default price).
  static const services = 'services';

  /// Scheduled service assignments (customer + service + date/time + status).
  static const assignedServices = 'assigned_services';
}
