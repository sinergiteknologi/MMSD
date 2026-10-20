class PwaInstall {
  const PwaInstall._();

  static bool get isInstalled => true;

  static bool get canPrompt => false;

  static bool get shouldShowInstall => false;

  static void onAvailable(void Function() callback) {}

  static Future<bool> promptInstall() async => false;
}
