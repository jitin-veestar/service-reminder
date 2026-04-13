import 'package:flutter/material.dart';
import 'package:service_reminder/core/theme/app_colors.dart';

/// Full-screen centered spinner.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2.5,
      ),
    );
  }
}

/// Small inline spinner (e.g. inside a button).
class SmallLoadingIndicator extends StatelessWidget {
  final Color? color;

  const SmallLoadingIndicator({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        color: color ?? AppColors.primary,
        strokeWidth: 2,
      ),
    );
  }
}
