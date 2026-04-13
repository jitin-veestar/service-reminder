import 'package:flutter/material.dart';

import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/core/utils/date_time_utils.dart';

/// Colour-coded chip showing how soon the next service is due.
class ServiceStatusChip extends StatelessWidget {
  final DateTime nextServiceAt;

  const ServiceStatusChip({super.key, required this.nextServiceAt});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    if (DateTimeUtils.isOverdue(nextServiceAt)) {
      bg = AppColors.overdue.withValues(alpha: 0.12);
      fg = AppColors.overdue;
      label = DateTimeUtils.relativeDateLabel(nextServiceAt);
    } else if (DateTimeUtils.isDueToday(nextServiceAt)) {
      bg = AppColors.overdue.withValues(alpha: 0.12);
      fg = AppColors.overdue;
      label = 'Due today';
    } else if (DateTimeUtils.isDueSoon(nextServiceAt)) {
      bg = AppColors.dueSoon.withValues(alpha: 0.12);
      fg = AppColors.dueSoon;
      label = DateTimeUtils.relativeDateLabel(nextServiceAt);
    } else {
      bg = AppColors.upToDate.withValues(alpha: 0.12);
      fg = AppColors.upToDate;
      label = 'Next: ${DateTimeUtils.formatShortDate(nextServiceAt)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppTypography.caption.copyWith(color: fg)),
    );
  }
}
