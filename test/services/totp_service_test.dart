import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:g04passwort/services/totp_service.dart';

void main() {
  const totp = TotpService();
  // RFC 6238 test secret "12345678901234567890" (SHA-1).
  final rfcSecret = utf8.encode('12345678901234567890');

  group('TOTP / HOTP', () {
    test('RFC 4226 HOTP test vectors', () async {
      const expected = ['755224', '287082', '359152', '969429', '338314'];
      for (var i = 0; i < expected.length; i++) {
        expect(await totp.hotp(rfcSecret, i), expected[i]);
      }
    });

    test('RFC 6238 TOTP test vectors (8 digits)', () async {
      final config = TotpConfig(
        secret: utf8.encode('12345678901234567890'),
        digits: 8,
      );
      final vectors = {
        59: '94287082',
        1111111109: '07081804',
        1234567890: '89005924',
      };
      for (final e in vectors.entries) {
        final code = await totp.generate(
          config,
          time: DateTime.fromMillisecondsSinceEpoch(e.key * 1000, isUtc: true),
        );
        expect(code.code, e.value);
      }
    });

    test('remaining seconds are within the period', () async {
      final code = await totp.generate(TotpConfig(secret: rfcSecret));
      expect(code.remaining, inInclusiveRange(1, 30));
      expect(code.formatted, matches(RegExp(r'^\d{3} \d{3}$')));
    });
  });

  group('parsing', () {
    test('base32 decoding', () {
      expect(TotpService.base32Decode('JBSWY3DPEHPK3PXP'), [
        72,
        101,
        108,
        108,
        111,
        33,
        0xDE,
        0xAD,
        0xBE,
        0xEF,
      ]);
      expect(TotpService.base32Decode('not valid!'), isNull);
    });

    test('raw secret', () {
      expect(totp.parse('JBSW Y3DP EHPK 3PXP'), isNotNull);
      expect(totp.parse(''), isNull);
    });

    test('otpauth URI', () {
      final c = totp.parse(
        'otpauth://totp/ACME%20Co:paul@example.com?secret=JBSWY3DPEHPK3PXP&issuer=ACME%20Co&digits=8&period=60&algorithm=SHA256',
      )!;
      expect(c.issuer, 'ACME Co');
      expect(c.account, 'paul@example.com');
      expect(c.digits, 8);
      expect(c.period, 60);
      expect(c.algorithm, TotpAlgorithm.sha256);
    });
  });
}
