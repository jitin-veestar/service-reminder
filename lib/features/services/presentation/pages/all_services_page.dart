import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:service_reminder/app/router/route_names.dart';
import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/assigned_service.dart';
import 'package:service_reminder/features/assigned_services/presentation/providers/assigned_services_provider.dart';
import 'package:service_reminder/shared/widgets/loading_indicator.dart';

class AllServicesPage extends ConsumerWidget {
  const AllServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(completedVisitsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Services', style: AppTypography.heading2),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e.toString(),
                style: AppTypography.bodySmall, textAlign: TextAlign.center),
          ),
        ),
        data: (visits) {
          if (visits.isEmpty) {
            return const _EmptyState();
          }
          // Group by month
          final grouped = <String, List<AssignedService>>{};
          for (final v in visits) {
            final key = DateFormat('MMMM yyyy').format(v.scheduledDate);
            grouped.putIfAbsent(key, () => []).add(v);
          }
          final months = grouped.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
            itemCount: months.fold<int>(
              0,
              (sum, m) => sum + 1 + grouped[m]!.length,
            ),
            itemBuilder: (context, index) {
              var cursor = 0;
              for (final month in months) {
                if (index == cursor) {
                  return _MonthHeader(month: month);
                }
                cursor++;
                final items = grouped[month]!;
                if (index < cursor + items.length) {
                  return _ServiceTile(visit: items[index - cursor]);
                }
                cursor += items.length;
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String month;
  const _MonthHeader({required this.month});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        month.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final AssignedService visit;
  const _ServiceTile({required this.visit});

  @override
  Widget build(BuildContext context) {
    final name = visit.customerName ?? 'Unknown';
    final service = visit.serviceOfferingName?.trim();
    final date = DateFormat('d MMM').format(visit.scheduledDate);
    final initials = () {
      final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return parts.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }();

    return InkWell(
      onTap: () => context.push(RouteNames.customerDetailPath(visit.customerId)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.success.withValues(alpha: 0.12),
              child: Text(
                initials,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (service != null && service.isNotEmpty)
                    Text(
                      service,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  date,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Done',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.task_alt_rounded,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'No completed services yet',
              style: AppTypography.heading3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Services you complete will appear here.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
