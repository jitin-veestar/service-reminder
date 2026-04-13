import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:service_reminder/core/services/pdf/receipt_pdf_input.dart';
import 'package:service_reminder/core/services/pdf/service_receipt_pdf_builder.dart';
import 'package:service_reminder/core/utils/date_time_utils.dart';
import 'package:service_reminder/core/utils/maps_utils.dart';
import 'package:service_reminder/core/utils/whatsapp_utils.dart';
import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/features/assigned_services/domain/assigned_service_status_rules.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/assigned_service.dart';
import 'package:service_reminder/features/assigned_services/presentation/providers/assigned_services_provider.dart';
import 'package:service_reminder/features/customers/domain/entities/customer.dart';
import 'package:service_reminder/features/dashboard/presentation/models/complete_visit_summary.dart';
import 'package:service_reminder/features/dashboard/presentation/utils/visit_whatsapp_messages.dart';
import 'package:service_reminder/features/dashboard/presentation/widgets/complete_visit_service_dialog.dart';
import 'package:service_reminder/features/dashboard/presentation/widgets/reschedule_visit_dialog.dart';
import 'package:service_reminder/features/subscription/presentation/pages/subscription_plans_page.dart';
import 'package:service_reminder/features/subscription/presentation/providers/subscription_provider.dart';

enum _CancelAction { keep, reschedule, cancel }

class DashboardVisitCard extends ConsumerStatefulWidget {
  final AssignedService visit;

  const DashboardVisitCard({super.key, required this.visit});

  @override
  ConsumerState<DashboardVisitCard> createState() => _DashboardVisitCardState();
}

class _DashboardVisitCardState extends ConsumerState<DashboardVisitCard> {
  bool _busy = false;

  AssignedService get _v => widget.visit;

  AssignedServiceStatus get _derived => AssignedServiceStatusRules.derive(_v);

  bool get _hasPhone =>
      _v.customerPhone != null && _v.customerPhone!.trim().isNotEmpty;

  bool get _hasAddress =>
      _v.customerAddress != null && _v.customerAddress!.trim().isNotEmpty;

  /// Only draft visits can set or change time from the card.
  bool get _canEditTime => _derived == AssignedServiceStatus.draft;

  String _timeDisplay() {
    final t = _v.scheduledTime?.trim();
    if (t == null || t.isEmpty) {
      return _canEditTime
          ? 'No time set — tap calendar'
          : 'No time set';
    }
    return DateTimeUtils.formatTime12HourFromHhMm(t);
  }

  bool get _timeUnset {
    final t = _v.scheduledTime?.trim();
    return t == null || t.isEmpty;
  }

  Future<void> _setBusy(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickTime() async {
    final tod = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted || tod == null) return;
    final ts =
        '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
    final st =
        AssignedServiceStatusRules.persistedAfterTimeSet(_v.scheduledDate, ts);
    await _setBusy(() async {
      await ref.read(dashboardVisitsProvider.notifier).patchVisit(
            _v.copyWith(scheduledTime: ts, status: st),
          );
    });
  }

  Future<void> _onCancel() async {
    final action = await showDialog<_CancelAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel visit'),
        content: const Text(
          'What would you like to do with this visit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _CancelAction.keep),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _CancelAction.reschedule),
            child: const Text('Reschedule'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _CancelAction.cancel),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Cancel visit'),
          ),
        ],
      ),
    );
    if (!mounted || action == null || action == _CancelAction.keep) return;

    if (action == _CancelAction.reschedule) {
      await _onReschedule();
      return;
    }

    await _setBusy(() async {
      await ref.read(dashboardVisitsProvider.notifier).cancelVisit(_v);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit cancelled.')),
      );
    }
  }

  Future<void> _onReschedule() async {
    if (!mounted) return;
    final data = await showDialog<RescheduleData>(
      context: context,
      builder: (ctx) => RescheduleVisitDialog(currentDate: _v.scheduledDate),
    );
    if (data == null || !mounted) return;
    await _setBusy(() async {
      await ref.read(dashboardVisitsProvider.notifier).rescheduleVisit(
            _v,
            newDate: data.newDate,
            newTime: data.newTime,
            reason: data.reason,
          );
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit rescheduled.')),
      );
    }
  }

  Future<void> _onComplete() async {
    var v = _v;
    if (_derived == AssignedServiceStatus.draft) {
      final tod = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (!mounted || tod == null) return;
      final ts =
          '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
      final st =
          AssignedServiceStatusRules.persistedAfterTimeSet(v.scheduledDate, ts);
      await _setBusy(() async {
        v = await ref.read(dashboardVisitsProvider.notifier).patchVisit(
              v.copyWith(scheduledTime: ts, status: st),
            );
      });
      if (!mounted) return;
    }

    final completionSummary = await showDialog<CompleteVisitSummary?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CompleteVisitServiceDialog(visit: v),
    );
    if (completionSummary == null || !mounted) return;

    final type = v.customerType ?? CustomerType.oneTime;
    int? oneTimeMonths;
    if (type == CustomerType.oneTime) {
      oneTimeMonths = await showDialog<int?>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Schedule next visit?'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 3),
              child: const Text('In 3 months'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 4),
              child: const Text('In 4 months'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 6),
              child: const Text('In 6 months'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('None'),
            ),
          ],
        ),
      );
      if (!mounted) return;
    }

    try {
      await _setBusy(() async {
        await ref.read(dashboardVisitsProvider.notifier).completeVisit(
              v,
              oneTimeFollowUpMonths:
                  type == CustomerType.oneTime ? oneTimeMonths : null,
            );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service saved and visit completed.'),
          ),
        );
        final premium = ref.read(subscriptionProvider).value?.hasWhatsAppAndPdfEntitlement ??
            false;
        if (premium) {
          await _openWhatsAppCompletion(
            customerName: v.customerName ?? '',
            phone: v.customerPhone,
            summary: completionSummary,
          );
          await _offerPdfReceiptShare(
            visit: v,
            summary: completionSummary,
          );
        } else if (mounted) {
          _showPremiumUpgradeSnack(
            'WhatsApp messages and PDF receipts are on the ₹499 plan (or included during your free trial).',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not complete: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Digits only, preserving a single leading `+` for country code.
  String? _normalizePhoneForTel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return hasPlus ? '+$digits' : digits;
  }

  static const Color _whatsappGreen = Color(0xFF25D366);

  void _showPremiumUpgradeSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Plans',
          onPressed: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const SubscriptionPlansPage(),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _whatsappReminder() async {
    final raw = _v.customerPhone?.trim();
    if (raw == null || raw.isEmpty || _busy) return;
    final msg = buildVisitReminderMessage(_v);
    try {
      final launched = await launchWhatsAppWithMessage(
        phoneRaw: raw,
        message: msg,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WhatsApp error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _offerPdfReceiptShare({
    required AssignedService visit,
    required CompleteVisitSummary summary,
  }) async {
    if (!mounted) return;
    final amountStr = summary.amountCharged > 0
        ? '₹${summary.amountCharged == summary.amountCharged.roundToDouble() ? summary.amountCharged.round() : summary.amountCharged.toStringAsFixed(2)}'
        : '₹0 (no amount entered)';
    final create = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PDF receipt'),
        content: Text(
          'Create a PDF receipt for $amountStr and share with the customer?\n\nYou can pick WhatsApp or any app from the share sheet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create & share'),
          ),
        ],
      ),
    );
    if (create != true || !mounted) return;

    try {
      final input = ReceiptPdfInput(
        visitId: visit.id,
        customerName: visit.customerName ?? 'Customer',
        customerPhone: visit.customerPhone,
        serviceName: summary.serviceName,
        servicedAt: summary.servicedAt,
        amountCharged: summary.amountCharged,
        notes: summary.notes,
        voiceNoteIncluded: summary.includedVoiceNote,
      );
      final file = await ServiceReceiptPdfBuilder.buildAndSaveTempFile(input);
      if (!mounted) return;

      final box = context.findRenderObject() as RenderBox?;
      Rect? shareOrigin;
      if (box != null && box.hasSize) {
        final o = box.localToGlobal(Offset.zero);
        shareOrigin =
            Rect.fromLTWH(o.dx, o.dy, box.size.width, box.size.height);
      }

      final receiptNo =
          ServiceReceiptPdfBuilder.receiptNumberFromVisitId(visit.id);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'application/pdf',
              name: 'service_receipt_$receiptNo.pdf',
            ),
          ],
          subject: 'Service receipt',
          title: 'Service receipt',
          text:
              'Service receipt — ${visit.customerName?.trim().isNotEmpty == true ? visit.customerName!.trim() : 'Customer'}',
          sharePositionOrigin: shareOrigin,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create receipt: $e')),
        );
      }
    }
  }

  Future<void> _openWhatsAppCompletion({
    required String customerName,
    required String? phone,
    required CompleteVisitSummary summary,
  }) async {
    final raw = phone?.trim();
    if (raw == null || raw.isEmpty) return;
    final msg = buildVisitCompletionMessage(
      customerName: customerName,
      summary: summary,
    );
    try {
      final launched = await launchWhatsAppWithMessage(
        phoneRaw: raw,
        message: msg,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp for completion message.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WhatsApp error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _callPhone() async {
    final raw = _v.customerPhone?.trim();
    if (raw == null || raw.isEmpty) return;
    final number = _normalizePhoneForTel(raw);
    if (number == null) return;

    final uri = Uri.parse('tel:$number');

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the phone app.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start call: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Status badge helpers ──────────────────────────────────────────────────

  String _statusLabel() => _derived.label;

  Color _statusColor() {
    switch (_derived) {
      case AssignedServiceStatus.draft:
        return const Color(0xFF854F0B);
      case AssignedServiceStatus.scheduled:
        return const Color(0xFF0F6E56);
      case AssignedServiceStatus.overdue:
        return const Color(0xFFA32D2D);
      default:
        return AppColors.textSecondary;
    }
  }

  Color _statusBadgeBg() {
    switch (_derived) {
      case AssignedServiceStatus.draft:
        return const Color(0xFFFAEEDA);
      case AssignedServiceStatus.scheduled:
        return const Color(0xFFE1F5EE);
      case AssignedServiceStatus.overdue:
        return const Color(0xFFFCEBEB);
      default:
        return AppColors.border;
    }
  }

  Color _timeTextColor() {
    if (_timeUnset) return const Color(0xFFD85A30);
    if (_derived == AssignedServiceStatus.overdue) return const Color(0xFFA32D2D);
    return AppColors.textSecondary;
  }

  Color _statusAccentColor() {
    switch (_derived) {
      case AssignedServiceStatus.draft:
        return AppColors.warning;
      case AssignedServiceStatus.scheduled:
        return AppColors.success;
      case AssignedServiceStatus.overdue:
        return AppColors.error;
      default:
        return AppColors.border;
    }
  }

  // ── Avatar helper ─────────────────────────────────────────────────────────

  String _avatarInitials() {
    final name = _v.customerName?.trim() ?? '';
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final service = _v.serviceOfferingName?.trim();
    final premiumMessaging =
        ref.watch(subscriptionProvider).value?.hasWhatsAppAndPdfEntitlement ??
            false;

    // Latest reschedule note (if any)
    final rescheduled = (_v.notes
            .where((n) => n.status == 'rescheduled')
            .toList()
          ..sort((a, b) => b.noteTime.compareTo(a.noteTime)))
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13.5),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left status accent bar ──────────────────────────────
              Container(width: 4, color: _statusAccentColor()),

              // ── Card body ───────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Info row ──────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                AppColors.primaryLight.withValues(alpha: 0.15),
                            child: Text(
                              _avatarInitials(),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Name / service / time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _v.customerName ?? 'Unknown customer',
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (service != null && service.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    service,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 5),
                                // Time row — tappable when draft to set time
                                GestureDetector(
                                  onTap: _canEditTime && !_busy
                                      ? _pickTime
                                      : null,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 13,
                                        color: _timeTextColor(),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _timeDisplay(),
                                        style: AppTypography.caption.copyWith(
                                          color: _timeTextColor(),
                                          fontWeight: _timeUnset
                                              ? FontWeight.w500
                                              : FontWeight.w400,
                                        ),
                                      ),
                                      if (_canEditTime) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.edit_rounded,
                                          size: 11,
                                          color: _timeTextColor(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _statusBadgeBg(),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel(),
                              style: AppTypography.caption.copyWith(
                                color: _statusColor(),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ── Reschedule note (slim inline) ─────────────
                      if (rescheduled != null) ...[
                        const SizedBox(height: 9),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.event_repeat_rounded,
                              size: 13,
                              color: Color(0xFFF57F17),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Rescheduled: ${rescheduled.message}',
                                style: AppTypography.caption.copyWith(
                                  color: const Color(0xFF8D6110),
                                  fontSize: 11.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 10),

                      // ── Contact icons + cancel ────────────────────
                      Row(
                        children: [
                          _SmallIconButton(
                            icon: Icons.phone_outlined,
                            tooltip: _hasPhone ? 'Call' : 'No phone',
                            onTap: (_busy || !_hasPhone) ? null : _callPhone,
                            disabled: !_hasPhone,
                            iconColor: _hasPhone ? AppColors.success : null,
                          ),
                          const SizedBox(width: 6),
                          _SmallIconButton(
                            faIcon: FontAwesomeIcons.whatsapp,
                            tooltip: !_hasPhone
                                ? 'No phone'
                                : (premiumMessaging
                                    ? 'WhatsApp reminder'
                                    : 'WhatsApp — ₹499 or free trial'),
                            onTap: (_busy || !_hasPhone)
                                ? null
                                : () {
                                    if (!premiumMessaging) {
                                      _showPremiumUpgradeSnack(
                                        'WhatsApp reminders need the ₹499 plan or an active free trial.',
                                      );
                                      return;
                                    }
                                    _whatsappReminder();
                                  },
                            disabled: !_hasPhone,
                            iconColor: _hasPhone
                                ? (premiumMessaging
                                    ? _whatsappGreen
                                    : AppColors.textHint)
                                : null,
                          ),
                          const SizedBox(width: 6),
                          _SmallIconButton(
                            icon: Icons.map_outlined,
                            tooltip: _hasAddress ? 'Maps' : 'No address',
                            onTap: (_busy || !_hasAddress)
                                ? null
                                : () => MapsUtils.openInMaps(
                                    _v.customerAddress!),
                            disabled: !_hasAddress,
                            iconColor:
                                _hasAddress ? AppColors.primary : null,
                          ),
                          const Spacer(),
                          // Cancel — subtle text link
                          GestureDetector(
                            onTap: _busy ? null : _onCancel,
                            child: Opacity(
                              opacity: _busy ? 0.4 : 1.0,
                              child: Text(
                                'Cancel',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ── Mark complete — full-width primary CTA ────
                      SizedBox(
                        height: 40,
                        child: FilledButton(
                          onPressed: _busy ? null : _onComplete,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Mark complete'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small icon button widget ───────────────────────────────────────────────

class _SmallIconButton extends StatelessWidget {
  final IconData? icon;
  final IconData? faIcon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool disabled;
  final Color? iconColor;

  const _SmallIconButton({
    this.icon,
    this.faIcon,
    required this.tooltip,
    this.onTap,
    this.disabled = false,
    this.iconColor,
  }) : assert(icon != null || faIcon != null);

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.textSecondary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedOpacity(
          opacity: disabled ? 0.35 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            alignment: Alignment.center,
            child: faIcon != null
                ? FaIcon(faIcon!, size: 15, color: color)
                : Icon(icon!, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}