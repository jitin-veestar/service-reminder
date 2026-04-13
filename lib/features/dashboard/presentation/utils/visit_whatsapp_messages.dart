import 'package:intl/intl.dart';

import 'package:service_reminder/core/utils/date_time_utils.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/assigned_service.dart';
import 'package:service_reminder/features/dashboard/presentation/models/complete_visit_summary.dart';

String buildVisitReminderMessage(AssignedService visit) {
  final name = (visit.customerName?.trim().isNotEmpty ?? false)
      ? visit.customerName!.trim()
      : 'there';
  final service = visit.serviceOfferingName?.trim();
  final dateStr = DateFormat('EEEE, d MMM yyyy').format(visit.scheduledDate);
  final timeRaw = visit.scheduledTime?.trim();
  final timeStr = (timeRaw != null && timeRaw.isNotEmpty)
      ? DateTimeUtils.formatTime12HourFromHhMm(timeRaw)
      : null;

  final servicePhrase = (service != null && service.isNotEmpty)
      ? 'your $service service visit'
      : 'your scheduled service visit';

  final buf = StringBuffer()
    ..write('Hello $name,\n\n')
    ..write('This is a reminder for $servicePhrase on $dateStr');
  if (timeStr != null) {
    buf.write(' at $timeStr');
  }
  buf.write(
    '.\n\nPlease reply if you need to reschedule.\n\nThank you!',
  );
  return buf.toString();
}

String buildVisitCompletionMessage({
  required String customerName,
  required CompleteVisitSummary summary,
}) {
  final name =
      customerName.trim().isEmpty ? 'there' : customerName.trim();
  final dateStr = DateFormat('d MMM yyyy').format(summary.servicedAt);
  final service = summary.serviceName?.trim();
  final amountStr =
      summary.amountCharged == summary.amountCharged.roundToDouble()
          ? '₹${summary.amountCharged.round()}'
          : '₹${summary.amountCharged.toStringAsFixed(2)}';

  final buf = StringBuffer()
    ..write('Hello $name,\n\n')
    ..write(
      'Thank you — we have completed your service visit on $dateStr.\n\n',
    );

  if (service != null && service.isNotEmpty) {
    buf.write('Service: $service\n');
  }
  buf.write('Amount: $amountStr\n');

  if (summary.includedVoiceNote) {
    buf.write('(A voice note was added to your service record.)\n');
  }

  final notes = summary.notes?.trim();
  if (notes != null && notes.isNotEmpty) {
    final clipped =
        notes.length > 400 ? '${notes.substring(0, 397)}...' : notes;
    buf.write('\nNotes: $clipped\n');
  }

  buf.write('\nThank you for choosing us!');
  return buf.toString();
}
