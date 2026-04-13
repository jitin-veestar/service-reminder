import 'package:flutter/material.dart';

import 'package:service_reminder/shared/widgets/skeleton_shimmer.dart';

/// Skeleton layout shown while the app checks auth on cold start.
class AuthScreenSkeleton extends StatelessWidget {
  const AuthScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 72),
          Center(
            child: PulsingSkeletonBar(
              width: 56,
              height: 56,
              borderRadius: 16,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: PulsingSkeletonBar(height: 28, width: 220),
          ),
          const SizedBox(height: 10),
          Center(
            child: PulsingSkeletonBar(height: 16, width: 280),
          ),
          const SizedBox(height: 48),
          PulsingSkeletonBar(height: 44),
          const SizedBox(height: 20),
          PulsingSkeletonBar(height: 52),
          const SizedBox(height: 16),
          PulsingSkeletonBar(height: 52),
          const SizedBox(height: 28),
          PulsingSkeletonBar(height: 52),
        ],
      ),
    );
  }
}
