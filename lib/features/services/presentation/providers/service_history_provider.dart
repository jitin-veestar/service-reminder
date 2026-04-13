import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:service_reminder/core/services/supabase/supabase_client_provider.dart';
import 'package:service_reminder/features/services/data/datasources/service_history_remote_datasource_impl.dart';
import 'package:service_reminder/features/services/data/datasources/services_remote_datasource_impl.dart';
import 'package:service_reminder/features/services/data/repositories/services_repository_impl.dart';
import 'package:service_reminder/features/services/domain/entities/service_record.dart';
import 'package:service_reminder/features/services/domain/repositories/services_repository.dart';
import 'package:service_reminder/features/services/domain/usecases/get_service_history_usecase.dart';

// ── Dependency providers ──────────────────────────────────────────────────────

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ServicesRepositoryImpl(
    ServicesRemoteDataSourceImpl(client),
    ServiceHistoryRemoteDataSourceImpl(client),
  );
});

final getServiceHistoryUseCaseProvider =
    Provider<GetServiceHistoryUseCase>((ref) {
  return GetServiceHistoryUseCase(ref.watch(servicesRepositoryProvider));
});

// ── Service history (per customer) ───────────────────────────────────────────

final serviceHistoryProvider =
    FutureProvider.family<List<ServiceRecord>, String>((ref, customerId) async {
  return ref.read(getServiceHistoryUseCaseProvider).call(customerId);
});
