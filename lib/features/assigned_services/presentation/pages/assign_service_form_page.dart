import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/features/assigned_services/domain/assigned_service_status_rules.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/assigned_service.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/service_note.dart';
import 'package:service_reminder/features/assigned_services/presentation/providers/assigned_services_provider.dart';
import 'package:service_reminder/features/customers/domain/entities/customer.dart';
import 'package:service_reminder/features/customers/presentation/providers/customers_controller.dart';
import 'package:service_reminder/features/service_catalog/domain/entities/service_offering.dart';
import 'package:service_reminder/features/service_catalog/presentation/providers/service_offerings_providers.dart';

class AssignServiceFormPage extends ConsumerStatefulWidget {
  const AssignServiceFormPage({super.key});

  @override
  ConsumerState<AssignServiceFormPage> createState() =>
      _AssignServiceFormPageState();
}

class _AssignServiceFormPageState extends ConsumerState<AssignServiceFormPage> {
  static const _uuid = Uuid();

  Customer? _selectedCustomer;
  ServiceOffering? _selectedOffering;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final List<ServiceNote> _notes = [];

  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _addNote() {
    final msg = _noteController.text.trim();
    if (msg.isEmpty) return;
    setState(() {
      _notes.add(ServiceNote(
        id: _uuid.v4(),
        noteTime: DateTime.now(),
        message: msg,
        status: 'general',
      ));
      _noteController.clear();
    });
  }

  void _removeNote(String id) {
    setState(() => _notes.removeWhere((n) => n.id == id));
  }

  Future<void> _submit() async {
    if (_selectedCustomer == null) {
      _showError('Please select a customer.');
      return;
    }
    if (_selectedDate == null) {
      _showError('Please select a date.');
      return;
    }

    // Build time string
    String? timeStr;
    if (_selectedTime != null) {
      timeStr =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
    }

    final status = timeStr == null
        ? AssignedServiceStatus.draft
        : AssignedServiceStatusRules.persistedAfterTimeSet(
            _selectedDate!,
            timeStr,
          );

    // technicianId is filled by the datasource (auth.currentUser.id).
    // We pass empty string here; the DB sets it via RLS/default.
    final service = AssignedService(
      id: '',
      technicianId: '',
      customerId: _selectedCustomer!.id,
      serviceOfferingId: _selectedOffering?.id,
      serviceOfferingName: _selectedOffering?.name,
      scheduledDate: _selectedDate!,
      scheduledTime: timeStr,
      status: status,
      notes: List.unmodifiable(_notes),
      createdAt: DateTime.now(),
    );

    setState(() => _saving = true);
    try {
      await ref.read(dashboardVisitsProvider.notifier).createVisit(service);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersListProvider);
    final offeringsAsync = ref.watch(serviceOfferingsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assign Service', style: AppTypography.heading2),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Save'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Customer ────────────────────────────────────────────────────
          _SectionLabel(label: 'Customer'),
          const SizedBox(height: 8),
          customersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error loading customers',
                style: TextStyle(color: AppColors.error)),
            data: (customers) => _SearchableCustomerField(
              customers: customers,
              selected: _selectedCustomer,
              onChanged: (c) => setState(() => _selectedCustomer = c),
            ),
          ),

          const SizedBox(height: 16),

          // ── Service ──────────────────────────────────────────────────────
          _SectionLabel(label: 'Service'),
          const SizedBox(height: 8),
          offeringsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error loading services',
                style: TextStyle(color: AppColors.error)),
            data: (offerings) => _SearchableServiceField(
              offerings: offerings,
              selected: _selectedOffering,
              onChanged: (s) => setState(() => _selectedOffering = s),
            ),
          ),

          const SizedBox(height: 16),

          // ── Date & Time ──────────────────────────────────────────────────
          _SectionLabel(label: 'Date & Time'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TapField(
                  icon: Icons.calendar_today_outlined,
                  label: _selectedDate != null
                      ? DateFormat('d MMM yyyy').format(_selectedDate!)
                      : 'Select date',
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TapField(
                  icon: Icons.access_time_outlined,
                  label: _selectedTime != null
                      ? _selectedTime!.format(context)
                      : 'Select time',
                  onTap: _pickTime,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Notes ────────────────────────────────────────────────────────
          _SectionLabel(label: 'Notes'),
          const SizedBox(height: 8),
          ..._notes.map(
            (note) => _NoteCard(note: note, onRemove: () => _removeNote(note.id)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Add a note…',
                    hintStyle: AppTypography.bodySmall
                        .copyWith(color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addNote(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _addNote,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(14),
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SearchableCustomerField extends StatelessWidget {
  final List<Customer> customers;
  final Customer? selected;
  final ValueChanged<Customer?> onChanged;

  const _SearchableCustomerField({
    required this.customers,
    required this.selected,
    required this.onChanged,
  });

  Future<void> _openSheet(BuildContext context) async {
    final sorted = [...customers]..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    final picked = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.88;
        return SafeArea(
          child: SizedBox(
            height: maxH,
            child: _CustomerSearchSheet(
              customers: sorted,
              selectedId: selected?.id,
            ),
          ),
        );
      },
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: customers.isEmpty ? null : () => _openSheet(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selected?.name ?? 'Select customer',
                    style: AppTypography.body.copyWith(
                      color: selected == null
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: AppColors.primary.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerSearchSheet extends StatefulWidget {
  final List<Customer> customers;
  final String? selectedId;

  const _CustomerSearchSheet({
    required this.customers,
    this.selectedId,
  });

  @override
  State<_CustomerSearchSheet> createState() => _CustomerSearchSheetState();
}

class _CustomerSearchSheetState extends State<_CustomerSearchSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return widget.customers;
    return widget.customers.where((c) {
      if (c.name.toLowerCase().contains(q)) return true;
      final phone = c.phone?.toLowerCase();
      if (phone != null && phone.contains(q)) return true;
      final addr = c.address?.toLowerCase();
      if (addr != null && addr.contains(q)) return true;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Select customer',
            style: AppTypography.heading3,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search name, phone, or address',
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 22),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 12,
              ),
            ),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              final list = _filtered;
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      widget.customers.isEmpty
                          ? 'No customers yet.'
                          : 'No customers match your search.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final c = list[index];
                  final sel = c.id == widget.selectedId;
                  return ListTile(
                    title: Text(
                      c.name,
                      style: AppTypography.body.copyWith(
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    subtitle: (c.phone != null && c.phone!.trim().isNotEmpty)
                        ? Text(
                            c.phone!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    trailing: sel
                        ? Icon(Icons.check_circle_rounded,
                            color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop(c),
                  );
                },
              );
            },
          ),
        ),
        ],
      ),
    );
  }
}

// Sheet result: `null` = user dismissed; cleared / picked = explicit choice.
abstract class _ServiceSheetResult {}

class _ServiceSheetCleared extends _ServiceSheetResult {}

class _ServiceSheetPicked extends _ServiceSheetResult {
  final ServiceOffering offering;
  _ServiceSheetPicked(this.offering);
}

class _SearchableServiceField extends StatelessWidget {
  final List<ServiceOffering> offerings;
  final ServiceOffering? selected;
  final ValueChanged<ServiceOffering?> onChanged;

  const _SearchableServiceField({
    required this.offerings,
    required this.selected,
    required this.onChanged,
  });

  Future<void> _openSheet(BuildContext context) async {
    final sorted = [...offerings]..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    final result = await showModalBottomSheet<_ServiceSheetResult?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.88;
        return SafeArea(
          child: SizedBox(
            height: maxH,
            child: _ServiceSearchSheet(
              offerings: sorted,
              selectedId: selected?.id,
            ),
          ),
        );
      },
    );
    if (result == null) return;
    if (result is _ServiceSheetCleared) {
      onChanged(null);
    } else if (result is _ServiceSheetPicked) {
      onChanged(result.offering);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openSheet(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selected?.name ?? 'Select service (optional)',
                    style: AppTypography.body.copyWith(
                      color: selected == null
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: AppColors.primary.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceSearchSheet extends StatefulWidget {
  final List<ServiceOffering> offerings;
  final String? selectedId;

  const _ServiceSearchSheet({
    required this.offerings,
    this.selectedId,
  });

  @override
  State<_ServiceSearchSheet> createState() => _ServiceSearchSheetState();
}

class _ServiceSearchSheetState extends State<_ServiceSearchSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String? _priceLine(ServiceOffering s) {
    final p = s.defaultPrice;
    if (p == null) return null;
    if (p == p.roundToDouble()) return '₹${p.round()}';
    return '₹${p.toStringAsFixed(2)}';
  }

  List<ServiceOffering> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return widget.offerings;
    return widget.offerings.where((s) {
      if (s.name.toLowerCase().contains(q)) return true;
      final desc = s.description?.toLowerCase();
      if (desc != null && desc.contains(q)) return true;
      final price = _priceLine(s)?.toLowerCase();
      if (price != null && price.contains(q)) return true;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Select service',
              style: AppTypography.heading3,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search service name, description, or price',
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                final list = _filtered;
                final noneSelected = widget.selectedId == null;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.remove_circle_outline_rounded,
                        color: AppColors.textSecondary,
                      ),
                      title: Text(
                        'No service',
                        style: AppTypography.body.copyWith(
                          fontWeight:
                              noneSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Optional — skip catalog item',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: noneSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: AppColors.primary)
                          : null,
                      onTap: () => Navigator.of(context)
                          .pop(_ServiceSheetCleared()),
                    ),
                    const Divider(height: 1),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            widget.offerings.isEmpty
                                ? 'Add services under the Services tab first.'
                                : 'No services match your search.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ...list.map((s) {
                        final sel = s.id == widget.selectedId;
                        final price = _priceLine(s);
                        final desc = s.description?.trim();
                        String? subtitle;
                        if (price != null &&
                            desc != null &&
                            desc.isNotEmpty) {
                          subtitle = '$price · $desc';
                        } else {
                          subtitle = price ?? desc;
                        }
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: Text(
                                s.name,
                                style: AppTypography.body.copyWith(
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              subtitle: subtitle != null && subtitle.isNotEmpty
                                  ? Text(
                                      subtitle,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: sel
                                  ? Icon(Icons.check_circle_rounded,
                                      color: AppColors.primary)
                                  : null,
                              onTap: () => Navigator.of(context)
                                  .pop(_ServiceSheetPicked(s)),
                            ),
                            const Divider(height: 1),
                          ],
                        );
                      }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TapField extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TapField({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: AppTypography.body),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final ServiceNote note;
  final VoidCallback onRemove;

  const _NoteCard({required this.note, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.message, style: AppTypography.body),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMM, HH:mm').format(note.noteTime),
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
