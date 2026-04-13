import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:service_reminder/core/services/pdf/receipt_pdf_input.dart';

/// Builds a simple A4 PDF receipt for sharing (e.g. WhatsApp).
abstract final class ServiceReceiptPdfBuilder {
  static String receiptNumberFromVisitId(String visitId) {
    final clean = visitId.replaceAll('-', '');
    if (clean.length >= 8) return clean.substring(0, 8).toUpperCase();
    return visitId.hashCode.abs().toRadixString(36).toUpperCase();
  }

  static String _amountLabel(double amount) {
    if (amount == amount.roundToDouble()) {
      return '₹${amount.round()}';
    }
    return '₹${amount.toStringAsFixed(2)}';
  }

  static Future<File> buildAndSaveTempFile(ReceiptPdfInput input) async {
    final receiptNo = receiptNumberFromVisitId(input.visitId);
    final dateFmt = DateFormat('d MMM yyyy');
    final titleStyle = pw.TextStyle(
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
    );
    final labelStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 11,
    );
    final bodyStyle = const pw.TextStyle(fontSize: 11);
    final smallStyle = pw.TextStyle(
      fontSize: 9,
      color: PdfColors.grey700,
    );

    final customer = input.customerName.trim().isEmpty
        ? 'Customer'
        : input.customerName.trim();
    final serviceLine = input.serviceName?.trim();
    final phone = input.customerPhone?.trim();
    final notes = input.notes?.trim();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (pw.Context context) => [
          pw.Text('SERVICE RECEIPT', style: titleStyle),
          pw.SizedBox(height: 4),
          pw.Text('RO & Water Filter Service', style: smallStyle),
          pw.SizedBox(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Receipt no.', style: labelStyle),
                  pw.Text(receiptNo, style: bodyStyle),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Service date', style: labelStyle),
                  pw.Text(dateFmt.format(input.servicedAt), style: bodyStyle),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
          pw.SizedBox(height: 12),
          pw.Text('Bill to', style: labelStyle),
          pw.SizedBox(height: 4),
          pw.Text(customer, style: bodyStyle.copyWith(fontSize: 12)),
          if (phone != null && phone.isNotEmpty)
            pw.Text(phone, style: bodyStyle),
          pw.SizedBox(height: 20),
          pw.Text('Description', style: labelStyle),
          pw.SizedBox(height: 6),
          pw.Text(
            (serviceLine != null && serviceLine.isNotEmpty)
                ? serviceLine
                : 'Service visit',
            style: bodyStyle.copyWith(fontSize: 12),
          ),
          if (input.voiceNoteIncluded) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Voice note attached to service record.',
              style: smallStyle,
            ),
          ],
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Amount charged', style: labelStyle.copyWith(fontSize: 12)),
                pw.Text(
                  _amountLabel(input.amountCharged),
                  style: titleStyle.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
          if (notes != null && notes.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('Notes', style: labelStyle),
            pw.SizedBox(height: 6),
            pw.Text(notes, style: bodyStyle),
          ],
          pw.SizedBox(height: 32),
          pw.Divider(thickness: 0.5, color: PdfColors.grey300),
          pw.SizedBox(height: 12),
          pw.Text(
            'Thank you for your business.',
            style: bodyStyle.copyWith(
              color: PdfColors.grey800,
              fontStyle: pw.FontStyle.italic,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final safeStub = customer
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    final stub = safeStub.isEmpty ? 'customer' : safeStub.substring(0, safeStub.length.clamp(0, 24));
    final file = File('${dir.path}/receipt_${receiptNo}_$stub.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
