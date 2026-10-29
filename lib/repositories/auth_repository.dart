import 'dart:convert';
import 'dart:typed_data';

import '../core/constants/app_constants.dart';
import '../core/errors/vault_exceptions.dart';
import '../database/app_database.dart';
import '../services/crypto/crypto_service.dart';
import '../services/crypto/key_derivation_service.dart';
import '../services/crypto/vault_header.dart';
import '../services/secure_storage_service.dart';

/// Master-password based authentication and key management.
abstract interface class AuthRepository {
  /// Whether a vault (header) exists on this device.
  Future<bool> isVaultInitialized();

  Future<VaultHeader?> readHeader();

  /// Creates a new vault protected by [masterPassword] and unlocks it.
  Future<void> createVault(String masterPassword, {String? hint});

  /// Unlocks the vault. Throws [InvalidMasterPasswordException].
  Future<void> unlock(String masterPassword);

  /// Returns `true` if [masterPassword] is correct (does not change state).
  Future<bool> verifyMasterPassword(String masterPassword);

  /// Unlocks with the biometric-protected key copy. Call only after the
  /// biometric prompt succeeded.
  Future<bool> unlockWithStoredKey();

  Future<bool> hasBiometricKey();
  Future<void> storeBiometricKey();
  Future<void> removeBiometricKey();

  Future<void> changeMasterPassword(
    String current,
    String next, {
    String? hint,
  });

  /// Unwraps a vault key of a foreign header (used for backup import).
  Future<Uint8List> unwrapKey(VaultHeader header, String password);

  bool get isUnlocked;

  /// The in-memory vault key. Throws [VaultLockedException] when locked.
  Uint8List requireKey();

  /// Wipes the key from memory.
  void lock();

  /// Deletes the vault and all keys irrevocably.
  Future<void> resetVault();
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AppDatabase database,
    required CryptoService crypto,
    required KeyDerivationService kdf,
    required SecureStorageService storage,
    KdfParams Function(Uint8List salt) kdfParams = KdfParams.recommended,
  }) : _db = database,
       _crypto = crypto,
       _kdf = kdf,
       _storage = storage,
       _kdfParams = kdfParams;

  static const _headerKey = 'vault_header';

  /// Encrypted known value used to verify a vault key without the master
  /// password (biometric unlock, stale keychain entries after reinstall).
  static const _keyCheckKey = 'key_check';
  static const _keyCheckPlain = 'g04passwort:key-check:v1';

  final KdfParams Function(Uint8List salt) _kdfParams;

  final AppDatabase _db;
  final CryptoService _crypto;
  final KeyDerivationService _kdf;
  final SecureStorageService _storage;

  Uint8List? _vaultKey;

  @override
  bool get isUnlocked => _vaultKey != null;

  @override
  Uint8List requireKey() => _vaultKey ?? (throw const VaultLockedException());

  @override
  Future<bool> isVaultInitialized() async =>
      (await _db.readMeta(_headerKey)) != null;

  @override
  Future<VaultHeader?> readHeader() async {
    final raw = await _db.readMeta(_headerKey);
    return raw == null ? null : VaultHeader.decode(raw);
  }

  @override
  Future<void> createVault(String masterPassword, {String? hint}) async {
    final params = _kdfParams(
      _crypto.randomBytes(KeyDerivationService.saltLength),
    );
    final kek = await _kdf.deriveKey(masterPassword, params);
    final vaultKey = _crypto.generateKey();
    final wrapped = await _crypto.encrypt(
      vaultKey,
      kek,
      aad: utf8.encode(VaultHeader.wrapAad),
    );
    CryptoService.wipe(kek);
    final header = VaultHeader(
      version: VaultHeader.currentVersion,
      kdf: params,
      wrappedVaultKey: base64Encode(wrapped),
      createdAt: DateTime.now(),
      passwordHint: hint,
    );
    await _db.writeMeta(_headerKey, header.encode());
    await _writeKeyCheck(vaultKey);
    // A biometric key of a previous (deleted) vault may survive in the
    // keychain after a reinstall – it must never unlock the new vault.
    await removeBiometricKey();
    _vaultKey = vaultKey;
  }

  Future<void> _writeKeyCheck(List<int> key) async => _db.writeMeta(
    _keyCheckKey,
    await _crypto.encryptString(_keyCheckPlain, key, aad: _keyCheckKey),
  );

  /// `true` if [key] belongs to this vault. Vaults created before the key
  /// check existed return `null` (unknown).
  Future<bool?> _matchesVault(List<int> key) async {
    final check = await _db.readMeta(_keyCheckKey);
    if (check == null) return null;
    try {
      return await _crypto.decryptString(check, key, aad: _keyCheckKey) ==
          _keyCheckPlain;
    } on DataIntegrityException {
      return false;
    }
  }

  @override
  Future<Uint8List> unwrapKey(VaultHeader header, String password) async {
    final kek = await _kdf.deriveKey(password, header.kdf);
    try {
      return await _crypto.decrypt(
        base64Decode(header.wrappedVaultKey),
        kek,
        aad: utf8.encode(VaultHeader.wrapAad),
      );
    } on DataIntegrityException {
      throw const InvalidMasterPasswordException();
    } finally {
      CryptoService.wipe(kek);
    }
  }

  @override
  Future<void> unlock(String masterPassword) async {
    final header = await readHeader();
    if (header == null) {
      throw const InvalidBackupException('Kein Tresor vorhanden.');
    }
    final key = await unwrapKey(header, masterPassword);
    if (await _matchesVault(key) == null) await _writeKeyCheck(key);
    _vaultKey = key;
  }

  @override
  Future<bool> verifyMasterPassword(String masterPassword) async {
    final header = await readHeader();
    if (header == null) return false;
    try {
      final key = await unwrapKey(header, masterPassword);
      CryptoService.wipe(key);
      return true;
    } on InvalidMasterPasswordException {
      return false;
    }
  }

  @override
  Future<bool> hasBiometricKey() async =>
      (await _storage.read(StorageKeys.biometricVaultKey)) != null;

  @override
  Future<void> storeBiometricKey() async =>
      _storage.write(StorageKeys.biometricVaultKey, base64Encode(requireKey()));

  @override
  Future<void> removeBiometricKey() =>
      _storage.delete(StorageKeys.biometricVaultKey);

  @override
  Future<bool> unlockWithStoredKey() async {
    final raw = await _storage.read(StorageKeys.biometricVaultKey);
    if (raw == null) return false;
    final key = base64Decode(raw);
    final header = await readHeader();
    if (header == null || key.length != CryptoService.keyLength) return false;
    if (await _matchesVault(key) != true) {
      // Stale or foreign key – discard it, the user must use the password.
      await removeBiometricKey();
      return false;
    }
    _vaultKey = key;
    return true;
  }

  @override
  Future<void> changeMasterPassword(
    String current,
    String next, {
    String? hint,
  }) async {
    final header = await readHeader();
    if (header == null) throw const VaultLockedException();
    final vaultKey = await unwrapKey(header, current);
    final params = _kdfParams(
      _crypto.randomBytes(KeyDerivationService.saltLength),
    );
    final kek = await _kdf.deriveKey(next, params);
    final wrapped = await _crypto.encrypt(
      vaultKey,
      kek,
      aad: utf8.encode(VaultHeader.wrapAad),
    );
    CryptoService.wipe(kek);
    await _db.writeMeta(
      _headerKey,
      header
          .copyWith(
            kdf: params,
            wrappedVaultKey: base64Encode(wrapped),
            passwordHint: hint,
          )
          .encode(),
    );
    _vaultKey = vaultKey;
  }

  @override
  void lock() {
    CryptoService.wipe(_vaultKey);
    _vaultKey = null;
  }

  @override
  Future<void> resetVault() async {
    lock();
    await _db.wipe();
    await _storage.delete(StorageKeys.biometricVaultKey);
  }
}
