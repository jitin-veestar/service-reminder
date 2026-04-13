import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/features/customers/presentation/providers/customers_controller.dart';
import 'package:service_reminder/features/customers/presentation/widgets/customer_form.dart';
import 'package:service_reminder/shared/widgets/loading_indicator.dart';

class CustomerFormPage extends ConsumerWidget {
  /// `null` = add customer; otherwise edit existing.
  final String? customerId;

  const CustomerFormPage({super.key, this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = customerId;
    if (id == null) {
      return _scaffold(
        context,
        title: 'Add Customer',
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            28 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: CustomerForm(
            editingCustomerId: null,
            onSuccess: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }

    final asyncCustomer = ref.watch(customerByIdProvider(id));
    return asyncCustomer.when(
      loading: () => _scaffold(
        context,
        title: 'Edit Customer',
        body: const LoadingIndicator(),
      ),
      error: (e, _) => _scaffold(
        context,
        title: 'Edit Customer',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e.toString(),
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (customer) => _scaffold(
        context,
        title: 'Edit Customer',
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            28 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: CustomerForm(
            key: ValueKey(customer.id),
            editingCustomerId: customer.id,
            initialCustomer: customer,
            onSuccess: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  Widget _scaffold(BuildContext context,
      {required String title, required Widget body}) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppTypography.heading2),
        backgroundColor: AppColors.surface,
      ),
      body: body,
    );
  }
}
