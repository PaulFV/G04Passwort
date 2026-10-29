import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'key_derivation_service.dart';

/// Public, non-secret metadata of a vault.
///
/// Key hierarchy (zero-knowledge, like Bitwarden / 1Password):
/// ```
/// master password ──Argon2id(salt)──► KEK (never stored)
/// KEK ──AES-256-GCM──► wrappedVaultKey   (stored here)
/// vault key (random 256 bit) ──AES-256-GCM──► every item / folder / file
/// ```
/// Changing the master password only re-wraps the vault key; items stay
/// untouched. A wrong password fails the GCM tag check of the wrapped key.
@immutable
class VaultHeader {
  const VaultHeader({
    required this.version,
    required this.kdf,
    required this.wrappedVaultKey,
    required this.createdAt,
    this.passwordHint,
  });

  factory VaultHeader.fromJson(Map<String, dynamic> j) => VaultHeader(
    version: j['v'] as int,
    kdf: KdfParams.fromJson(j['kdf'] as Map<String, dynamic>),
    wrappedVaultKey: j['wrapped'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(j['created'] as int),
    passwordHint: j['hint'] as String?,
  );

  factory VaultHeader.decode(String raw) =>
      VaultHeader.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  static const int currentVersion = 1;

  /// Associated data binding the wrapped key to its purpose.
  static const String wrapAad = 'g04passwort:vault-key:v1';

  final int version;
  final KdfParams kdf;

  /// Base64 AES-GCM envelope of the vault key, encrypted with the KEK.
  final String wrappedVaultKey;
  final DateTime createdAt;
  final String? passwordHint;

  VaultHeader copyWith({
    KdfParams? kdf,
    String? wrappedVaultKey,
    String? passwordHint,
  }) => VaultHeader(
    version: version,
    kdf: kdf ?? this.kdf,
    wrappedVaultKey: wrappedVaultKey ?? this.wrappedVaultKey,
    createdAt: createdAt,
    passwordHint: passwordHint ?? this.passwordHint,
  );

  Map<String, dynamic> toJson() => {
    'v': version,
    'kdf': kdf.toJson(),
    'wrapped': wrappedVaultKey,
    'created': createdAt.millisecondsSinceEpoch,
    if (passwordHint != null && passwordHint!.isNotEmpty) 'hint': passwordHint,
  };

  String encode() => jsonEncode(toJson());
}
