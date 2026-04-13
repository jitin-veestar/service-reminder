import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:service_reminder/app/router/route_names.dart';
import 'package:service_reminder/core/locale/app_locale_provider.dart';
import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/l10n/app_localizations.dart';
import 'package:service_reminder/core/services/notifications/notification_service.dart';
import 'package:service_reminder/features/auth/presentation/providers/auth_controller.dart';
import 'package:service_reminder/features/auth/presentation/providers/auth_state.dart';
import 'package:service_reminder/features/subscription/presentation/pages/subscription_plans_page.dart';
import 'package:service_reminder/features/subscription/presentation/providers/subscription_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final appLocale = ref.watch(appLocaleProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '—';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    final isLoading = ref.watch(authControllerProvider) is LoginLoading;
    final subAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.account, style: AppTypography.heading2),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Avatar + email card ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    initial,
                    style: AppTypography.heading2.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.signedInAs,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Subscription ─────────────────────────────────────────────────
          _SectionLabel(l10n.subscriptionAndBilling),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: subAsync.when(
                    data: (s) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.statusHeadline,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (s.isTrialExpired) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.trialEndedHint,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.warning,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                    error: (_, __) => Text(
                      l10n.couldNotLoadPlan,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _AccountTile(
                  icon: Icons.workspace_premium_outlined,
                  label: l10n.plansAndPricing,
                  subtitle: l10n.plansSubtitle,
                  color: AppColors.primary,
                  isLoading: false,
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const SubscriptionPlansPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Business section ─────────────────────────────────────────────
          _SectionLabel(l10n.business),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _AccountTile(
                  icon: Icons.people_outline_rounded,
                  label: l10n.customers,
                  subtitle: l10n.customersSubtitle,
                  color: AppColors.textPrimary,
                  isLoading: false,
                  onTap: () => context.push(RouteNames.customers),
                ),
                const Divider(height: 1, indent: 50, color: AppColors.divider),
                _AccountTile(
                  icon: Icons.inventory_2_outlined,
                  label: l10n.packages,
                  subtitle: l10n.packagesSubtitle,
                  color: AppColors.textPrimary,
                  isLoading: false,
                  onTap: () => context.push(RouteNames.serviceOfferings),
                ),
                const Divider(height: 1, indent: 50, color: AppColors.divider),
                _AccountTile(
                  icon: Icons.bar_chart_rounded,
                  label: l10n.reports,
                  subtitle: l10n.reportsSubtitle,
                  color: AppColors.textPrimary,
                  isLoading: false,
                  onTap: () => context.push(RouteNames.reports),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Notifications section ────────────────────────────────────────
          _SectionLabel(l10n.notifications),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _AccountTile(
                  icon: Icons.notifications_active_outlined,
                  label: l10n.enableNotifications,
                  subtitle: l10n.enableNotificationsSubtitle,
                  color: AppColors.primary,
                  isLoading: false,
                  onTap: () => _enableNotifications(context),
                ),
                const Divider(height: 1, indent: 50, color: AppColors.divider),
                _AccountTile(
                  icon: Icons.wb_sunny_outlined,
                  label: l10n.morningBriefing,
                  subtitle: l10n.morningBriefingSubtitle,
                  color: AppColors.primary,
                  isLoading: false,
                  onTap: () => _scheduleMorningBriefing(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _SectionLabel(l10n.language),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: _AccountTile(
              icon: Icons.language_rounded,
              label: l10n.language,
              subtitle: appLocale.languageCode == 'hi'
                  ? l10n.languageHindi
                  : l10n.languageEnglish,
              color: AppColors.textPrimary,
              isLoading: false,
              onTap: () => _pickLanguage(context, ref),
            ),
          ),

          const SizedBox(height: 24),

          // ── Account section ──────────────────────────────────────────────
          _SectionLabel(l10n.account),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: _AccountTile(
              icon: Icons.logout_rounded,
              label: l10n.signOut,
              color: AppColors.error,
              isLoading: isLoading,
              onTap: () => _confirmSignOut(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enableNotifications(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await NotificationService.requestPermission();
    await NotificationService.scheduleMorningBriefing();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.notificationsEnabledSnack),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _scheduleMorningBriefing(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await NotificationService.scheduleMorningBriefing();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.morningBriefingScheduledSnack),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Consumer(
        builder: (_, sheetRef, __) {
          final loc = sheetRef.watch(appLocaleProvider);
          final sheetL10n = AppLocalizations.of(sheetContext)!;
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    sheetL10n.languageTitle,
                    style: AppTypography.heading2,
                  ),
                ),
                RadioListTile<Locale>(
                  title: Text(sheetL10n.languageEnglish),
                  value: const Locale('en'),
                  groupValue: loc,
                  onChanged: (v) async {
                    if (v != null) {
                      await sheetRef
                          .read(appLocaleProvider.notifier)
                          .setLocale(v);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    }
                  },
                ),
                RadioListTile<Locale>(
                  title: Text(sheetL10n.languageHindi),
                  value: const Locale('hi'),
                  groupValue: loc,
                  onChanged: (v) async {
                    if (v != null) {
                      await sheetRef
                          .read(appLocaleProvider.notifier)
                          .setLocale(v);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOutConfirmTitle),
        content: Text(l10n.signOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.caption.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  const _AccountTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.body.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: color.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }
}
