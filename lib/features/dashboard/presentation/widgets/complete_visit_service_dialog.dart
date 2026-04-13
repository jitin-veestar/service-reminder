import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'package:service_reminder/core/services/storage/service_recordings_upload.dart';
import 'package:service_reminder/core/services/supabase/supabase_client_provider.dart';
import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/assigned_service.dart';
import 'package:service_reminder/features/dashboard/presentation/models/complete_visit_summary.dart';
import 'package:service_reminder/features/service_catalog/domain/entities/service_offering.dart';
import 'package:service_reminder/features/service_catalog/presentation/providers/service_offerings_providers.dart';
import 'package:service_reminder/features/services/presentation/providers/service_history_provider.dart';
import 'package:service_reminder/features/services/presentation/providers/service_record_controller.dart';
import 'package:service_reminder/features/services/presentation/widgets/voice_note_panel.dart';

/// Full "Record service & complete" bottom-sheet style dialog.
/// Returns [CompleteVisitSummary] when the service record was saved successfully.
class CompleteVisitServiceDialog extends ConsumerStatefulWidget {
  final AssignedService visit;

  const CompleteVisitServiceDialog({super.key, required this.visit});

  @override
  ConsumerState<CompleteVisitServiceDialog> createState() =>
      _CompleteVisitServiceDialogState();
}

class _CompleteVisitServiceDialogState
    extends ConsumerState<CompleteVisitServiceDialog> {
  // ── Form state ──────────────────────────────────────────────────────────────
  final _notesCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  late DateTime _servicedAt;
  String? _selectedCatalogId;
  String? _selectedCatalogName;
  bool _amountPrimed = false;

  // ── Recording state ────────────────────────────────────────────────────────
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  String? _localRecordingPath;
  Timer? _ampTimer;
  final List<double> _barLevels = List<double>.filled(7, 0.08);

  // ── UI state ───────────────────────────────────────────────────────────────
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.visit.scheduledDate;
    _servicedAt = DateTime(d.year, d.month, d.day);
    _selectedCatalogId = widget.visit.serviceOfferingId;
    _selectedCatalogName = widget.visit.serviceOfferingName;
  }

  @override
  void dispose() {
    _ampTimer?.cancel();
    _recorder.dispose();
    _notesCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // ── Catalog helpers ────────────────────────────────────────────────────────

  void _onCatalogSelected(ServiceOffering? offering) {
    setState(() {
      _selectedCatalogId = offering?.id;
      _selectedCatalogName = offering?.name;
      if (offering?.defaultPrice != null) {
        final p = offering!.defaultPrice!;
        _amountCtrl.text = p == p.roundToDouble()
            ? p.round().toString()
            : p.toStringAsFixed(2);
      }
    });
  }

  void _maybePrimeAmount(List<ServiceOffering> offerings) {
    if (_amountPrimed || offerings.isEmpty) return;
    final id = _selectedCatalogId;
    if (id == null || id.isEmpty) return;
    for (final o in offerings) {
      if (o.id == id) {
        if (!mounted) return;
        setState(() {
          _amountPrimed = true;
          if (o.defaultPrice != null) {
            final p = o.defaultPrice!;
            _amountCtrl.text = p == p.roundToDouble()
                ? p.round().toString()
                : p.toStringAsFixed(2);
          }
        });
        return;
      }
    }
  }

  // ── Date picker ────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _servicedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _servicedAt = picked);
    }
  }

  // ── Recording ──────────────────────────────────────────────────────────────

  void _startAmplitudeTicker() {
    _ampTimer?.cancel();
    _ampTimer = Timer.periodic(const Duration(milliseconds: 90), (_) async {
      if (!mounted || !_isRecording || _isPaused) return;
      try {
        final a = await _recorder.getAmplitude();
        final n = ((a.current + 50) / 50).clamp(0.0, 1.0);
        if (!mounted) return;
        setState(() {
          for (var i = 0; i < _barLevels.length; i++) {
            final wobble = 0.45 + 0.55 * (0.5 + 0.5 * ((i * 2) % 3) / 2);
            _barLevels[i] = (n * wobble).clamp(0.06, 1.0);
          }
        });
      } catch (_) {}
    });
  }

  void _stopAmplitudeTicker() {
    _ampTimer?.cancel();
    _ampTimer = null;
    for (var i = 0; i < _barLevels.length; i++) {
      _barLevels[i] = 0.08;
    }
  }

  Future<void> _startRecording() async {
    if (kIsWeb) return;
    try {
      setState(() => _localRecordingPath = null);
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          _showSnack('Microphone permission is required to record.');
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/visit_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      setState(() {
        _isRecording = true;
        _isPaused = false;
      });
      _startAmplitudeTicker();
    } catch (e) {
      if (mounted) _showSnack('Recording error: $e', isError: true);
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _recorder.pause();
      if (mounted) setState(() => _isPaused = true);
    } catch (e) {
      if (mounted) _showSnack('Pause failed: $e', isError: true);
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _recorder.resume();
      if (mounted) {
        setState(() => _isPaused = false);
        _startAmplitudeTicker();
      }
    } catch (e) {
      if (mounted) _showSnack('Resume failed: $e', isError: true);
    }
  }

  Future<void> _stopRecording() async {
    try {
      _stopAmplitudeTicker();
      final path = await _recorder.stop();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isPaused = false;
          _localRecordingPath = path;
        });
      }
    } catch (e) {
      if (mounted) _showSnack('Stop failed: $e', isError: true);
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    // Stop any in-progress recording first
    if (!kIsWeb && await _recorder.isRecording()) {
      _stopAmplitudeTicker();
      final path = await _recorder.stop();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isPaused = false;
          _localRecordingPath = path;
        });
      }
    }

    if (!mounted) return;

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    final customerId = widget.visit.customerId;

    String? audioPath;
    if (!kIsWeb && _localRecordingPath != null) {
      try {
        final client = ref.read(supabaseClientProvider);
        audioPath = await uploadServiceRecording(
          client: client,
          customerId: customerId,
          localFilePath: _localRecordingPath!,
        );
      } catch (e) {
        if (mounted) _showSnack('Could not upload recording: $e', isError: true);
        return;
      }
    }

    if (!mounted) return;
    setState(() => _saving = true);
    try {
      final ctrl =
          ref.read(serviceRecordControllerProvider(customerId).notifier);
      final saved = await ctrl.submit(
        servicedAt: _servicedAt,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        filterChanged: false,
        membraneChecked: false,
        cleaningDone: false,
        leakageFixed: false,
        amountCharged: amount,
        catalogServiceId: _selectedCatalogId,
        audioStoragePath: audioPath,
      );

      ref.invalidate(serviceHistoryProvider(customerId));

      if (saved && mounted) {
        Navigator.of(context).pop(
          CompleteVisitSummary(
            serviceName: _selectedCatalogName ?? widget.visit.serviceOfferingName,
            servicedAt: _servicedAt,
            amountCharged: amount,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            includedVoiceNote: audioPath != null,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // autoDispose: `ref.read` alone does not keep the notifier alive across awaits
    // in `_submit`. Watching keeps [ServiceRecordController] mounted with the dialog.
    ref.watch(serviceRecordControllerProvider(widget.visit.customerId));

    final maxH = MediaQuery.sizeOf(context).height * 0.92;
    final offeringsAsync = ref.watch(serviceOfferingsListProvider);

    ref.listen<AsyncValue<List<ServiceOffering>>>(
      serviceOfferingsListProvider,
      (_, next) {
        if (next is AsyncData<List<ServiceOffering>>) {
          _maybePrimeAmount(next.value);
        }
      },
    );
    offeringsAsync.whenData(_maybePrimeAmount);

    final customerInitials = () {
      final name = widget.visit.customerName?.trim() ?? '';
      if (name.isEmpty) return '?';
      final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
      return parts.length >= 2
          ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
          : parts.first[0].toUpperCase();
    }();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _DialogHeader(
              saving: _saving,
              onClose: () => Navigator.pop(context),
            ),

            const Divider(height: 1, thickness: 0.5),

            // ── Scrollable body ──────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Customer + date summary card ─────────────────────────
                    _SummaryCard(
                      customerInitials: customerInitials,
                      customerName: widget.visit.customerName ?? 'Unknown',
                      customerPhone: widget.visit.customerPhone,
                      servicedAt: _servicedAt,
                      onChangeDate: _saving ? null : _pickDate,
                    ),

                    const SizedBox(height: 16),

                    // ── Service catalog selector ─────────────────────────────
                    _FieldLabel('Service'),
                    const SizedBox(height: 6),
                    offeringsAsync.when(
                      loading: () => const _SkeletonField(),
                      error: (_, __) => const _SkeletonField(
                          label: 'Could not load services'),
                      data: (offerings) => _CatalogDropdown(
                        offerings: offerings,
                        selectedId: _selectedCatalogId,
                        enabled: !_saving,
                        onChanged: _onCatalogSelected,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Amount ───────────────────────────────────────────────
                    _FieldLabel('Amount charged (₹)'),
                    const SizedBox(height: 6),
                    _AmountField(
                      controller: _amountCtrl,
                      enabled: !_saving,
                    ),

                    const SizedBox(height: 16),

                    // ── Voice note ───────────────────────────────────────────
                    _FieldLabel('Voice note'),
                    const SizedBox(height: 8),
                    if (kIsWeb)
                      Text(
                        'Audio recording is available on iOS & Android.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      )
                    else
                      VoiceNotePanel(
                        isLoading: _saving,
                        isRecording: _isRecording,
                        isPaused: _isPaused,
                        hasClip: _localRecordingPath != null,
                        barLevels: _barLevels,
                        onMic: _startRecording,
                        onPause: _pauseRecording,
                        onResume: _resumeRecording,
                        onStop: _stopRecording,
                        onDelete: () =>
                            setState(() => _localRecordingPath = null),
                      ),

                    const SizedBox(height: 16),

                    // ── Notes ────────────────────────────────────────────────
                    _FieldLabel('Notes (optional)'),
                    const SizedBox(height: 6),
                    _NotesField(
                      controller: _notesCtrl,
                      enabled: !_saving,
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, thickness: 0.5),

            // ── Footer ───────────────────────────────────────────────────────
            _DialogFooter(
              saving: _saving,
              onCancel: () => Navigator.pop(context),
              onSave: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final bool saving;
  final VoidCallback onClose;
  const _DialogHeader({required this.saving, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.task_alt_rounded,
                size: 18, color: AppColors.success),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Record service', style: AppTypography.heading3),
                Text(
                  'Fill in the details to complete this visit',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: saving ? null : onClose,
            icon: const Icon(Icons.close, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String customerInitials;
  final String customerName;
  final String? customerPhone;
  final DateTime servicedAt;
  final VoidCallback? onChangeDate;

  const _SummaryCard({
    required this.customerInitials,
    required this.customerName,
    this.customerPhone,
    required this.servicedAt,
    this.onChangeDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        children: [
          // Customer row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.18),
                  child: Text(
                    customerInitials,
                    style: AppTypography.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (customerPhone != null &&
                          customerPhone!.isNotEmpty)
                        Text(
                          customerPhone!,
                          style: AppTypography.caption,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, indent: 14, endIndent: 14),
          // Date row — tappable to change
          InkWell(
            onTap: onChangeDate,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Service date: ${DateFormat('d MMM yyyy').format(servicedAt)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (onChangeDate != null) ...[
                    Text(
                      'Change',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Catalog dropdown ──────────────────────────────────────────────────────────

class _CatalogDropdown extends StatelessWidget {
  final List<ServiceOffering> offerings;
  final String? selectedId;
  final bool enabled;
  final ValueChanged<ServiceOffering?> onChanged;

  const _CatalogDropdown({
    required this.offerings,
    required this.selectedId,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = offerings.where((o) => o.id == selectedId).firstOrNull;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ServiceOffering>(
          value: selected,
          isExpanded: true,
          hint: Text(
            'Select a service (optional)',
            style: AppTypography.body.copyWith(color: AppColors.textHint),
          ),
          items: [
            // None option
            DropdownMenuItem<ServiceOffering>(
              value: null,
              child: Text(
                'None',
                style: AppTypography.body
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            ...offerings.map(
              (o) => DropdownMenuItem<ServiceOffering>(
                value: o,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(o.name, style: AppTypography.body),
                    ),
                    if (o.defaultPrice != null)
                      Text(
                        '₹${NumberFormat('#,##0', 'en_IN').format(o.defaultPrice!)}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: enabled ? (val) => onChanged(val) : null,
        ),
      ),
    );
  }
}

// ── Amount field ──────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _AmountField({required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: const BoxDecoration(
              border: Border(
                  right: BorderSide(color: AppColors.border, width: 0.8)),
            ),
            child: Text(
              '₹',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: AppTypography.body,
              decoration: const InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 13, horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notes field ───────────────────────────────────────────────────────────────

class _NotesField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _NotesField({required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: 3,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        style: AppTypography.body,
        decoration: const InputDecoration(
          hintText: 'e.g. Replaced carbon filter, pressure was low…',
          border: InputBorder.none,
          isDense: true,
          contentPadding:
              EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _DialogFooter extends StatelessWidget {
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _DialogFooter({
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: saving ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: saving ? null : onSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.task_alt_rounded, size: 18),
                    label: Text(saving ? 'Saving…' : 'Save & complete'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.label.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SkeletonField extends StatelessWidget {
  final String label;
  const _SkeletonField({this.label = 'Loading…'});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Text(label,
          style:
              AppTypography.body.copyWith(color: AppColors.textHint)),
    );
  }
}
