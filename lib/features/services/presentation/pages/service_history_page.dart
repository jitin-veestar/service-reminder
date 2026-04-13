import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/core/utils/date_time_utils.dart';
import 'package:service_reminder/features/assigned_services/presentation/providers/assigned_services_provider.dart';
import 'package:service_reminder/features/services/domain/entities/service_record.dart';
import 'package:service_reminder/features/services/presentation/providers/service_history_provider.dart';
import 'package:service_reminder/features/services/presentation/widgets/history_voice_player_bar.dart';
import 'package:service_reminder/shared/widgets/loading_indicator.dart';

/// Full-screen service history (opened from customer detail).
class CustomerServiceHistoryPage extends ConsumerWidget {
  final String customerId;

  const CustomerServiceHistoryPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Service history', style: AppTypography.heading2),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ServiceHistorySection(customerId: customerId),
            const SizedBox(height: 20),
            RescheduleHistorySection(customerId: customerId),
          ],
        ),
      ),
    );
  }
}

/// Embeddable widget that shows the full service history for a customer.
class ServiceHistorySection extends ConsumerWidget {
  final String customerId;

  const ServiceHistorySection({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(serviceHistoryProvider(customerId));

    return historyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: LoadingIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(e.toString(), style: AppTypography.bodySmall),
      ),
      data: (records) {
        if (records.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.history, size: 40, color: AppColors.textHint),
                SizedBox(height: 10),
                Text('No service history yet',
                    style: AppTypography.bodySmall),
              ],
            ),
          );
        }
        return Column(
          children: records
              .map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ServiceRecordCard(record: r),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _ServiceRecordCard extends ConsumerWidget {
  final ServiceRecord record;

  const _ServiceRecordCard({required this.record});

  static String _formatAmount(double v) {
    if (v <= 0) return '';
    if (v == v.roundToDouble()) return '₹${v.round()}';
    return '₹${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doneItems =
        record.checklistItems.where((c) => c.isChecked).toList();
    final amountLabel = _formatAmount(record.amountCharged);
    final audioPath = record.audioStoragePath;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: date + next service ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.build_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          DateTimeUtils.formatDate(record.servicedAt),
                          style: AppTypography.label,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Next: ${DateTimeUtils.formatShortDate(record.nextServiceAt)}',
                  style: AppTypography.caption,
                ),
              ],
            ),

            if (audioPath != null && audioPath.isNotEmpty) ...[
              const SizedBox(height: 12),
              HistoryVoicePlayerBar(storagePath: audioPath),
            ],

            if (amountLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(amountLabel,
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w600)),
            ],

            // ── Completed checkpoints ─────────────────────────────────────
            if (doneItems.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: doneItems
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.label,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            // ── Notes ─────────────────────────────────────────────────────
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Text(record.notes!, style: AppTypography.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Reschedule history section ────────────────────────────────────────────────

/// Shows all reschedule events across every assignment for this customer.
class RescheduleHistorySection extends ConsumerWidget {
  final String customerId;

  const RescheduleHistorySection({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(customerAssignmentsProvider(customerId));

    return assignmentsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (assignments) {
        // Collect all reschedule notes from all assignments
        final events = <_RescheduleEvent>[];
        for (final a in assignments) {
          for (final note in a.notes) {
            if (note.status == 'rescheduled') {
              events.add(_RescheduleEvent(
                reason: note.message,
                at: note.noteTime,
                rescheduledTo: a.scheduledDate,
              ));
            }
          }
        }
        if (events.isEmpty) return const SizedBox.shrink();

        events.sort((a, b) => b.at.compareTo(a.at));
        final fmt = DateFormat('d MMM yyyy');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section header
            Row(
              children: [
                const Icon(Icons.event_repeat_rounded,
                    size: 16, color: Color(0xFFF57F17)),
                const SizedBox(width: 6),
                Text(
                  'Reschedule history',
                  style: AppTypography.heading3.copyWith(fontSize: 14),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Text(
                    '${events.length}',
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFFF57F17),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Timeline
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: events.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final isLast = i == events.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timeline dot
                            Column(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF57F17),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 1.5,
                                    height: 30,
                                    color: const Color(0xFFFFE082),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.reason,
                                    style: AppTypography.body
                                        .copyWith(fontSize: 13),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${fmt.format(e.at)}  →  Moved to ${fmt.format(e.rescheduledTo)}',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        const Divider(
                            height: 1, indent: 34, color: AppColors.divider),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RescheduleEvent {
  final String reason;
  final DateTime at;
  final DateTime rescheduledTo;

  const _RescheduleEvent({
    required this.reason,
    required this.at,
    required this.rescheduledTo,
  });
}
