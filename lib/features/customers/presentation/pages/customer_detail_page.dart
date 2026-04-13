import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:service_reminder/app/router/route_names.dart';
import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/core/utils/date_time_utils.dart';
import 'package:service_reminder/core/utils/maps_utils.dart';
import 'package:service_reminder/features/customers/domain/entities/customer.dart';
import 'package:service_reminder/features/customers/presentation/providers/customers_controller.dart';
import 'package:service_reminder/shared/widgets/loading_indicator.dart';

/// Best match for total days → months (0–12) and weeks (0–3), same as [CustomerForm].
(int months, int weeks) _monthsWeeksFromTotalDays(int totalDays) {
  final t = totalDays.clamp(0, 12 * 30 + 3 * 7);
  var bestM = 0;
  var bestW = 0;
  var bestDiff = 1 << 20;
  for (var m = 0; m <= 12; m++) {
    for (var w = 0; w <= 3; w++) {
      final d = m * 30 + w * 7;
      final diff = (d - t).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestM = m;
        bestW = w;
      }
    }
  }
  return (bestM, bestW);
}

class CustomerDetailPage extends ConsumerWidget {
  final String customerId;

  const CustomerDetailPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerByIdProvider(customerId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: customerAsync.maybeWhen(
          data: (c) => Text(
            c.name,
            style: AppTypography.heading2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          orElse: () => const Text('Customer', style: AppTypography.heading2),
        ),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Service history',
            onPressed: () => context.push(
              RouteNames.customerServiceHistoryPath(customerId),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit customer',
            onPressed: () => context.push(
              RouteNames.customerEditPath(customerId),
            ),
          ),
        ],
      ),
      body: customerAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e.toString(),
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (customer) => _CustomerDetailView(customer: customer),
      ),
    );
  }
}

class _CustomerDetailView extends StatelessWidget {
  final Customer customer;

  const _CustomerDetailView({required this.customer});

  @override
  Widget build(BuildContext context) {
    final isAmc = customer.customerType == CustomerType.amc;
    final (months, weeks) = _monthsWeeksFromTotalDays(customer.serviceFrequencyDays);
    final freqParts = <String>[];
    if (months > 0) freqParts.add('$months mo');
    if (weeks > 0) freqParts.add('$weeks wk');
    final freqLabel = isAmc
        ? (freqParts.isEmpty
            ? '${customer.serviceFrequencyDays} days'
            : '${freqParts.join(' · ')} (~${customer.serviceFrequencyDays} days)')
        : '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  radius: 32,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    customer.name.isNotEmpty
                        ? customer.name[0].toUpperCase()
                        : '?',
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
                        customer.name,
                        style: AppTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      _TypeChip(type: customer.customerType),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Details',
            style: AppTypography.label.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _ReadOnlyTile(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: customer.phone,
            emptyHint: 'Not added',
          ),
          const SizedBox(height: 8),
          _ReadOnlyTile(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: customer.address,
            emptyHint: 'Not added',
            multiline: true,
            onTap: (customer.address?.trim().isNotEmpty ?? false)
                ? () => MapsUtils.openInMaps(customer.address!)
                : null,
          ),
          const SizedBox(height: 8),
          _ReadOnlyTile(
            icon: Icons.event_repeat_outlined,
            label: 'Service frequency',
            value: freqLabel,
            emptyHint: null,
          ),
          const SizedBox(height: 8),
          _ReadOnlyTile(
            icon: Icons.event_available_outlined,
            label: 'Next service',
            value: customer.nextServiceAt != null
                ? DateTimeUtils.formatDate(customer.nextServiceAt!)
                : '—',
            emptyHint: null,
          ),
          const SizedBox(height: 8),
          _ReadOnlyTile(
            icon: Icons.calendar_today_outlined,
            label: 'Customer since',
            value: DateTimeUtils.formatDate(customer.createdAt),
            emptyHint: null,
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final CustomerType type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final isAmc = type == CustomerType.amc;
    final color = isAmc ? AppColors.success : AppColors.textSecondary;
    final label = isAmc ? 'AMC customer' : 'One-time customer';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReadOnlyTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? emptyHint;
  final bool multiline;
  final VoidCallback? onTap;

  const _ReadOnlyTile({
    required this.icon,
    required this.label,
    required this.value,
    this.emptyHint,
    this.multiline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final v = value?.trim();
    final hasValue = v != null && v.isNotEmpty;
    final display = hasValue ? v : (emptyHint ?? '—');
    final isMuted = !hasValue && emptyHint != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  display,
                  style: AppTypography.body.copyWith(
                    color: isMuted ? AppColors.textHint : AppColors.textPrimary,
                    fontStyle:
                        isMuted ? FontStyle.italic : FontStyle.normal,
                  ),
                  maxLines: multiline ? 6 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.primary),
          ],
        ],
      ),
    ),
    );
  }
}
