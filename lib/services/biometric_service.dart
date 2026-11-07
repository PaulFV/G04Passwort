import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../core/l10n/l10n.dart';
import 'passkey/passkey_bridge.dart';

/// Kind of biometric hardware, used to pick the right icon/label.
enum BiometricKind { none, fingerprint, face, generic }

/// Result of a biometric check.
///
/// On the web, [secret] is the passkey PRF output that encrypts the stored
/// vault key; native platforms keep the key in the OS keychain instead and
/// return no secret.
@immutable
class BiometricResult {
  const BiometricResult.success([this.secret, this.credentialId])
    : ok = true,
      error = null;

  const BiometricResult.failure(this.error)
    : ok = false,
      secret = null,
      credentialId = null;

  /// User cancelled – no message needed.
  const BiometricResult.cancelled()
    : ok = false,
      error = null,
      secret = null,
      credentialId = null;

  final bool ok;
  final Uint8List? secret;
  final String? credentialId;

  /// User facing German error, `null` when cancelled.
  final String? error;
}

/// Result of setting up biometric unlock.
@immutable
class BiometricEnrollment {
  const BiometricEnrollment({
    required this.ok,
    this.secret,
    this.credentialId,
    this.needsConfirmation = false,
    this.error,
  });

  final bool ok;
  final Uint8List? secret;

  /// Passkey id (web only).
  final String? credentialId;

  /// The passkey was created, but the browser only reveals the secret on
  /// a second Face ID check (Safari). Call [BiometricService.authenticate]
  /// from another tap.
  final bool needsConfirmation;
  final String? error;
}

/// Fingerprint / Face ID / Windows Hello.
///
/// Native platforms use `local_auth`. The web app uses a passkey (WebAuthn
/// with the PRF extension) – on an iPhone this shows the Face ID prompt.
class BiometricService {
  BiometricService([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  static String get unsupportedWebMessage =>
      tr('Dieser Browser unterstützt Face ID für Web-Apps noch nicht. '
      'Benötigt wird iOS/iPadOS 18 oder neuer bzw. ein aktuelles Chrome, '
      'Edge oder Safari mit Passkey-Unterstützung.');

  /// Whether the device can authenticate the user biometrically.
  Future<bool> isAvailable() async {
    if (kIsWeb) {
      final r = await PasskeyBridge.available();
      return r['platform'] == true && r['prf'] != false;
    }
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
    if (kIsWeb) {
      return switch (defaultTargetPlatform) {
        TargetPlatform.iOS || TargetPlatform.macOS => BiometricKind.face,
        TargetPlatform.android => BiometricKind.fingerprint,
        _ => BiometricKind.generic,
      };
    }
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return BiometricKind.face;
      if (types.contains(BiometricType.fingerprint)) {
        return BiometricKind.fingerprint;
      }
      return BiometricKind.generic;
    } on Object {
      return BiometricKind.generic;
    }
  }

  /// Shows the biometric prompt.
  ///
  /// On the web this must be called synchronously from a tap handler and
  /// [credentialId] should be the passkey created by [enroll].
  Future<BiometricResult> authenticate({
    String? reason,
    String? credentialId,
  }) async {
    if (kIsWeb) {
      // No await before this call: the browser needs the user gesture.
      final r = await PasskeyBridge.get(credentialId);
      if (r['ok'] == true) {
        return BiometricResult.success(
          base64Decode(r['secret']! as String),
          r['id'] as String?,
        );
      }
      return _webFailure(r);
    }
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason ?? tr('Entsperre deinen G04Passwort-Tresor'),
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      return ok
          ? const BiometricResult.success()
          : const BiometricResult.cancelled();
    } on LocalAuthException catch (e) {
      debugPrint('Biometric authentication failed: ${e.code}');
      return BiometricResult.failure(
        tr('Biometrische Bestätigung fehlgeschlagen'),
      );
    } on Object catch (e) {
      debugPrint('Biometric authentication error: $e');
      return BiometricResult.failure(
        tr('Biometrische Bestätigung fehlgeschlagen'),
      );
    }
  }

  /// Sets up biometric unlock. On the web this registers a passkey and must
  /// be called synchronously from a tap handler.
  Future<BiometricEnrollment> enroll({
    String? reason,
  }) async {
    if (!kIsWeb) {
      final r = await authenticate(
        reason: reason ?? tr('Biometrisches Entsperren für G04Passwort aktivieren'),
      );
      return BiometricEnrollment(ok: r.ok, error: r.error);
    }
    final r = await PasskeyBridge.create();
    if (r['ok'] != true) {
      final f = _webFailure(r);
      return BiometricEnrollment(ok: false, error: f.error);
    }
    final id = r['id']! as String;
    final secret = r['secret'] as String?;
    if (secret != null) {
      return BiometricEnrollment(
        ok: true,
        secret: base64Decode(secret),
        credentialId: id,
      );
    }
    if (r['prfEnabled'] == false) {
      return BiometricEnrollment(ok: false, error: unsupportedWebMessage);
    }
    // Passkey exists, secret follows with the next Face ID check.
    return BiometricEnrollment(
      ok: true,
      credentialId: id,
      needsConfirmation: true,
    );
  }

  BiometricResult _webFailure(Map<String, Object?> r) {
    debugPrint('Passkey: ${r['error']} ${r['message'] ?? ''}');
    return switch (r['error']) {
      'cancelled' => const BiometricResult.cancelled(),
      'unsupported' || 'noprf' => BiometricResult.failure(
        unsupportedWebMessage,
      ),
      'insecure' => BiometricResult.failure(
        tr('Face ID funktioniert nur über eine sichere Verbindung (https).'),
      ),
      'exists' => BiometricResult.failure(
        tr('Für diese Web-App ist bereits ein Passkey vorhanden.'),
      ),
      _ => BiometricResult.failure(
        tr('Face ID konnte nicht verwendet werden. Bitte erneut versuchen.'),
      ),
    };
  }
}
