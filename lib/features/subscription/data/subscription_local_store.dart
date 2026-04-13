import 'package:shared_preferences/shared_preferences.dart';

import 'package:service_reminder/features/subscription/domain/billing_plan.dart';
import 'package:service_reminder/features/subscription/domain/subscription_state.dart';

/// Persists trial start and selected plan per Supabase user id (device-local).
abstract final class SubscriptionLocalStore {
  static String _trialKey(String userId) => 'billing_trial_start_$userId';
  static String _planKey(String userId) => 'billing_plan_$userId';

  static Future<SubscriptionState> loadForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final trialKey = _trialKey(userId);
    var trialIso = prefs.getString(trialKey);
    if (trialIso == null || trialIso.isEmpty) {
      trialIso = DateTime.now().toUtc().toIso8601String();
      await prefs.setString(trialKey, trialIso);
    }
    final trialStarted = DateTime.parse(trialIso).toUtc();
    final planRaw = prefs.getString(_planKey(userId));
    final plan = BillingPlanX.fromStorage(planRaw);

    return SubscriptionState(
      userId: userId,
      selectedPlan: plan,
      trialStartedAtUtc: trialStarted,
      isAuthenticated: true,
    );
  }

  static Future<void> saveSelectedPlan(String userId, BillingPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey(userId), plan.storageValue);
  }
}
