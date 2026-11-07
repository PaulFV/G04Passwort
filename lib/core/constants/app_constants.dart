import '../l10n/l10n.dart';

/// App-wide constants for G04Passwort.
abstract final class AppConstants {
  static const String appName = 'G04Passwort';
  static const String version = '1.0.0';
  static const String buildNumber = '1';
  static const String copyright = '© 2026 PaulFV';
  static String get rightsReserved =>
      tr('© 2026 PaulFV · Alle Rechte vorbehalten');
  static const String owner = 'PaulFV';
  static const String ownerUrl = 'https://github.com/PaulFV';
  static const String privacyUrl =
      'https://github.com/PaulFV/G04Passwort/blob/main/PRIVACY.md';
  static const String legalDate = '4. November 2026';
  static const String repositoryUrl = 'https://github.com/PaulFV/G04Passwort';

  /// Name of the local SQLite database (".sqlite" is appended on native).
  static const String databaseName = 'g04passwort_vault';

  /// Minimum length of the master password.
  static const int minMasterPasswordLength = 10;

  /// Failed unlock attempts before a temporary lockout starts.
  static const int maxFailedAttempts = 5;

  /// Maximum size of an encrypted document attachment.
  static const int maxAttachmentBytes = 10 * 1024 * 1024;

  /// Number of previous passwords kept per login item.
  static const int passwordHistoryLength = 10;

  /// Minimum time the splash screen is shown.
  static const Duration splashMinDuration = Duration(milliseconds: 1800);
}

/// Keys used in flutter_secure_storage.
abstract final class StorageKeys {
  static const String settings = 'g04.settings.v1';
  static const String biometricVaultKey = 'g04.bio.vault_key.v1';
  static const String lockout = 'g04.lockout.v1';
}
