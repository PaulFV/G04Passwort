import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:g04passwort/core/errors/vault_exceptions.dart';
import 'package:g04passwort/services/crypto/crypto_service.dart';
import 'package:g04passwort/services/crypto/key_derivation_service.dart';

void main() {
  final crypto = CryptoService();

  group('CryptoService (AES-256-GCM)', () {
    test('encrypt/decrypt round trip', () async {
      final key = crypto.generateKey();
      final cipher = await crypto.encryptString(
        'geheim 🔐',
        key,
        aad: 'item:1',
      );
      expect(cipher, isNot(contains('geheim')));
      expect(
        await crypto.decryptString(cipher, key, aad: 'item:1'),
        'geheim 🔐',
      );
    });

    test('uses a fresh nonce for every encryption', () async {
      final key = crypto.generateKey();
      final a = await crypto.encryptString('x', key);
      final b = await crypto.encryptString('x', key);
      expect(a, isNot(b));
    });

    test('wrong key fails authentication', () async {
      final cipher = await crypto.encryptString('data', crypto.generateKey());
      expect(
        () => crypto.decryptString(cipher, crypto.generateKey()),
        throwsA(isA<DataIntegrityException>()),
      );
    });

    test('wrong associated data fails authentication', () async {
      final key = crypto.generateKey();
      final cipher = await crypto.encryptString('data', key, aad: 'item:1');
      expect(
        () => crypto.decryptString(cipher, key, aad: 'item:2'),
        throwsA(isA<DataIntegrityException>()),
      );
    });

    test('tampered ciphertext is rejected', () async {
      final key = crypto.generateKey();
      final bytes = base64Decode(await crypto.encryptString('data', key));
      bytes[bytes.length - 20] ^= 0x01;
      expect(
        () => crypto.decrypt(bytes, key),
        throwsA(isA<DataIntegrityException>()),
      );
    });

    test('constantTimeEquals', () {
      expect(CryptoService.constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
      expect(CryptoService.constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
      expect(CryptoService.constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
    });
  });

  group('KeyDerivationService', () {
    const kdf = KeyDerivationService();
    final salt = crypto.randomBytes(16);
    // Small parameters keep the unit test fast.
    final params = KdfParams(
      algorithm: KdfAlgorithm.argon2id,
      salt: salt,
      memoryKiB: 256,
      iterations: 1,
    );

    test('Argon2id is deterministic for the same salt', () async {
      final a = await kdf.deriveKey('master', params);
      final b = await kdf.deriveKey('master', params);
      expect(a, hasLength(32));
      expect(a, b);
    });

    test('different passwords give different keys', () async {
      final a = await kdf.deriveKey('master', params);
      final b = await kdf.deriveKey('Master', params);
      expect(a, isNot(b));
    });

    test('PBKDF2 fallback derives 256-bit keys', () async {
      final p = KdfParams(
        algorithm: KdfAlgorithm.pbkdf2Sha256,
        salt: salt,
        iterations: 1000,
      );
      expect(await kdf.deriveKey('master', p), hasLength(32));
    });

    test('params survive JSON round trip', () {
      final copy = KdfParams.fromJson(params.toJson());
      expect(copy.salt, params.salt);
      expect(copy.memoryKiB, params.memoryKiB);
      expect(copy.algorithm, params.algorithm);
    });
  });
}
