/// Domain exceptions of the vault. UI layers map them to user messages.
sealed class VaultException implements Exception {
  const VaultException(this.message);

  /// Human readable (German) message, safe to show in the UI.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The vault is locked; no key material is available in memory.
final class VaultLockedException extends VaultException {
  const VaultLockedException() : super('Der Tresor ist gesperrt.');
}

/// The supplied master password could not decrypt the vault key.
final class InvalidMasterPasswordException extends VaultException {
  const InvalidMasterPasswordException()
    : super('Das Master-Passwort ist falsch.');
}

/// Too many failed attempts – the user has to wait.
final class TooManyAttemptsException extends VaultException {
  const TooManyAttemptsException(this.retryAfter)
    : super('Zu viele Fehlversuche. Bitte warte kurz.');

  final Duration retryAfter;
}

/// Encrypted data was modified or is corrupt (GCM tag mismatch).
final class DataIntegrityException extends VaultException {
  const DataIntegrityException()
    : super('Daten sind beschädigt oder wurden manipuliert.');
}

/// Import / backup file could not be parsed.
final class InvalidBackupException extends VaultException {
  const InvalidBackupException([String? details])
    : super(details ?? 'Die Datei ist kein gültiges Backup.');
}

/// A feature that is architecturally prepared but not yet available.
final class FeatureNotAvailableException extends VaultException {
  const FeatureNotAvailableException(String feature)
    : super('$feature ist in Vorbereitung und bald verfügbar.');
}
