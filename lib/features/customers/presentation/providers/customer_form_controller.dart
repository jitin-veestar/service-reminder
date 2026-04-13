import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:service_reminder/features/customers/domain/entities/customer.dart';
import 'package:service_reminder/features/customers/domain/usecases/create_customer_usecase.dart';
import 'package:service_reminder/features/customers/domain/usecases/update_customer_usecase.dart';
import 'package:service_reminder/features/customers/presentation/providers/customers_controller.dart';
import 'package:service_reminder/features/services/presentation/providers/service_history_provider.dart';

// ── Dependency providers ──────────────────────────────────────────────────────

final createCustomerUseCaseProvider = Provider<CreateCustomerUseCase>((ref) {
  return CreateCustomerUseCase(ref.watch(customersRepositoryProvider));
});

final updateCustomerUseCaseProvider = Provider<UpdateCustomerUseCase>((ref) {
  return UpdateCustomerUseCase(ref.watch(customersRepositoryProvider));
});

// ── Form controller (null id = create, non-null = edit) ───────────────────────

final customerFormControllerProvider = StateNotifierProvider.autoDispose
    .family<CustomerFormController, AsyncValue<void>, String?>(
  (ref, editingCustomerId) {
    return CustomerFormController(
      editingCustomerId: editingCustomerId,
      createCustomer: ref.watch(createCustomerUseCaseProvider),
      updateCustomer: ref.watch(updateCustomerUseCaseProvider),
      onSuccess: () async {
        await ref.read(customersListProvider.notifier).refresh();
        final id = editingCustomerId;
        if (id != null) {
          ref.invalidate(customerByIdProvider(id));
          ref.invalidate(serviceHistoryProvider(id));
        }
      },
    );
  },
);

class CustomerFormController extends StateNotifier<AsyncValue<void>> {
  final String? editingCustomerId;
  final CreateCustomerUseCase _createCustomer;
  final UpdateCustomerUseCase _updateCustomer;
  final Future<void> Function() _onSuccess;

  CustomerFormController({
    required this.editingCustomerId,
    required CreateCustomerUseCase createCustomer,
    required UpdateCustomerUseCase updateCustomer,
    required Future<void> Function() onSuccess,
  })  : _createCustomer = createCustomer,
        _updateCustomer = updateCustomer,
        _onSuccess = onSuccess,
        super(const AsyncData(null));

  Future<Customer?> submit({
    required String name,
    String? phone,
    String? address,
    required int serviceFrequencyDays,
    required CustomerType customerType,
  }) async {
    state = const AsyncLoading();
    final AsyncValue<Customer> result;
    final id = editingCustomerId;
    if (id != null) {
      result = await AsyncValue.guard(
        () => _updateCustomer(
          id: id,
          name: name,
          phone: phone,
          address: address,
          serviceFrequencyDays: serviceFrequencyDays,
          customerType: customerType,
        ),
      );
    } else {
      result = await AsyncValue.guard(
        () => _createCustomer(
          name: name,
          phone: phone,
          address: address,
          serviceFrequencyDays: serviceFrequencyDays,
          customerType: customerType,
        ),
      );
    }

    state = result.whenData((_) {});

    if (result.hasValue) {
      await _onSuccess();
      return result.value;
    }
    return null;
  }
}
