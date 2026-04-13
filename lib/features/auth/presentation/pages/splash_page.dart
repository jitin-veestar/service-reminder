import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:service_reminder/app/router/route_names.dart';
import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/features/auth/presentation/widgets/auth_screen_skeleton.dart';

/// Shown on first launch. Redirects to Login or Home after auth check.
/// GoRouter's redirect also handles navigation — this is a visual fallback.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      context.go(RouteNames.dashboard);
    } else {
      context.go(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: AuthScreenSkeleton(),
        ),
      ),
    );
  }
}
