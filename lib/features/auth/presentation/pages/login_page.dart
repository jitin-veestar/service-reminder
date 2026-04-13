import 'package:flutter/material.dart';

import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/features/auth/presentation/widgets/login_form.dart';
import 'package:service_reminder/l10n/app_localizations.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Navigation to dashboard after sign-in is handled by GoRouter's
    // _AuthChangeNotifier, which listens to Supabase auth state changes.
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 72),

              // ── Brand header ────────────────────────────────────────────
              const Icon(
                Icons.water_drop_rounded,
                size: 56,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.appTitle,
                style: AppTypography.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.loginSubtitle,
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // ── Login form ──────────────────────────────────────────────
              const LoginForm(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
