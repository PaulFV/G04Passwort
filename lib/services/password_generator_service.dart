import 'dart:math';

import '../models/generator_options.dart';
import 'wordlist.dart';

/// Cryptographically secure password, passphrase and PIN generator.
///
/// Uses [Random.secure] exclusively. For random passwords at least one
/// character of every selected class is guaranteed; the result is then
/// shuffled (Fisher–Yates) so the guaranteed characters are not predictable.
class PasswordGeneratorService {
  PasswordGeneratorService({Random? random})
    : _random = random ?? Random.secure();

  final Random _random;

  static const String upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String lower = 'abcdefghijklmnopqrstuvwxyz';
  static const String digitChars = '0123456789';
  static const String symbolChars = r'!@#$%^&*()-_=+[]{};:,.?/~';
  static const String ambiguous = 'Il1O0o|`\'"';

  String generate(GeneratorOptions o) => switch (o.mode) {
    GeneratorMode.password => _password(o),
    GeneratorMode.passphrase => _passphrase(o),
    GeneratorMode.pin => _pin(o.length.clamp(4, 12)),
  };

  String _password(GeneratorOptions o) {
    String filter(String chars) => o.excludeAmbiguous
        ? chars.split('').where((c) => !ambiguous.contains(c)).join()
        : chars;

    final classes = <String>[
      if (o.uppercase) filter(upper),
      if (o.lowercase) filter(lower),
      if (o.digits) filter(digitChars),
      if (o.symbols) filter(symbolChars),
    ];
    if (classes.isEmpty) classes.add(filter(lower));

    final length = o.length.clamp(
      GeneratorOptions.minLength,
      GeneratorOptions.maxLength,
    );
    final all = classes.join();
    final chars = <String>[
      for (final c in classes) _pick(c),
      for (var i = classes.length; i < length; i++) _pick(all),
    ];
    _shuffle(chars);
    return chars.take(length).join();
  }

  String _passphrase(GeneratorOptions o) {
    final count = o.wordCount.clamp(3, 10);
    final words = List.generate(count, (_) {
      final w = kWordlist[_random.nextInt(kWordlist.length)];
      return o.capitalizeWords ? '${w[0].toUpperCase()}${w.substring(1)}' : w;
    });
    if (o.includeNumber) {
      final i = _random.nextInt(words.length);
      words[i] = '${words[i]}${_random.nextInt(10)}';
    }
    return words.join(o.separator);
  }

  String _pin(int length) =>
      List.generate(length, (_) => _random.nextInt(10)).join();

  String _pick(String chars) => chars[_random.nextInt(chars.length)];

  void _shuffle(List<String> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final t = list[i];
      list[i] = list[j];
      list[j] = t;
    }
  }
}
