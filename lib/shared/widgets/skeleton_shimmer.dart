import 'package:flutter/material.dart';

import 'package:service_reminder/core/theme/app_colors.dart';

/// Pulsing rounded rectangle for skeleton loading states (no extra packages).
class PulsingSkeletonBar extends StatefulWidget {
  const PulsingSkeletonBar({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<PulsingSkeletonBar> createState() => _PulsingSkeletonBarState();
}

class _PulsingSkeletonBarState extends State<PulsingSkeletonBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final color = Color.lerp(
          AppColors.surfaceVariant,
          AppColors.divider,
          t,
        )!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
