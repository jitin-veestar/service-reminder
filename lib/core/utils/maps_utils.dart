import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsUtils {
  MapsUtils._();

  /// Opens [address] in Google Maps (directions mode).
  static Future<void> openInMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$encoded',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[MapsUtils] Could not open maps: $e');
    }
  }
}
