import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:service_reminder/app/router/route_names.dart';
import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/utils/validators.dart';
import 'package:service_reminder/features/auth/presentation/providers/auth_controller.dart';
import 'package:service_reminder/features/auth/presentation/providers/auth_state.dart';
import 'package:service_reminder/shared/widgets/app_text_field.dart';
import 'package:service_reminder/l10n/app_localizations.dart';
import 'package:service_reminder/shared/widgets/primary_button.dart';
import 'package:service_reminder/shared/widgets/skeleton_shimmer.dart';

enum _LoginTab { email, mobile }

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _emailFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _obscurePassword = true;
  _LoginTab _tab = _LoginTab.email;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _submitEmail() {
    if (!_emailFormKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _sendOtp() {
    if (!_phoneFormKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).sendOtp(
          phone: _phoneController.text.trim(),
        );
  }

  void _verifyOtp(String phone) {
    final code = _otpController.text.trim();
    if (code.length != 6) return;
    ref.read(authControllerProvider.notifier).verifyOtp(
          phone: phone,
          token: code,
        );
  }

  void _changeNumber() {
    _otpController.clear();
    ref.read(authControllerProvider.notifier).resetToInitial();
  }

  void _onTabChanged(Set<_LoginTab> selection) {
    setState(() => _tab = selection.single);
    ref.read(authControllerProvider.notifier).resetToInitial();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    ref.read(authControllerProvider.notifier).clearError();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is LoginLoading;

    ref.listen<LoginState>(authControllerProvider, (_, next) {
      if (next is LoginError) _showError(next.message);
    });

    if (isLoading) return const _LoginFormSkeleton();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Tab selector ────────────────────────────────────────────────
        SegmentedButton<_LoginTab>(
          multiSelectionEnabled: false,
          emptySelectionAllowed: false,
          showSelectedIcon: false,
          segments: [
            ButtonSegment<_LoginTab>(
              value: _LoginTab.email,
              label: Text(l10n.email),
              icon: const Icon(Icons.alternate_email_rounded, size: 18),
            ),
            ButtonSegment<_LoginTab>(
              value: _LoginTab.mobile,
              label: Text(l10n.mobileOtp),
              icon: const Icon(Icons.smartphone_rounded, size: 18),
            ),
          ],
          selected: {_tab},
          onSelectionChanged: _onTabChanged,
        ),
        const SizedBox(height: 24),

        // ── Email / password tab ─────────────────────────────────────────
        if (_tab == _LoginTab.email) ...[
          Form(
            key: _emailFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: l10n.email,
                  hint: 'you@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: l10n.password,
                  hint: '••••••••',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  validator: Validators.password,
                  onFieldSubmitted: (_) => _submitEmail(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryButton(label: l10n.signIn, onPressed: _submitEmail),
              ],
            ),
          ),
        ]

        // ── Mobile OTP tab ───────────────────────────────────────────────
        else if (authState is OtpSent) ...[
          _OtpCodeStep(
            l10n: l10n,
            phone: authState.phone,
            controller: _otpController,
            onVerify: () => _verifyOtp(authState.phone),
            onChangeNumber: _changeNumber,
          ),
        ] else ...[
          Form(
            key: _phoneFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: l10n.mobileNumber,
                  hint: '+91 98765 43210',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: Validators.phone,
                  onFieldSubmitted: (_) => _sendOtp(),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.countryCodeHint,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: l10n.sendOtp, onPressed: _sendOtp),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.newHere,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            TextButton(
              onPressed: () => context.push(RouteNames.signup),
              child: Text(l10n.createAccount),
            ),
          ],
        ),
      ],
    );
  }
}

// ── OTP code entry step ────────────────────────────────────────────────────────

class _OtpCodeStep extends StatelessWidget {
  final AppLocalizations l10n;
  final String phone;
  final TextEditingController controller;
  final VoidCallback onVerify;
  final VoidCallback onChangeNumber;

  const _OtpCodeStep({
    required this.l10n,
    required this.phone,
    required this.controller,
    required this.onVerify,
    required this.onChangeNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sent-to banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  size: 18, color: AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.otpSentTo(phone),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 6-digit OTP field
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 6,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 12,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '• • • • • •',
            hintStyle: const TextStyle(
              fontSize: 20,
              letterSpacing: 10,
              color: AppColors.textHint,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onFieldSubmitted: (_) => onVerify(),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.otpSmsHint,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: l10n.verifyAndSignIn, onPressed: onVerify),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onChangeNumber,
          child: Text(l10n.changeNumber),
        ),
      ],
    );
  }
}

// ── Skeleton ───────────────────────────────────────────────────────────────────

class _LoginFormSkeleton extends StatelessWidget {
  const _LoginFormSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PulsingSkeletonBar(height: 44, borderRadius: 12),
        const SizedBox(height: 24),
        PulsingSkeletonBar(height: 52),
        const SizedBox(height: 16),
        PulsingSkeletonBar(height: 52),
        const SizedBox(height: 28),
        PulsingSkeletonBar(height: 52),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PulsingSkeletonBar(width: 160, height: 16, borderRadius: 4),
          ],
        ),
      ],
    );
  }
}
