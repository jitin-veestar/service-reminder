import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:service_reminder/core/services/supabase/supabase_client_provider.dart';
import 'package:service_reminder/features/service_catalog/data/datasources/service_offerings_remote_datasource_impl.dart';
import 'package:service_reminder/features/service_catalog/data/repositories/service_offerings_repository_impl.dart';
import 'package:service_reminder/features/service_catalog/domain/entities/service_offering.dart';
import 'package:service_reminder/features/service_catalog/domain/repositories/service_offerings_repository.dart';

final serviceOfferingsRepositoryProvider =
    Provider<ServiceOfferingsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ServiceOfferingsRepositoryImpl(
    ServiceOfferingsRemoteDataSourceImpl(client),
  );
});

final serviceOfferingsListProvider =
    AsyncNotifierProvider<ServiceOfferingsListNotifier, List<ServiceOffering>>(
  ServiceOfferingsListNotifier.new,
);

class ServiceOfferingsListNotifier
    extends AsyncNotifier<List<ServiceOffering>> {
  @override
  Future<List<ServiceOffering>> build() =>
      ref.read(serviceOfferingsRepositoryProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(serviceOfferingsRepositoryProvider).getAll(),
    );
  }

  Future<void> deleteOffering(String id) async {
    await ref.read(serviceOfferingsRepositoryProvider).delete(id);
    await refresh();
  }
}
