import 'dart:js_interop';

@JS('mmsdPwaCanPrompt')
external bool _canPrompt();

@JS('mmsdPwaIsInstalled')
external bool _isInstalled();

@JS('mmsdPwaPromptInstall')
external JSPromise<JSBoolean> _promptInstall();

@JS('mmsdPwaOnAvailable')
external void _onAvailable(JSFunction callback);

class PwaInstall {
  const PwaInstall._();

  static bool get isInstalled => _isInstalled();

  static bool get canPrompt => _canPrompt();

  static bool get shouldShowInstall => !_isInstalled();

  static void onAvailable(void Function() callback) {
    _onAvailable(callback.toJS);
  }

  static Future<bool> promptInstall() async {
    final result = await _promptInstall().toDart;
    return result.toDart;
  }
}
