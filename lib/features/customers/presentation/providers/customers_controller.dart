import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:service_reminder/core/services/supabase/supabase_client_provider.dart';
import 'package:service_reminder/features/customers/data/datasources/customers_remote_datasource_impl.dart';
import 'package:service_reminder/features/customers/data/repositories/customers_repository_impl.dart';
import 'package:service_reminder/features/customers/domain/entities/customer.dart';
import 'package:service_reminder/features/customers/domain/repositories/customers_repository.dart';
import 'package:service_reminder/features/customers/domain/usecases/get_customer_by_id_usecase.dart';
import 'package:service_reminder/features/customers/domain/usecases/get_customer_list_usecase.dart';

// ── Dependency providers ──────────────────────────────────────────────────────

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CustomersRepositoryImpl(CustomersRemoteDataSourceImpl(client));
});

final getCustomerListUseCaseProvider = Provider<GetCustomerListUseCase>((ref) {
  return GetCustomerListUseCase(ref.watch(customersRepositoryProvider));
});

final getCustomerByIdUseCaseProvider = Provider<GetCustomerByIdUseCase>((ref) {
  return GetCustomerByIdUseCase(ref.watch(customersRepositoryProvider));
});

// ── Customers list ────────────────────────────────────────────────────────────

final customersListProvider =
    AsyncNotifierProvider<CustomersListNotifier, List<Customer>>(
  CustomersListNotifier.new,
);

class CustomersListNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() => _fetch();

  Future<List<Customer>> _fetch() =>
      ref.read(getCustomerListUseCaseProvider).call();

  /// Call this after adding a customer to refresh the list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

// ── Single customer by ID ─────────────────────────────────────────────────────

final customerByIdProvider =
    FutureProvider.family<Customer, String>((ref, id) async {
  return ref.read(getCustomerByIdUseCaseProvider).call(id);
});
