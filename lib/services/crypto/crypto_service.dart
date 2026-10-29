import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../core/errors/vault_exceptions.dart';

/// Authenticated encryption for all vault data: **AES-256-GCM**.
///
/// Envelope layout (base64 encoded for storage):
/// ```
/// [1 byte version][12 byte nonce][N byte ciphertext][16 byte GCM tag]
/// ```
/// A fresh random 96-bit nonce is generated for every encryption. Optional
/// associated data (AAD) binds a ciphertext to its context (e.g. the item
/// id), so encrypted blobs cannot be swapped between records.
class CryptoService {
  CryptoService({Random? random}) : _random = random ?? Random.secure();

  static const int envelopeVersion = 1;
  static const int keyLength = 32;
  static const int nonceLength = 12;
  static const int macLength = 16;

  final Random _random;
  final AesGcm _aes = AesGcm.with256bits();

  /// Cryptographically secure random bytes.
  Uint8List randomBytes(int length) {
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = _random.nextInt(256);
    }
    return out;
  }

  /// Generates a new random 256-bit key (the vault key).
  Uint8List generateKey() => randomBytes(keyLength);

  /// Encrypts [plain] with [key] and returns the binary envelope.
  Future<Uint8List> encrypt(
    List<int> plain,
    List<int> key, {
    List<int> aad = const [],
  }) async {
    _checkKey(key);
    final nonce = randomBytes(nonceLength);
    final box = await _aes.encrypt(
      plain,
      secretKey: SecretKeyData(key),
      nonce: nonce,
      aad: aad,
    );
    final out = BytesBuilder(copy: false)
      ..addByte(envelopeVersion)
      ..add(nonce)
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    return out.toBytes();
  }

  /// Decrypts an envelope produced by [encrypt].
  ///
  /// Throws [DataIntegrityException] if the key is wrong or the data was
  /// tampered with (GCM authentication failure).
  Future<Uint8List> decrypt(
    List<int> envelope,
    List<int> key, {
    List<int> aad = const [],
  }) async {
    _checkKey(key);
    if (envelope.length < 1 + nonceLength + macLength ||
        envelope[0] != envelopeVersion) {
      throw const DataIntegrityException();
    }
    final nonce = envelope.sublist(1, 1 + nonceLength);
    final cipher = envelope.sublist(1 + nonceLength, envelope.length - macLength);
    final mac = envelope.sublist(envelope.length - macLength);
    try {
      final plain = await _aes.decrypt(
        SecretBox(cipher, nonce: nonce, mac: Mac(mac)),
        secretKey: SecretKeyData(key),
        aad: aad,
      );
      return Uint8List.fromList(plain);
    } on SecretBoxAuthenticationError {
      throw const DataIntegrityException();
    }
  }

  /// Encrypts a UTF-8 string and returns base64 text.
  Future<String> encryptString(String plain, List<int> key, {String? aad}) async =>
      base64Encode(
        await encrypt(utf8.encode(plain), key, aad: aad == null ? const [] : utf8.encode(aad)),
      );

  /// Decrypts base64 text produced by [encryptString].
  Future<String> decryptString(String cipher, List<int> key, {String? aad}) async =>
      utf8.decode(
        await decrypt(
          base64Decode(cipher),
          key,
          aad: aad == null ? const [] : utf8.encode(aad),
        ),
      );

  /// Encrypts a JSON-serialisable map.
  Future<String> encryptJson(Map<String, dynamic> json, List<int> key, {String? aad}) =>
      encryptString(jsonEncode(json), key, aad: aad);

  /// Decrypts a JSON map produced by [encryptJson].
  Future<Map<String, dynamic>> decryptJson(String cipher, List<int> key, {String? aad}) async =>
      jsonDecode(await decryptString(cipher, key, aad: aad)) as Map<String, dynamic>;

  /// Constant-time comparison to avoid timing side channels.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Best-effort wipe of sensitive bytes held in memory.
  static void wipe(List<int>? bytes) {
    if (bytes == null) return;
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }

  void _checkKey(List<int> key) {
    if (key.length != keyLength) {
      throw ArgumentError('AES-256 requires a $keyLength byte key');
    }
  }
}
