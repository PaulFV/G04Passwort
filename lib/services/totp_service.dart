
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

/// Hash algorithm of a TOTP secret.
enum TotpAlgorithm { sha1, sha256, sha512 }

/// Parsed TOTP configuration (RFC 6238).
@immutable
class TotpConfig {
  const TotpConfig({
    required this.secret,
    this.digits = 6,
    this.period = 30,
    this.algorithm = TotpAlgorithm.sha1,
    this.issuer,
    this.account,
  });

  final Uint8List secret;
  final int digits;
  final int period;
  final TotpAlgorithm algorithm;
  final String? issuer;
  final String? account;
}

/// A generated one-time code plus its remaining validity.
@immutable
class TotpCode {
  const TotpCode({required this.code, required this.remaining, required this.period});

  final String code;
  final int remaining;
  final int period;

  /// Code formatted as "482 615".
  String get formatted => code.length == 6
      ? '${code.substring(0, 3)} ${code.substring(3)}'
      : code.length == 8
          ? '${code.substring(0, 4)} ${code.substring(4)}'
          : code;

  double get progress => remaining / period;
}

/// Time-based one-time passwords (2FA) – RFC 6238 / RFC 4226.
class TotpService {
  const TotpService();

  /// Parses either a raw Base32 secret or an `otpauth://totp/...` URI.
  /// Returns `null` if the input is invalid.
  TotpConfig? parse(String input) {
    final value = input.trim();
    if (value.isEmpty) return null;
    if (value.toLowerCase().startsWith('otpauth://')) {
      final uri = Uri.tryParse(value);
      if (uri == null || uri.host.toLowerCase() != 'totp') return null;
      final secret = base32Decode(uri.queryParameters['secret'] ?? '');
      if (secret == null || secret.isEmpty) return null;
      final label = Uri.decodeComponent(uri.path.replaceFirst('/', ''));
      final parts = label.split(':');
      return TotpConfig(
        secret: secret,
        digits: int.tryParse(uri.queryParameters['digits'] ?? '') ?? 6,
        period: int.tryParse(uri.queryParameters['period'] ?? '') ?? 30,
        algorithm: switch ((uri.queryParameters['algorithm'] ?? 'SHA1').toUpperCase()) {
          'SHA256' => TotpAlgorithm.sha256,
          'SHA512' => TotpAlgorithm.sha512,
          _ => TotpAlgorithm.sha1,
        },
        issuer: uri.queryParameters['issuer'] ?? (parts.length > 1 ? parts.first : null),
        account: parts.last,
      );
    }
    final secret = base32Decode(value);
    if (secret == null || secret.isEmpty) return null;
    return TotpConfig(secret: secret);
  }

  /// Generates the code valid at [time] (defaults to now).
  Future<TotpCode> generate(TotpConfig config, {DateTime? time}) async {
    final now = (time ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final counter = now ~/ config.period;
    final code = await hotp(config.secret, counter, digits: config.digits, algorithm: config.algorithm);
    return TotpCode(
      code: code,
      remaining: config.period - (now % config.period),
      period: config.period,
    );
  }

  /// HOTP value for [counter] (RFC 4226 dynamic truncation).
  Future<String> hotp(
    List<int> secret,
    int counter, {
    int digits = 6,
    TotpAlgorithm algorithm = TotpAlgorithm.sha1,
  }) async {
    final msg = ByteData(8)
      ..setUint32(0, (counter >> 32) & 0xFFFFFFFF)
      ..setUint32(4, counter & 0xFFFFFFFF);
    final hmac = switch (algorithm) {
      TotpAlgorithm.sha1 => Hmac.sha1(),
      TotpAlgorithm.sha256 => Hmac.sha256(),
      TotpAlgorithm.sha512 => Hmac.sha512(),
    };
    final mac = await hmac.calculateMac(
      msg.buffer.asUint8List(),
      secretKey: SecretKeyData(secret),
    );
    final h = mac.bytes;
    final offset = h.last & 0x0f;
    final binary = ((h[offset] & 0x7f) << 24) |
        ((h[offset + 1] & 0xff) << 16) |
        ((h[offset + 2] & 0xff) << 8) |
        (h[offset + 3] & 0xff);
    var mod = 1;
    for (var i = 0; i < digits; i++) {
      mod *= 10;
    }
    return (binary % mod).toString().padLeft(digits, '0');
  }

  /// RFC 4648 Base32 decoding (case-insensitive, ignores spaces/padding).
  static Uint8List? base32Decode(String input) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final clean = input.toUpperCase().replaceAll(RegExp(r'[\s=-]'), '');
    final out = <int>[];
    var buffer = 0;
    var bits = 0;
    for (final ch in clean.split('')) {
      final v = alphabet.indexOf(ch);
      if (v < 0) return null;
      buffer = (buffer << 5) | v;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        out.add((buffer >> bits) & 0xff);
        buffer &= (1 << bits) - 1; // keep only unread bits (web-safe)
      }
    }
    return Uint8List.fromList(out);
  }
}
