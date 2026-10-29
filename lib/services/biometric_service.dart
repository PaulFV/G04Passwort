import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Kind of biometric hardware, used to pick the right icon/label.
enum BiometricKind { none, fingerprint, face, generic }

/// Wraps `local_auth` (Fingerprint, Face ID, Windows Hello).
class BiometricService {
  BiometricService([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Whether the device can authenticate the user biometrically.
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      return await _auth.canCheckBiometrics;
    } on Object {
      return false;
    }
  }

  /// Best guess of the available biometric type for UI purposes.
  Future<BiometricKind> kind() async {
    if (!await isAvailable()) return BiometricKind.none;
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return BiometricKind.face;
      if (types.contains(BiometricType.fingerprint)) return BiometricKind.fingerprint;
      return BiometricKind.generic;
    } on Object {
      return BiometricKind.generic;
    }
  }

  /// Shows the system biometric prompt. Returns `true` on success.
  Future<bool> authenticate({
    String reason = 'Entsperre deinen G04Passwort-Tresor',
  }) async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      debugPrint('Biometric authentication failed: ${e.code}');
      return false;
    } on Object catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }
}
