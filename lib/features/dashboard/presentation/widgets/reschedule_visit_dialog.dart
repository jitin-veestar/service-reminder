import 'package:flutter/material.dart';

import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/core/utils/date_time_utils.dart';

class RescheduleData {
  final DateTime newDate;
  final String? newTime; // "HH:mm" or null
  final String reason;

  const RescheduleData({
    required this.newDate,
    required this.newTime,
    required this.reason,
  });
}

/// Dialog that collects a new date, optional time, and a reason for rescheduling.
/// Returns [RescheduleData] on confirm, null if dismissed.
class RescheduleVisitDialog extends StatefulWidget {
  final DateTime currentDate;

  const RescheduleVisitDialog({super.key, required this.currentDate});

  @override
  State<RescheduleVisitDialog> createState() => _RescheduleVisitDialogState();
}

class _RescheduleVisitDialogState extends State<RescheduleVisitDialog> {
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.currentDate;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final initial = _selectedTime ?? TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _clearTime() => setState(() => _selectedTime = null);

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    String? timeStr;
    if (_selectedTime != null) {
      timeStr =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
    }
    Navigator.pop(
      context,
      RescheduleData(
        newDate: _selectedDate,
        newTime: timeStr,
        reason: _reasonController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateTimeUtils.formatDate(_selectedDate);
    final timeLabel = _selectedTime != null
        ? _selectedTime!.format(context)
        : 'Not set (tap to add)';

    return AlertDialog(
      title: const Text('Reschedule visit'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── New date ──────────────────────────────────────────────
              Text(
                'New date',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(dateLabel, style: AppTypography.body),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── New time (optional) ───────────────────────────────────
              Text(
                'New time (optional)',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              timeLabel,
                              style: AppTypography.body.copyWith(
                                color: _selectedTime == null
                                    ? AppColors.textHint
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_selectedTime != null) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: _clearTime,
                      tooltip: 'Clear time',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 14),

              // ── Reason ────────────────────────────────────────────────
              Text(
                'Reason for rescheduling',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'e.g. Customer not available, called and rescheduled',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back'),
        ),
        FilledButton.icon(
          onPressed: _confirm,
          icon: const Icon(Icons.event_repeat_outlined, size: 16),
          label: const Text('Reschedule'),
        ),
      ],
    );
  }
}
