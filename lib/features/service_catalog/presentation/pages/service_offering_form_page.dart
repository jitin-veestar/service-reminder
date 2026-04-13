import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/features/service_catalog/domain/entities/service_offering.dart';
import 'package:service_reminder/features/service_catalog/presentation/providers/service_offerings_providers.dart';
import 'package:service_reminder/shared/widgets/app_text_field.dart';
import 'package:service_reminder/shared/widgets/loading_indicator.dart';
import 'package:service_reminder/shared/widgets/primary_button.dart';

class ServiceOfferingFormPage extends ConsumerStatefulWidget {
  final String? offeringId;

  const ServiceOfferingFormPage({super.key, this.offeringId});

  @override
  ConsumerState<ServiceOfferingFormPage> createState() =>
      _ServiceOfferingFormPageState();
}

class _ServiceOfferingFormPageState
    extends ConsumerState<ServiceOfferingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  bool _loadingExisting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    final id = widget.offeringId;
    if (id != null) {
      _loadingExisting = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(id));
    }
  }

  Future<void> _load(String id) async {
    try {
      final list =
          await ref.read(serviceOfferingsRepositoryProvider).getAll();
      ServiceOffering? o;
      for (final e in list) {
        if (e.id == id) {
          o = e;
          break;
        }
      }
      if (!mounted) return;
      if (o == null) {
        setState(() {
          _loadError = 'Service not found';
          _loadingExisting = false;
        });
        return;
      }
      final ServiceOffering found = o;
      setState(() {
        _name.text = found.name;
        _description.text = found.description ?? '';
        _price.text =
            found.defaultPrice != null ? found.defaultPrice!.toString() : '';
        _loadingExisting = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _loadingExisting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  double? _parsePrice() {
    final t = _price.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final price = _parsePrice();
    if (_price.text.trim().isNotEmpty && price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid default price or leave blank'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final repo = ref.read(serviceOfferingsRepositoryProvider);
    final id = widget.offeringId;
    try {
      if (id == null) {
        await repo.create(
          name: _name.text,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          defaultPrice: price,
        );
      } else {
        await repo.update(
          id: id,
          name: _name.text,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          defaultPrice: price,
        );
      }
      if (!mounted) return;
      await ref.read(serviceOfferingsListProvider.notifier).refresh();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.offeringId;
    final isEdit = id != null;

    if (_loadingExisting) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Service', style: AppTypography.heading2),
          backgroundColor: AppColors.surface,
        ),
        body: const LoadingIndicator(),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Service', style: AppTypography.heading2),
          backgroundColor: AppColors.surface,
        ),
        body: Center(child: Text(_loadError!, style: AppTypography.bodySmall)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Service' : 'Add Service',
          style: AppTypography.heading2,
        ),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Service name',
                hint: 'e.g. RO filter replacement',
                controller: _name,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description (optional)',
                hint: 'What this visit includes',
                controller: _description,
                maxLines: 3,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Default price (optional)',
                hint: 'e.g. 450',
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 8),
              Text(
                'Visit records stay in Service history on each customer. This list is your reusable menu of work types.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: isEdit ? 'Save changes' : 'Create service',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
