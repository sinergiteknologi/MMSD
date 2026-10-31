class AppConfig {
  static const String defaultServiceHost = 'api.sinergiteknologi.co.id';
  static const String defaultServiceBaseUrl =
      'https://api.sinergiteknologi.co.id/ApiNewMMSDMobile';
  static const String dbServer = '100.120.64.117';
  static const String dbName = 'NewMMDacen';
  static const String getUserUrl =
      'https://api.sinergiteknologi.co.id/NewMMSDMobileServices/mobileservices.asmx';

      
  static const String defaultCabang = '0001';
  static const int currentVersionCode = 117;
  static const String currentVersionName = '10.16';
  static const String androidPackageName = 'com.smartsoft.NewMMSD';

  static String get playStoreUrl =>
      'https://play.google.com/store/apps/details?id=$androidPackageName';

  static bool _isPrivateHost(String host) {
    final value = host.toLowerCase();
    return value == 'localhost' ||
        value.startsWith('10.') ||
        value.startsWith('127.') ||
        value.startsWith('192.168.') ||
        RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').hasMatch(value);
  }

  static String serviceUrl(String server) {
    final raw = server.trim();
    if (raw.isEmpty) return 'https://$defaultServiceHost';
    final uri = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
    if (uri == null || uri.host.isEmpty) return 'https://$defaultServiceHost';
    final scheme = _isPrivateHost(uri.host)
        ? (uri.scheme.isEmpty ? 'http' : uri.scheme)
        : 'https';
    return '$scheme://${uri.host}';
  }

  static String defaultServiceUrl() => serviceUrl(defaultServiceHost);
}
