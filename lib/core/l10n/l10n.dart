import 'dart:ui';

import 'strings_en.dart';

/// Lightweight localisation of G04Passwort (German / English).
///
/// German is the source language: every UI text is written in German and
/// wrapped in [tr]. In English mode [tr] looks the text up in [kEn].
/// Placeholders use `{name}` and are filled from [args]:
///
/// ```dart
/// tr('Entsperren mit {bio} …', {'bio': bioName})
/// ```
///
/// `test/l10n/translations_test.dart` makes sure every text passed to [tr]
/// has an English translation.
abstract final class L10n {
  /// Supported language codes.
  static const supported = ['de', 'en'];

  /// Value of the language setting that follows the device language.
  static const system = 'system';

  static String _code = 'de';

  /// Active language code ('de' or 'en').
  static String get code => _code;

  static bool get isEnglish => _code == 'en';

  /// Intl locale for date and number formatting.
  static String get intlLocale => isEnglish ? 'en_US' : 'de_DE';

  /// Resolves the setting ('system', 'de', 'en') to a supported language.
  static String resolve(String setting, [Locale? device]) {
    if (supported.contains(setting)) return setting;
    final lang = (device ?? PlatformDispatcher.instance.locale).languageCode;
    return lang == 'de' ? 'de' : 'en';
  }

  /// Activates [code]. Called by the app whenever the setting changes.
  static void use(String code) => _code = supported.contains(code) ? code : 'de';
}

/// Translates the German [de] text into the active language and fills the
/// `{placeholders}` from [args].
String tr(String de, [Map<String, Object?>? args]) {
  var text = L10n.isEnglish ? (kEn[de] ?? de) : de;
  if (args != null) {
    args.forEach((key, value) => text = text.replaceAll('{$key}', '$value'));
  }
  return text;
}
