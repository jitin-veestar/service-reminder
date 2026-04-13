import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/core/utils/validators.dart';
import 'package:service_reminder/features/customers/domain/entities/customer.dart';
import 'package:service_reminder/features/customers/presentation/providers/customer_form_controller.dart';
import 'package:service_reminder/shared/widgets/app_text_field.dart';
import 'package:service_reminder/shared/widgets/primary_button.dart';

class CustomerForm extends ConsumerStatefulWidget {
  /// When non-null, form runs in edit mode and uses [customerFormControllerProvider] with this id.
  final String? editingCustomerId;
  final Customer? initialCustomer;
  final VoidCallback onSuccess;

  const CustomerForm({
    super.key,
    this.editingCustomerId,
    this.initialCustomer,
    required this.onSuccess,
  });

  @override
  ConsumerState<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends ConsumerState<CustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Service frequency — default 4 months, 0 weeks
  int _selectedMonths = 4;
  int _selectedWeeks = 0;

  CustomerType _customerType = CustomerType.oneTime;

  int get _frequencyDays => _selectedMonths * 30 + _selectedWeeks * 7;

  /// Inverse of `_selectedMonths * 30 + _selectedWeeks * 7` (best match). Months 0–12.
  static (int months, int weeks) _monthsWeeksFromTotalDays(int totalDays) {
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

  @override
  void initState() {
    super.initState();
    final c = widget.initialCustomer;
    if (c != null) {
      _nameController.text = c.name;
      _phoneController.text = c.phone ?? '';
      _addressController.text = c.address ?? '';
      final (m, w) = _monthsWeeksFromTotalDays(c.serviceFrequencyDays);
      _selectedMonths = m;
      _selectedWeeks = w;
      _customerType = c.customerType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final customer = await ref
        .read(customerFormControllerProvider(widget.editingCustomerId).notifier)
        .submit(
              name: _nameController.text,
              phone: _phoneController.text.isEmpty
                  ? null
                  : _phoneController.text,
              address: _addressController.text.isEmpty
                  ? null
                  : _addressController.text,
              serviceFrequencyDays: _frequencyDays,
              customerType: _customerType,
            );

    if (customer != null && mounted) widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final formState =
        ref.watch(customerFormControllerProvider(widget.editingCustomerId));
    final isLoading = formState is AsyncLoading;

    ref.listen<AsyncValue<void>>(
        customerFormControllerProvider(widget.editingCustomerId), (_, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Customer Name',
            hint: 'e.g. Ramesh Kumar',
            controller: _nameController,
            validator: Validators.name,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Phone Number (optional)',
            hint: 'e.g. 9876543210',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: Validators.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Address (optional)',
            hint: 'e.g. 12, Main Street, Chennai',
            controller: _addressController,
            maxLines: 2,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),

          // ── Customer Type ───────────────────────────────────────────────
          const _SectionLabel(label: 'Customer Type'),
          const SizedBox(height: 10),
          _CustomerTypeSelector(
            value: _customerType,
            onChanged: (type) => setState(() => _customerType = type),
          ),
          const SizedBox(height: 24),

          // ── Service Frequency (AMC only) ─────────────────────────────────
          if (_customerType == CustomerType.amc) ...[
            Row(
              children: [
                const _SectionLabel(label: 'Service Frequency'),
                const Spacer(),
                Text(
                  '$_frequencyDays days total',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _FrequencyRollPicker(
              selectedMonths: _selectedMonths,
              selectedWeeks: _selectedWeeks,
              onMonthsChanged: (v) => setState(() => _selectedMonths = v),
              onWeeksChanged: (v) => setState(() => _selectedWeeks = v),
            ),
          ],
          const SizedBox(height: 32),

          PrimaryButton(
            label: widget.editingCustomerId != null
                ? 'Update Customer'
                : 'Save Customer',
            isLoading: isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.label.copyWith(color: AppColors.textSecondary),
    );
  }
}

// ── Customer type radio selector ──────────────────────────────────────────────

class _CustomerTypeSelector extends StatelessWidget {
  final CustomerType value;
  final ValueChanged<CustomerType> onChanged;

  const _CustomerTypeSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeOption(
            label: 'One-time',
            icon: Icons.person_outline_rounded,
            selected: value == CustomerType.oneTime,
            onTap: () => onChanged(CustomerType.oneTime),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeOption(
            label: 'AMC',
            icon: Icons.verified_outlined,
            selected: value == CustomerType.amc,
            onTap: () => onChanged(CustomerType.amc),
          ),
        ),
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    final bg = selected
        ? AppColors.primary.withValues(alpha: 0.08)
        : AppColors.surface;
    final border = selected ? AppColors.primary : AppColors.border;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.label.copyWith(
                  color: color,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: selected ? 5 : 1.5,
                ),
                color: selected ? AppColors.primary : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Frequency roll picker ─────────────────────────────────────────────────────

class _FrequencyRollPicker extends StatelessWidget {
  final int selectedMonths;
  final int selectedWeeks;
  final ValueChanged<int> onMonthsChanged;
  final ValueChanged<int> onWeeksChanged;

  const _FrequencyRollPicker({
    required this.selectedMonths,
    required this.selectedWeeks,
    required this.onMonthsChanged,
    required this.onWeeksChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RollColumn(
              label: 'Months',
              itemCount: 13,
              selectedIndex: selectedMonths.clamp(0, 12),
              labelBuilder: (i) => '$i',
              onChanged: onMonthsChanged,
            ),
          ),
          Container(width: 1, color: AppColors.divider),
          Expanded(
            child: _RollColumn(
              label: 'Weeks',
              itemCount: 4,
              selectedIndex: selectedWeeks, // weeks 0–3
              labelBuilder: (i) => '$i',
              onChanged: onWeeksChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _RollColumn extends StatefulWidget {
  final String label;
  final int itemCount;
  final int selectedIndex;
  final String Function(int index) labelBuilder;
  final ValueChanged<int> onChanged;

  const _RollColumn({
    required this.label,
    required this.itemCount,
    required this.selectedIndex,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  State<_RollColumn> createState() => _RollColumnState();
}

class _RollColumnState extends State<_RollColumn> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        FixedExtentScrollController(initialItem: widget.selectedIndex);
  }

  @override
  void didUpdateWidget(_RollColumn old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex &&
        _controller.hasClients &&
        _controller.selectedItem != widget.selectedIndex) {
      _controller.animateToItem(
        widget.selectedIndex,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            widget.label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Selection highlight bar
              Positioned(
                left: 12,
                right: 12,
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: 36,
                diameterRatio: 1.6,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: widget.onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.itemCount,
                  builder: (context, index) {
                    final isSelected = index == widget.selectedIndex;
                    return Center(
                      child: Text(
                        widget.labelBuilder(index),
                        style: AppTypography.body.copyWith(
                          fontSize: isSelected ? 18 : 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
