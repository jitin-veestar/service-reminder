import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/features/subscription/domain/billing_plan.dart';
import 'package:service_reminder/features/subscription/domain/subscription_state.dart';
import 'package:service_reminder/features/subscription/presentation/providers/subscription_provider.dart';

class SubscriptionPlansPage extends ConsumerWidget {
  const SubscriptionPlansPage({super.key});

  static const _coreFeatures = [
    'Dashboard & visit management',
    'Customers, service catalog & packages',
    'Service history & voice notes',
    'Local visit & morning notifications',
    'Reports & analytics',
    'Maps & quick call from visit cards',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subscriptionProvider);
    final current = subAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Plans & billing', style: AppTypography.heading2),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Current status banner ──────────────────────────────────────
          if (current != null && current.isAuthenticated) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current plan',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    current.statusHeadline,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  if (current.isTrialExpired) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Your 3-month trial has ended. Choose a plan below to continue '
                      'using WhatsApp automation and PDF receipts.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Free trial ─────────────────────────────────────────────────
          _PlanCard(
            title: 'Free trial',
            price: '₹0 · 3 months',
            highlight: current?.isTrialActive == true,
            selected: current?.selectedPlan == BillingPlan.free,
            badge: current?.isTrialActive == true ? 'Active' : null,
            badgeColor: AppColors.success,
            bullets: const [
              '✓ Full app — all features included',
              '✓ WhatsApp automation & PDF receipts',
              '✓ No payment required during trial',
              '✗ Expires after 3 months from first sign-in',
            ],
            footnote: 'After your trial, choose ₹299 or ₹499 to continue.',
            buttonLabel: _freePlanButtonLabel(current),
            buttonEnabled: _freePlanEnabled(current),
            isPrimary: false,
            onPressed: _freePlanOnPressed(context, ref, current),
          ),
          const SizedBox(height: 12),

          // ── ₹299 plan ──────────────────────────────────────────────────
          _PlanCard(
            title: 'Professional',
            price: '₹299 / month',
            highlight: false,
            selected: current?.selectedPlan == BillingPlan.pro299,
            bullets: [
              ..._coreFeatures.map((e) => '✓ $e'),
              '✗ WhatsApp reminders & completion messages',
              '✗ PDF receipt / invoice sharing',
            ],
            footnote:
                'Ideal if you prefer to contact customers manually.',
            buttonLabel: current?.selectedPlan == BillingPlan.pro299
                ? 'Current plan'
                : 'Choose ₹299 plan',
            buttonEnabled: current?.selectedPlan != BillingPlan.pro299,
            isPrimary: true,
            onPressed: current?.selectedPlan == BillingPlan.pro299
                ? null
                : () => _subscribe(context, ref, BillingPlan.pro299),
          ),
          const SizedBox(height: 12),

          // ── ₹499 plan ──────────────────────────────────────────────────
          _PlanCard(
            title: 'Business',
            price: '₹499 / month',
            highlight: true,
            selected: current?.selectedPlan == BillingPlan.pro499,
            badge: 'Most popular',
            badgeColor: AppColors.primary,
            bullets: [
              ..._coreFeatures.map((e) => '✓ $e'),
              '✓ WhatsApp visit reminders from the card',
              '✓ WhatsApp message after service completion',
              '✓ PDF receipt — share via WhatsApp or any app',
            ],
            footnote: 'Everything included. Best for technicians who use WhatsApp.',
            buttonLabel: current?.selectedPlan == BillingPlan.pro499
                ? 'Current plan'
                : 'Choose ₹499 plan',
            buttonEnabled: current?.selectedPlan != BillingPlan.pro499,
            isPrimary: true,
            accent: AppColors.primary,
            onPressed: current?.selectedPlan == BillingPlan.pro499
                ? null
                : () => _subscribe(context, ref, BillingPlan.pro499),
          ),

          const SizedBox(height: 24),
          // ── Payment note ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Plan choice only unlocks features in this app. Apple and '
                    'Google in-app purchase is not connected — the stores do not '
                    'charge for these plans. Any future paid subscription will '
                    'follow App Store / Play billing rules when enabled.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _freePlanButtonLabel(SubscriptionState? s) {
    if (s == null || !s.isAuthenticated) return 'Sign in required';
    if (s.selectedPlan != BillingPlan.free) return 'Switch to free trial';
    if (s.isTrialActive) {
      return 'Free trial — ${s.trialDaysRemaining} days left';
    }
    return 'Trial ended';
  }

  bool _freePlanEnabled(SubscriptionState? s) {
    if (s == null || !s.isAuthenticated) return false;
    if (s.selectedPlan == BillingPlan.free) return false;
    return true;
  }

  VoidCallback? _freePlanOnPressed(
    BuildContext context,
    WidgetRef ref,
    SubscriptionState? s,
  ) {
    if (!_freePlanEnabled(s)) return null;
    return () => _subscribe(context, ref, BillingPlan.free);
  }

  Future<void> _subscribe(
    BuildContext context,
    WidgetRef ref,
    BillingPlan plan,
  ) async {
    final label = switch (plan) {
      BillingPlan.free => 'Free trial',
      BillingPlan.pro299 => 'Professional — ₹299/mo',
      BillingPlan.pro499 => 'Business — ₹499/mo',
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm plan'),
        content: Text(
          'Activate the $label plan?\n\n'
          'This only updates feature access on this device. No payment is '
          'processed through the App Store or Google Play.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(subscriptionProvider.notifier).selectPlan(plan);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label activated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ── Plan card ──────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final bool highlight;
  final bool selected;
  final String? badge;
  final Color? badgeColor;
  final List<String> bullets;
  final String footnote;
  final String buttonLabel;
  final bool buttonEnabled;
  final bool isPrimary;
  final Color? accent;
  final VoidCallback? onPressed;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.highlight,
    required this.selected,
    this.badge,
    this.badgeColor,
    required this.bullets,
    required this.footnote,
    required this.buttonLabel,
    required this.buttonEnabled,
    required this.isPrimary,
    this.accent,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = highlight
        ? AppColors.primary
        : (selected ? AppColors.primaryLight : AppColors.border);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: selected || highlight ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title row
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.heading3.copyWith(fontSize: 17),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? AppColors.primary)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge!,
                      style: AppTypography.caption.copyWith(
                        color: badgeColor ?? AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
                if (selected && badge == null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Current',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w700,
                color: accent ?? AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...bullets.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  line,
                  style: AppTypography.bodySmall.copyWith(
                    color: line.startsWith('✗')
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              footnote,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 14),
            if (isPrimary)
              FilledButton(
                onPressed: buttonEnabled ? onPressed : null,
                style: FilledButton.styleFrom(
                  backgroundColor: accent ?? AppColors.primary,
                ),
                child: Text(buttonLabel),
              )
            else
              OutlinedButton(
                onPressed: buttonEnabled ? onPressed : null,
                child: Text(buttonLabel),
              ),
          ],
        ),
      ),
    );
  }
}
