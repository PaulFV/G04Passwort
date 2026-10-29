import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:g04passwort/core/errors/vault_exceptions.dart';
import 'package:g04passwort/database/app_database.dart';
import 'package:g04passwort/models/vault_item_type.dart';
import 'package:g04passwort/repositories/auth_repository.dart';
import 'package:g04passwort/repositories/vault_repository.dart';
import 'package:g04passwort/services/crypto/crypto_service.dart';
import 'package:g04passwort/services/crypto/key_derivation_service.dart';
import 'package:g04passwort/services/import_export_service.dart';
import 'package:g04passwort/services/secure_storage_service.dart';

/// End-to-end flow of the persistence layer with an in-memory database:
/// create vault → save → lock → wrong / right password → backup → import.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AuthRepositoryImpl auth;
  late VaultRepositoryImpl vault;
  late ImportExportService io;
  final crypto = CryptoService();

  // Fast KDF parameters keep the test quick; production uses Argon2id.
  KdfParams fastParams(Uint8List salt) =>
      KdfParams(algorithm: KdfAlgorithm.pbkdf2Sha256, salt: salt, iterations: 1000);

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    auth = AuthRepositoryImpl(
      database: db,
      crypto: crypto,
      kdf: const KeyDerivationService(),
      storage: SecureStorageService(),
      kdfParams: fastParams,
    );
    vault = VaultRepositoryImpl(database: db, crypto: crypto, auth: auth);
    io = ImportExportService(database: db, crypto: crypto, auth: auth, vault: vault);
  });

  tearDown(() => db.close());

  test('create, save, lock and unlock', () async {
    expect(await auth.isVaultInitialized(), isFalse);
    await auth.createVault('Master-Passwort-1!');
    await vault.load();

    final item = vault.newItem(VaultItemType.login);
    await vault.save(
      item.copyWith(
        title: 'Router',
        login: item.login!.copyWith(username: 'admin', password: 'alt'),
      ),
    );
    // Changing the password records the old one in the history.
    final saved = vault.byId(item.id)!;
    await vault.save(saved.copyWith(login: saved.login!.copyWith(password: 'neu')));
    expect(vault.byId(item.id)!.login!.passwordHistory.single.password, 'alt');

    auth.lock();
    vault.clear();
    expect(auth.isUnlocked, isFalse);
    expect(() => auth.requireKey(), throwsA(isA<VaultLockedException>()));

    await expectLater(auth.unlock('falsch'), throwsA(isA<InvalidMasterPasswordException>()));

    await auth.unlock('Master-Passwort-1!');
    await vault.load();
    expect(vault.items.single.title, 'Router');
    expect(vault.items.single.login!.password, 'neu');
  });

  test('database contains no plaintext', () async {
    await auth.createVault('Master-Passwort-1!');
    await vault.load();
    final item = vault.newItem(VaultItemType.note);
    await vault.save(item.copyWith(title: 'Geheimnis', notes: 'PIN 4711'));
    final rows = await db.readAll(AppDatabase.tableItems);
    expect(rows.single.payload, isNot(contains('Geheimnis')));
    expect(rows.single.payload, isNot(contains('4711')));
  });

  test('change master password keeps data', () async {
    await auth.createVault('Alt-Passwort-123');
    await vault.load();
    await vault.save(vault.newItem(VaultItemType.note).copyWith(title: 'Notiz'));
    await auth.changeMasterPassword('Alt-Passwort-123', 'Neu-Passwort-456');
    auth.lock();
    await expectLater(auth.unlock('Alt-Passwort-123'), throwsA(isA<InvalidMasterPasswordException>()));
    await auth.unlock('Neu-Passwort-456');
    await vault.load();
    expect(vault.items.single.title, 'Notiz');
  });

  test('stale biometric key from another vault is rejected', () async {
    await auth.createVault('Erster-Tresor-1');
    await auth.storeBiometricKey();
    expect(await auth.hasBiometricKey(), isTrue);
    // Simulate a reinstall: DB wiped, keychain entry survives.
    await db.wipe();
    final storage = SecureStorageService();
    final staleKey = await storage.read('g04.bio.vault_key.v1');
    await auth.createVault('Zweiter-Tresor-2');
    expect(await auth.hasBiometricKey(), isFalse);
    await storage.write('g04.bio.vault_key.v1', staleKey!);
    auth.lock();
    expect(await auth.unlockWithStoredKey(), isFalse);
    expect(await auth.hasBiometricKey(), isFalse);
  });

  test('encrypted backup round trip and CSV import without duplicates', () async {
    await auth.createVault('Backup-Passwort-1');
    await vault.load();
    final csv = 'name,url,username,password\nGitHub,https://github.com,paul,pw1\nRouter,,admin,pw2\n';
    final first = await io.importCsv(csv);
    expect(first.imported, 2);
    final again = await io.importCsv(csv);
    expect(again.imported, 0);
    expect(again.skipped, 2);

    final backup = await io.createEncryptedBackup();
    for (final i in vault.items) {
      await vault.delete(i.id);
    }
    expect(vault.items, isEmpty);
    await expectLater(io.restoreEncryptedBackup(backup, 'falsch'), throwsA(isA<InvalidMasterPasswordException>()));
    final restored = await io.restoreEncryptedBackup(backup, 'Backup-Passwort-1');
    expect(restored.imported, 2);
    expect(vault.items.map((i) => i.title), containsAll(['GitHub', 'Router']));
  });
}
