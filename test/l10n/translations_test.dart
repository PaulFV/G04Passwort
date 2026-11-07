import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:g04passwort/core/errors/vault_exceptions.dart';
import 'package:g04passwort/core/l10n/l10n.dart';
import 'package:g04passwort/core/l10n/strings_en.dart';
import 'package:g04passwort/models/app_settings.dart';
import 'package:g04passwort/models/generator_options.dart';
import 'package:g04passwort/models/item_category.dart';
import 'package:g04passwort/models/password_strength.dart';
import 'package:g04passwort/models/vault_item.dart';
import 'package:g04passwort/models/vault_item_type.dart';
import 'package:g04passwort/widgets/feature_icon.dart';

/// `tr('…' '…')` with one or more adjacent string literals.
final _trCall = RegExp(
  r'''\btr\(\s*((?:(?:'(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*")\s*)+)''',
);
final _literal = RegExp(r'''(?:'((?:[^'\\\n]|\\.)*)'|"((?:[^"\\\n]|\\.)*)")''');

String _unescape(String s) => s.replaceAllMapped(
  RegExp(r'\\(.)'),
  (m) => switch (m[1]) {
    'n' => '\n',
    't' => '\t',
    _ => m[1]!,
  },
);

Set<String> _placeholders(String s) =>
    RegExp(r'\{(\w+)\}').allMatches(s).map((m) => m[1]!).toSet();

void main() {
  setUp(() => L10n.use('de'));
  tearDown(() => L10n.use('de'));

  test('every tr() text in lib/ has an English translation', () {
    final missing = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final src = file.readAsStringSync();
      for (final call in _trCall.allMatches(src)) {
        final key = _literal
            .allMatches(call[1]!)
            .map((l) => _unescape(l[1] ?? l[2] ?? ''))
            .join();
        if (!kEn.containsKey(key)) missing.add('${file.path}: $key');
      }
    }
    expect(missing, isEmpty, reason: 'Fehlende Übersetzungen');
  });

  test('labels of enums, document types and errors are translated', () {
    final keys = <String>[
      for (final v in FeatureIcon.values) v.label,
      for (final v in AppBackgroundStyle.values) v.label,
      for (final v in ItemCategory.values) v.label,
      for (final v in VaultItemType.values) v.label,
      for (final v in PasswordStrengthLevel.values) v.label,
      for (final v in GeneratorMode.values) v.label,
      ...DocumentData.types,
      const VaultLockedException().messageDe,
      const InvalidMasterPasswordException().messageDe,
      const TooManyAttemptsException(Duration.zero).messageDe,
      const DataIntegrityException().messageDe,
      const InvalidBackupException().messageDe,
      const FeatureNotAvailableException('x').messageDe,
    ];
    expect(keys.where((k) => !kEn.containsKey(k)), isEmpty);
  });

  test('translations keep all placeholders', () {
    kEn.forEach((de, en) {
      expect(_placeholders(en), _placeholders(de), reason: de);
    });
  });

  test('tr switches language and fills placeholders', () {
    expect(tr('Entsperren'), 'Entsperren');
    expect(tr('Mit {bioName} entsperren', {'bioName': 'Face ID'}),
        'Mit Face ID entsperren');
    L10n.use('en');
    expect(tr('Entsperren'), 'Unlock');
    expect(tr('Mit {bioName} entsperren', {'bioName': 'Face ID'}),
        'Unlock with Face ID');
    expect(const VaultLockedException().message, 'The vault is locked.');
    expect(FeatureIcon.favorites.label, 'Favorites');
  });

  test('language setting resolves system language', () {
    expect(L10n.resolve('de'), 'de');
    expect(L10n.resolve('en'), 'en');
    expect(L10n.resolve('system', const Locale('de', 'AT')), 'de');
    expect(L10n.resolve('system', const Locale('fr')), 'en');
  });
}
