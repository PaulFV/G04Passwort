import 'package:flutter_test/flutter_test.dart';
import 'package:g04passwort/models/generator_options.dart';
import 'package:g04passwort/services/password_generator_service.dart';
import 'package:g04passwort/services/wordlist.dart';

void main() {
  final generator = PasswordGeneratorService();

  test('respects length and contains every selected class', () {
    for (var i = 0; i < 200; i++) {
      final p = generator.generate(const GeneratorOptions(length: 12));
      expect(p, hasLength(12));
      expect(p, matches(RegExp('[A-Z]')));
      expect(p, matches(RegExp('[a-z]')));
      expect(p, matches(RegExp('[0-9]')));
      expect(p, matches(RegExp(r'[^A-Za-z0-9]')));
    }
  });

  test('only digits when only digits are selected', () {
    final p = generator.generate(
      const GeneratorOptions(
        length: 20,
        uppercase: false,
        lowercase: false,
        symbols: false,
      ),
    );
    expect(p, matches(RegExp(r'^\d{20}$')));
  });

  test('excludes ambiguous characters', () {
    for (var i = 0; i < 100; i++) {
      final p = generator.generate(
        const GeneratorOptions(length: 64, excludeAmbiguous: true),
      );
      expect(p, isNot(matches(RegExp(r'[Il1O0o|]'))));
    }
  });

  test('passphrase uses words from the list', () {
    final p = generator.generate(
      const GeneratorOptions(
        mode: GeneratorMode.passphrase,
        wordCount: 4,
        capitalizeWords: false,
        includeNumber: false,
      ),
    );
    final words = p.split('-');
    expect(words, hasLength(4));
    for (final w in words) {
      expect(kWordlist, contains(w));
    }
  });

  test('PIN mode', () {
    expect(
      generator.generate(
        const GeneratorOptions(mode: GeneratorMode.pin, length: 6),
      ),
      matches(RegExp(r'^\d{6}$')),
    );
  });

  test('passwords are not repeated', () {
    final set = {
      for (var i = 0; i < 500; i++)
        generator.generate(const GeneratorOptions()),
    };
    expect(set, hasLength(500));
  });
}
