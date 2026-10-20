class AppConfig {
  static const String defaultServiceHost = 'api.sinergiteknologi.co.id';
  // static const String defaultServiceHost = '127.0.0.1:3000';
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
    var host = server.replaceAll(RegExp(r'^https?://'), '');
    host = host.split('/').first;
    if (host.isEmpty) host = defaultServiceHost;
    if (!host.contains(':')) host = '$host:3000';
    return 'http://$host';
  }

  static String defaultServiceUrl() => serviceUrl(defaultServiceHost);
}
