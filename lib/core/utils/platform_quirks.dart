import 'package:flutter/foundation.dart';

/// Workarounds for browser specific behaviour of the web app.
abstract final class PlatformQuirks {
  /// Web app running on iPhone / iPad (Safari, home screen app).
  static bool get isIosWeb =>
      kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// iOS Safari only opens the keyboard when a field is focused by a tap.
  /// An autofocused field looks focused, but the keyboard stays closed and
  /// the next tap on it does nothing – so autofocus is skipped there.
  static bool autofocus(bool requested) => requested && !isIosWeb;

  /// Autofill hints (password / new-password / username) make iOS Safari
  /// swallow the first tap on the field (no keyboard). Dropped on iOS web.
  static Iterable<String>? autofillHints(Iterable<String>? hints) =>
      isIosWeb ? null : hints;
}
