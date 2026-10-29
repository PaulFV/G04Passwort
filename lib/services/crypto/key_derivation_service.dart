import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

/// Supported password hashing algorithms.
enum KdfAlgorithm { argon2id, pbkdf2Sha256 }

/// Parameters of the master-password key derivation. They are stored with
/// the vault header so they can be raised later without breaking old vaults.
@immutable
class KdfParams {
  const KdfParams({
    required this.algorithm,
    required this.salt,
    this.memoryKiB = 19456,
    this.iterations = 2,
    this.parallelism = 1,
  });

  factory KdfParams.fromJson(Map<String, dynamic> j) => KdfParams(
    algorithm: KdfAlgorithm.values.byName(j['alg'] as String),
    salt: base64Decode(j['salt'] as String),
    memoryKiB: j['m'] as int? ?? 19456,
    iterations: j['t'] as int,
    parallelism: j['p'] as int? ?? 1,
  );

  /// Argon2id with OWASP recommended parameters (19 MiB, t=2, p=1).
  ///
  /// On the web, Argon2id would run as single-threaded JavaScript on the UI
  /// thread (10–20 s, frozen UI). There PBKDF2-HMAC-SHA256 with 600 000
  /// iterations is used instead, which runs natively via WebCrypto.
  factory KdfParams.recommended(Uint8List salt) => kIsWeb
      ? KdfParams.pbkdf2(salt)
      : KdfParams(algorithm: KdfAlgorithm.argon2id, salt: salt);

  /// PBKDF2-HMAC-SHA256 fallback (OWASP 2023: 600 000 iterations).
  factory KdfParams.pbkdf2(Uint8List salt) => KdfParams(
    algorithm: KdfAlgorithm.pbkdf2Sha256,
    salt: salt,
    iterations: 600000,
  );

  final KdfAlgorithm algorithm;
  final Uint8List salt;
  final int memoryKiB;
  final int iterations;
  final int parallelism;

  String get description => switch (algorithm) {
    KdfAlgorithm.argon2id =>
      'Argon2id · ${memoryKiB ~/ 1024} MiB · $iterations Iterationen',
    KdfAlgorithm.pbkdf2Sha256 => 'PBKDF2-SHA256 · $iterations Iterationen',
  };

  Map<String, dynamic> toJson() => {
    'alg': algorithm.name,
    'salt': base64Encode(salt),
    'm': memoryKiB,
    't': iterations,
    'p': parallelism,
  };
}

/// Derives the 256-bit key-encryption-key (KEK) from the master password.
///
/// The work runs in a background isolate via [compute] so the UI stays
/// responsive (on the web it runs on the main thread).
class KeyDerivationService {
  const KeyDerivationService();

  static const int saltLength = 16;

  Future<Uint8List> deriveKey(String password, KdfParams params) {
    return compute(_derive, <String, Object>{
      'password': utf8.encode(password),
      'params': params.toJson(),
    });
  }
}

/// Isolate entry point – must be top-level.
Future<Uint8List> _derive(Map<String, Object> message) async {
  final password = message['password']! as List<int>;
  final params = KdfParams.fromJson(message['params']! as Map<String, dynamic>);
  final KdfAlgorithm algorithm = params.algorithm;
  final SecretKey key = switch (algorithm) {
    KdfAlgorithm.argon2id => await Argon2id(
      parallelism: params.parallelism,
      memory: params.memoryKiB,
      iterations: params.iterations,
      hashLength: 32,
    ).deriveKey(secretKey: SecretKeyData(password), nonce: params.salt),
    KdfAlgorithm.pbkdf2Sha256 => await Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: params.iterations,
      bits: 256,
    ).deriveKey(secretKey: SecretKeyData(password), nonce: params.salt),
  };
  return Uint8List.fromList(await key.extractBytes());
}
