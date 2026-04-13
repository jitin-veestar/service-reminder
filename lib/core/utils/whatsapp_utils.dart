import 'package:url_launcher/url_launcher.dart';

/// Digits-only international number for `https://wa.me/<digits>` (no + or spaces).
String? normalizePhoneDigitsForWhatsApp(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  return digits;
}

Future<bool> launchWhatsAppWithMessage({
  required String phoneRaw,
  required String message,
}) async {
  final digits = normalizePhoneDigitsForWhatsApp(phoneRaw);
  if (digits == null) return false;
  final uri = Uri(
    scheme: 'https',
    host: 'wa.me',
    path: '/$digits',
    queryParameters: {'text': message},
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
