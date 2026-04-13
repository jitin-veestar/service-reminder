import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'package:service_reminder/core/services/storage/service_recordings_upload.dart';
import 'package:service_reminder/core/services/supabase/supabase_client_provider.dart';
import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/core/utils/date_time_utils.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/assigned_service.dart';
import 'package:service_reminder/features/assigned_services/presentation/providers/assigned_services_provider.dart';
import 'package:service_reminder/features/service_catalog/domain/entities/service_offering.dart';
import 'package:service_reminder/features/service_catalog/presentation/providers/service_offerings_providers.dart';
import 'package:service_reminder/features/services/presentation/providers/service_record_controller.dart';
import 'package:service_reminder/features/services/presentation/widgets/service_notes_field.dart';
import 'package:service_reminder/features/services/presentation/widgets/voice_note_panel.dart';
import 'package:service_reminder/shared/widgets/primary_button.dart';

class ServiceRecordFormPage extends ConsumerWidget {
  final String customerId;

  const ServiceRecordFormPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeAssignmentForCustomerProvider(customerId));
    return async.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Record Service', style: AppTypography.heading2),
          backgroundColor: AppColors.surface,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Record Service', style: AppTypography.heading2),
          backgroundColor: AppColors.surface,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$e', style: AppTypography.bodySmall),
          ),
        ),
      ),
      data: (assignment) => _ServiceRecordFormBody(
        key: ValueKey('${assignment?.id ?? 'none'}_$customerId'),
        customerId: customerId,
        assignment: assignment,
      ),
    );
  }
}

class _ServiceRecordFormBody extends ConsumerStatefulWidget {
  final String customerId;
  final AssignedService? assignment;

  const _ServiceRecordFormBody({
    super.key,
    required this.customerId,
    required this.assignment,
  });

  @override
  ConsumerState<_ServiceRecordFormBody> createState() =>
      _ServiceRecordFormBodyState();
}

class _ServiceRecordFormBodyState extends ConsumerState<_ServiceRecordFormBody> {
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();
  final _recorder = AudioRecorder();

  late DateTime _servicedAt;
  String? _selectedCatalogId;
  bool _amountPrimed = false;

  bool _isRecording = false;
  bool _isPaused = false;
  String? _localRecordingPath;
  Timer? _ampTimer;
  final List<double> _barLevels = List<double>.filled(7, 0.08);

  @override
  void initState() {
    super.initState();
    final a = widget.assignment;
    final d = a?.scheduledDate ?? DateTime.now();
    _servicedAt = DateTime(d.year, d.month, d.day);
    _selectedCatalogId = a?.serviceOfferingId;
  }

  @override
  void dispose() {
    _ampTimer?.cancel();
    _recorder.dispose();
    _notesController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _applyCatalogPrice(ServiceOffering? offering) {
    if (offering?.defaultPrice != null) {
      final p = offering!.defaultPrice!;
      _amountController.text = p == p.roundToDouble()
          ? p.round().toString()
          : p.toStringAsFixed(2);
    }
  }

  void _maybePrimeAmount(List<ServiceOffering> offerings) {
    if (_amountPrimed || offerings.isEmpty) return;
    final id = _selectedCatalogId;
    if (id == null || id.isEmpty) return;
    for (final o in offerings) {
      if (o.id == id) {
        if (!mounted) return;
        setState(() {
          _applyCatalogPrice(o);
          _amountPrimed = true;
        });
        break;
      }
    }
  }

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
      if (_localRecordingPath != null) {
        setState(() {
          _localRecordingPath = null;
        });
      }
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required to record.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/sr_${DateTime.now().millisecondsSinceEpoch}.m4a';
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _recorder.pause();
      if (mounted) setState(() => _isPaused = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pause failed: $e')),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resume failed: $e')),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stop failed: $e')),
        );
      }
    }
  }

  void _clearRecording() {
    setState(() => _localRecordingPath = null);
  }

  Future<void> _submit() async {
    if (!kIsWeb && await _recorder.isRecording()) {
      _stopAmplitudeTicker();
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _localRecordingPath = path;
      });
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    String? audioPath;
    if (!kIsWeb && _localRecordingPath != null) {
      try {
        final client = ref.read(supabaseClientProvider);
        audioPath = await uploadServiceRecording(
          client: client,
          customerId: widget.customerId,
          localFilePath: _localRecordingPath!,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not upload recording: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    final saved = await ref
        .read(serviceRecordControllerProvider(widget.customerId).notifier)
        .submit(
          servicedAt: _servicedAt,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          filterChanged: false,
          membraneChecked: false,
          cleaningDone: false,
          leakageFixed: false,
          amountCharged: amount,
          catalogServiceId: _selectedCatalogId,
          audioStoragePath: audioPath,
        );

    if (saved && mounted) Navigator.of(context).pop();
  }

  String get _serviceTitle {
    final n = widget.assignment?.serviceOfferingName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return 'Service visit';
  }

  @override
  Widget build(BuildContext context) {
    final formState =
        ref.watch(serviceRecordControllerProvider(widget.customerId));
    final isLoading = formState is AsyncLoading;
    final offeringsAsync = ref.watch(serviceOfferingsListProvider);

    ref.listen<AsyncValue<List<ServiceOffering>>>(
      serviceOfferingsListProvider,
      (prev, next) {
        if (next is AsyncData<List<ServiceOffering>>) {
          _maybePrimeAmount(next.value);
        }
      },
    );
    offeringsAsync.whenData(_maybePrimeAmount);

    ref.listen<AsyncValue<void>>(
      serviceRecordControllerProvider(widget.customerId),
      (_, next) {
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
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Record Service', style: AppTypography.heading2),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From assignment',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        DateTimeUtils.formatDate(_servicedAt),
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.build_outlined,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _serviceTitle,
                          style: AppTypography.body,
                        ),
                      ),
                    ],
                  ),
                  if (widget.assignment == null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'No open assignment for this customer — using today\'s date.',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Next service: ${DateTimeUtils.formatDate(DateTimeUtils.nextServiceDate(_servicedAt))}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text('Amount (₹)', style: AppTypography.label),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('₹',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      style: AppTypography.body,
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text('Voice note', style: AppTypography.label),
            const SizedBox(height: 10),
            if (kIsWeb)
              Text(
                'Recording is available on iOS and Android.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              )
            else
              VoiceNotePanel(
                isLoading: isLoading,
                isRecording: _isRecording,
                isPaused: _isPaused,
                hasClip: _localRecordingPath != null,
                barLevels: _barLevels,
                onMic: _startRecording,
                onPause: _pauseRecording,
                onResume: _resumeRecording,
                onStop: _stopRecording,
                onDelete: _clearRecording,
              ),

            const SizedBox(height: 24),

            ServiceNotesField(controller: _notesController),

            const SizedBox(height: 28),

            PrimaryButton(
              label: 'Save Service Record',
              isLoading: isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
