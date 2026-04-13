/// Data required to render a service receipt / invoice PDF.
class ReceiptPdfInput {
  final String visitId;
  final String customerName;
  final String? customerPhone;
  final String? serviceName;
  final DateTime servicedAt;
  final double amountCharged;
  final String? notes;
  final bool voiceNoteIncluded;

  const ReceiptPdfInput({
    required this.visitId,
    required this.customerName,
    this.customerPhone,
    this.serviceName,
    required this.servicedAt,
    required this.amountCharged,
    this.notes,
    required this.voiceNoteIncluded,
  });
}
