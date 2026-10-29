import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Screenshot / screen-recording protection.
///
/// * Android: toggles `FLAG_SECURE` via the `g04passwort/security` channel
///   implemented in `MainActivity.kt` (also hides the recent-apps preview).
/// * All platforms: the app additionally shows a privacy shield whenever it
///   is inactive or in the background (see `PrivacyShield`).
class ScreenProtectionService {
  static const _channel = MethodChannel('g04passwort/security');

  Future<void> setEnabled(bool enabled) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<bool>('setSecureScreen', {'enabled': enabled});
    } on MissingPluginException {
      // Running in a test or an unsupported embedder.
    } on PlatformException catch (e) {
      debugPrint('Screen protection failed: ${e.message}');
    }
  }
}
