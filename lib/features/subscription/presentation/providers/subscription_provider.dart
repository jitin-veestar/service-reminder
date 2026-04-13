import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:service_reminder/features/subscription/data/subscription_local_store.dart';
import 'package:service_reminder/features/subscription/domain/billing_plan.dart';
import 'package:service_reminder/features/subscription/domain/subscription_state.dart';

/// Fires when auth session changes so subscription reloads per user.
final authUserIdProvider = StreamProvider<String?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map(
    (_) => Supabase.instance.client.auth.currentUser?.id,
  );
});

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionState>(
  SubscriptionNotifier.new,
);

class SubscriptionNotifier extends AsyncNotifier<SubscriptionState> {
  @override
  Future<SubscriptionState> build() async {
    ref.watch(authUserIdProvider);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.id.isEmpty) {
      return SubscriptionState.guest();
    }

    // Server-authoritative: read from auth.users.user_metadata (written by admin panel).
    final meta = user.userMetadata ?? {};
    if (meta['plan'] != null) {
      return SubscriptionState.fromUserMetadata(user.id, meta);
    }

    // Fallback: local store for existing users that pre-date the metadata migration.
    return SubscriptionLocalStore.loadForUser(user.id);
  }

  /// Select a plan — writes to Supabase user_metadata (admin-visible) and
  /// keeps the local cache in sync as an offline fallback.
  Future<void> selectPlan(BillingPlan plan) async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) return;

    // Persist to server so admin panel reflects the change immediately.
    await client.auth.updateUser(
      UserAttributes(data: {'plan': plan.storageValue}),
    );

    // Mirror locally for offline resilience.
    await SubscriptionLocalStore.saveSelectedPlan(uid, plan);

    // Refresh session so userMetadata on currentUser is up-to-date.
    await client.auth.refreshSession();

    state = AsyncData(await build());
  }

  /// Force-reload from server (e.g. after admin changes the plan remotely).
  Future<void> reload() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      state = AsyncData(SubscriptionState.guest());
      return;
    }
    // Fetch fresh metadata from Supabase before rebuilding.
    await client.auth.refreshSession();
    state = AsyncData(await build());
  }
}
