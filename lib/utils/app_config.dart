class AppConfig {
  static const String defaultServiceHost = 'api.sinergiteknologi.co.id';
  static const String defaultServiceBaseUrl =
      'http://api.sinergiteknologi.co.id/ApiNewMMSDMobile';
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

  static String serviceUrl(String server) {
    final raw = server.trim();
    if (raw.isEmpty) return 'http://$defaultServiceHost';
    final uri = Uri.tryParse(raw.contains('://') ? raw : 'http://$raw');
    if (uri == null || uri.host.isEmpty) return 'http://$defaultServiceHost';
    final scheme = uri.scheme.isEmpty ? 'http' : uri.scheme;
    return '$scheme://${uri.host}';
  }

  static String defaultServiceUrl() => serviceUrl(defaultServiceHost);
}
