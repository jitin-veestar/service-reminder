/// Payload returned when the user successfully saves a service record from
/// [CompleteVisitServiceDialog], used for follow-up actions (e.g. WhatsApp).
class CompleteVisitSummary {
  final String? serviceName;
  final DateTime servicedAt;
  final double amountCharged;
  final String? notes;
  final bool includedVoiceNote;

  const CompleteVisitSummary({
    required this.serviceName,
    required this.servicedAt,
    required this.amountCharged,
    this.notes,
    required this.includedVoiceNote,
  });
}
