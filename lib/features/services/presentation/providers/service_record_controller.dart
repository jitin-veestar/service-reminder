import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:service_reminder/core/utils/date_time_utils.dart';
import 'package:service_reminder/features/services/domain/usecases/create_service_record_usecase.dart';
import 'package:service_reminder/features/services/presentation/providers/service_history_provider.dart';

// ── Dependency provider ───────────────────────────────────────────────────────

final createServiceRecordUseCaseProvider =
    Provider<CreateServiceRecordUseCase>((ref) {
  return CreateServiceRecordUseCase(ref.watch(servicesRepositoryProvider));
});

// ── Form controller (scoped per customer) ────────────────────────────────────

final serviceRecordControllerProvider = StateNotifierProvider.autoDispose
    .family<ServiceRecordController, AsyncValue<void>, String>(
  (ref, customerId) => ServiceRecordController(
    customerId: customerId,
    createUseCase: ref.watch(createServiceRecordUseCaseProvider),
    onSuccess: () => ref.invalidate(serviceHistoryProvider(customerId)),
  ),
);

class ServiceRecordController extends StateNotifier<AsyncValue<void>> {
  final String _customerId;
  final CreateServiceRecordUseCase _createUseCase;
  final void Function() _onSuccess;

  ServiceRecordController({
    required String customerId,
    required CreateServiceRecordUseCase createUseCase,
    required void Function() onSuccess,
  })  : _customerId = customerId,
        _createUseCase = createUseCase,
        _onSuccess = onSuccess,
        super(const AsyncData(null));

  Future<bool> submit({
    required DateTime servicedAt,
    String? notes,
    required bool filterChanged,
    required bool membraneChecked,
    required bool cleaningDone,
    required bool leakageFixed,
    required double amountCharged,
    String? catalogServiceId,
    String? audioStoragePath,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _createUseCase(
        customerId: _customerId,
        servicedAt: servicedAt,
        nextServiceAt: DateTimeUtils.nextServiceDate(servicedAt),
        notes: notes,
        filterChanged: filterChanged,
        membraneChecked: membraneChecked,
        cleaningDone: cleaningDone,
        leakageFixed: leakageFixed,
        amountCharged: amountCharged,
        catalogServiceId: catalogServiceId,
        audioStoragePath: audioStoragePath,
      ),
    );
    if (state is AsyncData) {
      _onSuccess();
      return true;
    }
    return false;
  }
}
