import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/errors/vault_exceptions.dart';
import '../../../services/biometric_service.dart';
import '../../settings/application/settings_controller.dart';

/// High level lifecycle of the vault.
enum AuthStatus {
  /// Splash: loading settings / checking for a vault.
  initializing,

  /// First start: onboarding slides.
  onboarding,

  /// No vault yet: create master password.
  setup,

  /// Vault exists but is locked.
  locked,

  /// Vault is unlocked and decrypted in memory.
  unlocked,
}

@immutable
class AuthState {
  const AuthState({
    this.status = AuthStatus.initializing,
    this.busy = false,
    this.error,
    this.failedAttempts = 0,
    this.lockedUntil,
    this.biometricKind = BiometricKind.none,
    this.passwordHint,
  });

  final AuthStatus status;
  final bool busy;
  final String? error;
  final int failedAttempts;
  final DateTime? lockedUntil;
  final BiometricKind biometricKind;
  final String? passwordHint;

  bool get biometricHardware => biometricKind != BiometricKind.none;

  AuthState copyWith({
    AuthStatus? status,
    bool? busy,
    String? error,
    bool clearError = false,
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearLockout = false,
    BiometricKind? biometricKind,
    String? passwordHint,
  }) => AuthState(
    status: status ?? this.status,
    busy: busy ?? this.busy,
    error: clearError ? null : (error ?? this.error),
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lockedUntil: clearLockout ? null : (lockedUntil ?? this.lockedUntil),
    biometricKind: biometricKind ?? this.biometricKind,
    passwordHint: passwordHint ?? this.passwordHint,
  );
}

/// Orchestrates onboarding, vault creation, unlock (password / biometrics),
/// brute-force throttling and locking.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_init);
    return const AuthState();
  }

  Future<void> _init() async {
    final auth = ref.read(authRepositoryProvider);
    final results = await Future.wait<Object?>([
      auth.isVaultInitialized(),
      ref.read(biometricServiceProvider).kind(),
      Future<void>.delayed(AppConstants.splashMinDuration),
    ]);
    final initialized = results[0]! as bool;
    final settings = ref.read(settingsControllerProvider);
    final header = await auth.readHeader();
    final lockout = await _loadLockout();
    state = state.copyWith(
      failedAttempts: lockout.attempts,
      lockedUntil: lockout.until,
      biometricKind: results[1]! as BiometricKind,
      passwordHint: header?.passwordHint,
      status: !settings.onboardingDone
          ? AuthStatus.onboarding
          : initialized
          ? AuthStatus.locked
          : AuthStatus.setup,
    );
    await ref
        .read(screenProtectionProvider)
        .setEnabled(settings.screenshotProtection);
  }

  // ---------------------------------------------------------------------------
  // Brute-force protection – persisted so an app restart does not reset it.
  // ---------------------------------------------------------------------------

  Future<({int attempts, DateTime? until})> _loadLockout() async {
    final raw = await ref.read(secureStorageProvider).read(StorageKeys.lockout);
    if (raw == null) return (attempts: 0, until: null);
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final until = j['until'] as int?;
      return (
        attempts: j['attempts'] as int? ?? 0,
        until: until == null ? null : DateTime.fromMillisecondsSinceEpoch(until),
      );
    } on Object {
      return (attempts: 0, until: null);
    }
  }

  Future<void> _saveLockout(int attempts, DateTime? until) async {
    final storage = ref.read(secureStorageProvider);
    if (attempts == 0) {
      await storage.delete(StorageKeys.lockout);
    } else {
      await storage.write(
        StorageKeys.lockout,
        jsonEncode({'attempts': attempts, 'until': until?.millisecondsSinceEpoch}),
      );
    }
  }

  Future<void> completeOnboarding() async {
    await ref.read(settingsControllerProvider.notifier).completeOnboarding();
    final initialized = await ref
        .read(authRepositoryProvider)
        .isVaultInitialized();
    state = state.copyWith(
      status: initialized ? AuthStatus.locked : AuthStatus.setup,
    );
  }

  /// Creates a new vault. Returns `true` on success.
  Future<bool> createVault(String password, {String? hint}) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).createVault(password, hint: hint);
      // A new vault never inherits a biometric unlock of an old one.
      await ref.read(settingsControllerProvider.notifier).setBiometricFlag(false);
      await _saveLockout(0, null);
      await ref.read(vaultRepositoryProvider).load();
      state = state.copyWith(
        status: AuthStatus.unlocked,
        busy: false,
        passwordHint: hint,
      );
      return true;
    } on Object catch (e) {
      state = state.copyWith(
        busy: false,
        error: 'Tresor konnte nicht erstellt werden: $e',
      );
      return false;
    }
  }

  /// Remaining lockout or `null`.
  Duration? get remainingLockout {
    final until = state.lockedUntil;
    if (until == null) return null;
    final rest = until.difference(DateTime.now());
    return rest.isNegative ? null : rest;
  }

  /// Unlocks with the master password. Returns `true` on success.
  Future<bool> unlock(String password) async {
    final wait = remainingLockout;
    if (wait != null) {
      state = state.copyWith(
        error: 'Zu viele Fehlversuche. Bitte warte ${wait.inSeconds + 1} s.',
      );
      return false;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).unlock(password);
      await ref.read(vaultRepositoryProvider).load();
      await _saveLockout(0, null);
      state = state.copyWith(
        status: AuthStatus.unlocked,
        busy: false,
        failedAttempts: 0,
        clearLockout: true,
      );
      return true;
    } on InvalidMasterPasswordException catch (e) {
      final attempts = state.failedAttempts + 1;
      DateTime? until;
      if (attempts >= AppConstants.maxFailedAttempts) {
        final factor = pow(
          2,
          attempts - AppConstants.maxFailedAttempts,
        ).toInt();
        until = DateTime.now().add(Duration(seconds: min(30 * factor, 900)));
      }
      await _saveLockout(attempts, until);
      state = state.copyWith(
        busy: false,
        failedAttempts: attempts,
        lockedUntil: until,
        error: until == null
            ? '${e.message} (${AppConstants.maxFailedAttempts - attempts} Versuche bis zur Sperre)'
            : 'Zu viele Fehlversuche – gesperrt für ${until.difference(DateTime.now()).inSeconds} s.',
      );
      return false;
    } on VaultException catch (e) {
      state = state.copyWith(busy: false, error: e.message);
      return false;
    } on Object catch (e) {
      state = state.copyWith(busy: false, error: 'Entsperren fehlgeschlagen: $e');
      return false;
    }
  }

  /// Unlocks with Fingerprint / Face ID if enabled.
  Future<bool> unlockWithBiometrics() async {
    if (!ref.read(settingsControllerProvider).biometricEnabled) return false;
    final ok = await ref.read(biometricServiceProvider).authenticate();
    if (!ok) return false;
    state = state.copyWith(busy: true, clearError: true);
    final unlocked = await ref
        .read(authRepositoryProvider)
        .unlockWithStoredKey();
    if (!unlocked) {
      // The stored key was missing or did not match this vault.
      await ref.read(settingsControllerProvider.notifier).setBiometricFlag(false);
      state = state.copyWith(
        busy: false,
        error:
            'Biometrie-Schlüssel ungültig. Bitte mit dem Master-Passwort entsperren '
            'und Biometrie in den Einstellungen erneut aktivieren.',
      );
      return false;
    }
    await ref.read(vaultRepositoryProvider).load();
    state = state.copyWith(
      status: AuthStatus.unlocked,
      busy: false,
      failedAttempts: 0,
    );
    return true;
  }

  /// Enables / disables biometric unlock. Enabling requires a successful
  /// biometric prompt and an unlocked vault.
  Future<bool> setBiometricEnabled(bool enabled) async {
    final auth = ref.read(authRepositoryProvider);
    final settings = ref.read(settingsControllerProvider.notifier);
    if (!enabled) {
      await auth.removeBiometricKey();
      await settings.setBiometricFlag(false);
      return true;
    }
    final ok = await ref
        .read(biometricServiceProvider)
        .authenticate(
          reason: 'Biometrisches Entsperren für G04Passwort aktivieren',
        );
    if (!ok) return false;
    await auth.storeBiometricKey();
    await settings.setBiometricFlag(true);
    return true;
  }

  /// Changes the master password. Returns an error message or `null`.
  Future<String?> changeMasterPassword(
    String current,
    String next, {
    String? hint,
  }) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .changeMasterPassword(current, next, hint: hint);
      state = state.copyWith(busy: false, passwordHint: hint);
      return null;
    } on VaultException catch (e) {
      state = state.copyWith(busy: false);
      return e.message;
    }
  }

  /// Locks the vault and wipes decrypted data from memory.
  void lock() {
    if (state.status != AuthStatus.unlocked) return;
    ref.read(authRepositoryProvider).lock();
    ref.read(vaultRepositoryProvider).clear();
    unawaited(
      ref.read(clipboardServiceProvider).clearNow().catchError((Object _) {}),
    );
    state = state.copyWith(status: AuthStatus.locked, clearError: true);
  }

  /// Deletes the vault irrevocably.
  Future<void> resetVault() async {
    await ref.read(authRepositoryProvider).resetVault();
    await _saveLockout(0, null);
    ref.read(vaultRepositoryProvider).clear();
    await ref.read(settingsControllerProvider.notifier).setBiometricFlag(false);
    state = const AuthState(status: AuthStatus.setup);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
