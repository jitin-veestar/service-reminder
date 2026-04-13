import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:service_reminder/core/services/supabase/supabase_client_provider.dart';
import 'package:service_reminder/features/reminders/data/datasources/reminders_remote_datasource_impl.dart';
import 'package:service_reminder/features/reminders/data/repositories/reminders_repository_impl.dart';
import 'package:service_reminder/features/reminders/domain/entities/reminder.dart';
import 'package:service_reminder/features/reminders/domain/repositories/reminders_repository.dart';
import 'package:service_reminder/features/reminders/domain/usecases/get_due_reminders_usecase.dart';

// ── Dependency providers ──────────────────────────────────────────────────────

final remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RemindersRepositoryImpl(RemindersRemoteDataSourceImpl(client));
});

final getDueRemindersUseCaseProvider = Provider<GetDueRemindersUseCase>((ref) {
  return GetDueRemindersUseCase(ref.watch(remindersRepositoryProvider));
});

// ── Due reminders list ────────────────────────────────────────────────────────

final dueRemindersProvider =
    AsyncNotifierProvider<DueRemindersNotifier, List<Reminder>>(
  DueRemindersNotifier.new,
);

class DueRemindersNotifier extends AsyncNotifier<List<Reminder>> {
  @override
  Future<List<Reminder>> build() => _fetch();

  Future<List<Reminder>> _fetch() =>
      ref.read(getDueRemindersUseCaseProvider).call();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
