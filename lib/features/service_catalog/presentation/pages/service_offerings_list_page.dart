import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:service_reminder/app/router/route_names.dart';
import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/features/service_catalog/domain/entities/service_offering.dart';
import 'package:service_reminder/features/service_catalog/presentation/providers/service_offerings_providers.dart';
import 'package:service_reminder/shared/widgets/loading_indicator.dart';

class ServiceOfferingsListPage extends ConsumerWidget {
  const ServiceOfferingsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(serviceOfferingsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Packages', style: AppTypography.heading2),
        backgroundColor: AppColors.surface,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.addServiceOffering),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.toString(),
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      ref.read(serviceOfferingsListProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_repair_service_outlined,
                        size: 56, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    const Text(
                      'No packages yet',
                      style: AppTypography.heading3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add packages (e.g. Filter Change, AMC Visit) to reuse when recording customer visits.',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                ref.read(serviceOfferingsListProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final o = items[index];
                return _OfferingCard(
                  offering: o,
                  onTap: () => context.push(
                    RouteNames.serviceOfferingEditPath(o.id),
                  ),
                  onDelete: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete service?'),
                        content: Text(
                          'Remove “${o.name}”? This does not delete past visit records in service history.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      await ref
                          .read(serviceOfferingsListProvider.notifier)
                          .deleteOffering(o.id);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _OfferingCard extends StatelessWidget {
  final ServiceOffering offering;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _OfferingCard({
    required this.offering,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final price = offering.defaultPrice;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.build_circle_outlined,
                  color: AppColors.primary, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offering.name, style: AppTypography.heading3),
                    if (offering.description != null &&
                        offering.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        offering.description!,
                        style: AppTypography.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (price != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Default ₹${price.toStringAsFixed(0)}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
