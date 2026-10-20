import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class LaunchUtil {
  static String _digits(String phone) =>
      phone.replaceAll(RegExp(r'[^0-9+]'), '');

  static Future<void> call(String phone) async {
    final uri = Uri(scheme: 'tel', path: _digits(phone));
    await launchUrl(uri);
  }

  static Future<void> whatsapp(String phone, [String message = '']) async {
    var digits = _digits(phone);
    if (digits.startsWith('0')) digits = '62${digits.substring(1)}';
    final uri = Uri.parse(
      'https://wa.me/$digits${message.isEmpty ? '' : '?text=${Uri.encodeComponent(message)}'}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> sms(String phone) async {
    final uri = Uri(scheme: 'sms', path: _digits(phone));
    await launchUrl(uri);
  }

  static Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
