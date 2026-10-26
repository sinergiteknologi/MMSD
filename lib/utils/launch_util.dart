import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
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

  /// Buka URL website. Android/iOS dipaksa Google Chrome jika terpasang;
  /// jika tidak ada Chrome, fallback Safari / browser default.
  static Future<bool> openWebsite(String url) async {
    var normalized = url.trim();
    if (normalized.isEmpty) return false;
    if (!normalized.contains('://')) normalized = 'https://$normalized';
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty) return false;

    if (!kIsWeb) {
      if (Platform.isAndroid) {
        final opened = await _openInChromeAndroid(uri);
        if (opened) return true;
      } else if (Platform.isIOS) {
        final opened = await _openInChromeIos(uri);
        if (opened) return true;
      }
    }

    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static Future<bool> _openInChromeAndroid(Uri uri) async {
    final pathAndQuery = uri.hasQuery
        ? '${uri.host}${uri.path}?${uri.query}'
        : '${uri.host}${uri.path}';
    final intentUri = Uri.parse(
      'intent://$pathAndQuery#Intent;scheme=${uri.scheme};package=com.android.chrome;end',
    );
    try {
      if (await canLaunchUrl(intentUri)) {
        final ok = await launchUrl(
          intentUri,
          mode: LaunchMode.externalApplication,
        );
        if (ok) return true;
      }
    } catch (_) {}

    final chromeUri = Uri.parse(
      'googlechrome://navigate?url=${Uri.encodeFull(uri.toString())}',
    );
    try {
      if (await canLaunchUrl(chromeUri)) {
        return launchUrl(chromeUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  /// iOS Chrome: https → googlechromes:// , http → googlechrome://
  static Future<bool> _openInChromeIos(Uri uri) async {
    final chromeScheme =
        uri.scheme.toLowerCase() == 'http' ? 'googlechrome' : 'googlechromes';
    final chromeUri = uri.replace(scheme: chromeScheme);
    try {
      if (await canLaunchUrl(chromeUri)) {
        return launchUrl(chromeUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }
}
