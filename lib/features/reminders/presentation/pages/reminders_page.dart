import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/core/utils/date_time_utils.dart';
import 'package:service_reminder/features/reminders/domain/entities/reminder.dart';
import 'package:service_reminder/features/reminders/presentation/providers/due_reminders_provider.dart';
import 'package:service_reminder/features/reminders/presentation/widgets/reminder_tile.dart';

class RemindersPage extends ConsumerWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dueRemindersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reminders', style: AppTypography.heading2),
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.read(dueRemindersProvider.notifier).refresh(),
        ),
        data: (reminders) => RefreshIndicator(
          onRefresh: () => ref.read(dueRemindersProvider.notifier).refresh(),
          child: reminders.isEmpty
              ? _EmptyState()
              : _RemindersList(reminders: reminders),
        ),
      ),
    );
  }
}

// ── Partitioned list ──────────────────────────────────────────────────────────

class _RemindersList extends StatelessWidget {
  final List<Reminder> reminders;

  const _RemindersList({required this.reminders});

  @override
  Widget build(BuildContext context) {
    final overdue = reminders
        .where((r) =>
            DateTimeUtils.isOverdue(r.nextServiceAt) ||
            DateTimeUtils.isDueToday(r.nextServiceAt))
        .toList();
    final dueSoon = reminders
        .where((r) => DateTimeUtils.isDueSoon(r.nextServiceAt))
        .toList();

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        if (overdue.isNotEmpty) ...[
          _SectionHeader(
            label: 'Overdue / Due Today',
            count: overdue.length,
            color: AppColors.overdue,
          ),
          ...overdue.map((r) => ReminderTile(reminder: r)),
        ],
        if (dueSoon.isNotEmpty) ...[
          _SectionHeader(
            label: 'Due Soon',
            count: dueSoon.length,
            color: AppColors.dueSoon,
          ),
          ...dueSoon.map((r) => ReminderTile(reminder: r)),
        ],
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.check_circle_outline_rounded,
          size: 72,
          color: AppColors.success.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 20),
        Text(
          'All caught up!',
          textAlign: TextAlign.center,
          style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'No customers are due for service\nin the next 7 days.',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load reminders',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
