import 'package:service_reminder/features/subscription/domain/billing_plan.dart';

/// Local subscription snapshot (trial + selected paid plan).
class SubscriptionState {
  static const int trialDays = 90;

  final String? userId;
  final BillingPlan selectedPlan;
  final DateTime trialStartedAtUtc;
  final bool isAuthenticated;

  const SubscriptionState({
    required this.userId,
    required this.selectedPlan,
    required this.trialStartedAtUtc,
    required this.isAuthenticated,
  });

  factory SubscriptionState.guest() => SubscriptionState(
        userId: null,
        selectedPlan: BillingPlan.free,
        trialStartedAtUtc: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        isAuthenticated: false,
      );

  /// Build from auth.users.user_metadata written by the admin panel.
  /// Falls back to safe defaults if fields are missing (legacy accounts).
  factory SubscriptionState.fromUserMetadata(
    String userId,
    Map<String, dynamic> meta,
  ) {
    final plan = BillingPlanX.fromStorage(meta['plan'] as String?);
    final trialRaw = meta['trial_started_at'] as String?;
    final trialStarted = trialRaw != null && trialRaw.isNotEmpty
        ? DateTime.parse(trialRaw).toUtc()
        : DateTime.now().toUtc();
    return SubscriptionState(
      userId: userId,
      selectedPlan: plan,
      trialStartedAtUtc: trialStarted,
      isAuthenticated: true,
    );
  }

  DateTime get _trialEndUtc =>
      trialStartedAtUtc.add(const Duration(days: trialDays));

  /// Active only while still on [BillingPlan.free] and within the trial window.
  bool get isTrialActive {
    if (!isAuthenticated || selectedPlan != BillingPlan.free) return false;
    return DateTime.now().toUtc().isBefore(_trialEndUtc);
  }

  int get trialDaysRemaining {
    if (!isTrialActive) return 0;
    final end = _trialEndUtc.toLocal();
    final diff = end.difference(DateTime.now());
    return diff.inDays.clamp(0, trialDays);
  }

  /// WhatsApp (reminder + completion) and PDF receipt — [pro499] or active free trial.
  bool get hasWhatsAppAndPdfEntitlement =>
      selectedPlan == BillingPlan.pro499 ||
      (selectedPlan == BillingPlan.free && isTrialActive);

  bool get isTrialExpired =>
      isAuthenticated &&
      selectedPlan == BillingPlan.free &&
      !isTrialActive;

  String get statusHeadline {
    if (!isAuthenticated) return 'Sign in to manage your plan';
    if (selectedPlan == BillingPlan.pro499) {
      return 'Business · ${BillingPlan.pro499.priceLabel}';
    }
    if (selectedPlan == BillingPlan.pro299) {
      return 'Professional · ${BillingPlan.pro299.priceLabel}';
    }
    if (isTrialActive) {
      final d = trialDaysRemaining;
      return 'Free trial · $d days left';
    }
    return 'Trial ended — choose a plan to continue premium tools';
  }
}
