import 'package:flutter/foundation.dart';

/// Mode of the password generator.
enum GeneratorMode {
  password('Passwort'),
  passphrase('Passphrase'),
  pin('PIN');

  const GeneratorMode(this.label);

  final String label;
}

/// Options for [PasswordGeneratorService].
@immutable
class GeneratorOptions {
  const GeneratorOptions({
    this.mode = GeneratorMode.password,
    this.length = 16,
    this.uppercase = true,
    this.lowercase = true,
    this.digits = true,
    this.symbols = true,
    this.excludeAmbiguous = false,
    this.wordCount = 5,
    this.separator = '-',
    this.capitalizeWords = true,
    this.includeNumber = true,
  });

  static const int minLength = 4;
  static const int maxLength = 64;

  final GeneratorMode mode;
  final int length;
  final bool uppercase;
  final bool lowercase;
  final bool digits;
  final bool symbols;

  /// Removes look-alike characters such as l, 1, I, O, 0.
  final bool excludeAmbiguous;
  final int wordCount;
  final String separator;
  final bool capitalizeWords;
  final bool includeNumber;

  GeneratorOptions copyWith({
    GeneratorMode? mode,
    int? length,
    bool? uppercase,
    bool? lowercase,
    bool? digits,
    bool? symbols,
    bool? excludeAmbiguous,
    int? wordCount,
    String? separator,
    bool? capitalizeWords,
    bool? includeNumber,
  }) => GeneratorOptions(
    mode: mode ?? this.mode,
    length: length ?? this.length,
    uppercase: uppercase ?? this.uppercase,
    lowercase: lowercase ?? this.lowercase,
    digits: digits ?? this.digits,
    symbols: symbols ?? this.symbols,
    excludeAmbiguous: excludeAmbiguous ?? this.excludeAmbiguous,
    wordCount: wordCount ?? this.wordCount,
    separator: separator ?? this.separator,
    capitalizeWords: capitalizeWords ?? this.capitalizeWords,
    includeNumber: includeNumber ?? this.includeNumber,
  );
}
