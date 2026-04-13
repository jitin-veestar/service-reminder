abstract final class RouteNames {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const dashboard = '/home/dashboard';
  static const allServices = '/home/services';
  static const profile = '/home/profile';
  // Pushed from Account — not shell tabs
  static const customers = '/customers-list';
  static const reminders = '/home/reminders';
  static const reports = '/reports';
  static const serviceOfferings = '/service-offerings-list';
  static const addCustomer = '/customers/new';
  static const customerDetail = '/customers/:id';
  static const customerServiceHistory = '/customers/:id/history';
  static const editCustomer = '/customers/:id/edit';
  static const addService = '/customers/:id/service/new';
  static const addServiceOffering = '/service-offerings/new';
  static const editServiceOffering = '/service-offerings/:id/edit';
  static const assignService = '/assign-service/new';
  static const suspended = '/suspended';

  // Builders for dynamic segments
  static String customerDetailPath(String id) => '/customers/$id';
  static String customerServiceHistoryPath(String id) => '/customers/$id/history';
  static String customerEditPath(String id) => '/customers/$id/edit';
  static String addServicePath(String customerId) => '/customers/$customerId/service/new';
  static String serviceOfferingEditPath(String id) => '/service-offerings/$id/edit';
}
