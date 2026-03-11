import 'package:url_launcher/url_launcher.dart';

class MapsLauncher {
  static Future<bool> open(double lat, double lng) async {
    try {
      final uri = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
      if (!await canLaunchUrl(uri)) return false;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
