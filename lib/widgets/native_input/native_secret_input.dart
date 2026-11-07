import 'package:flutter/widgets.dart';

import 'native_secret_input_stub.dart'
    if (dart.library.js_interop) 'native_secret_input_web.dart'
    as impl;

/// A real browser `<input type="password">` embedded in the Flutter UI.
///
/// Used by the web app on iPhone/iPad only: iOS Safari reliably opens the
/// keyboard when the finger lands on a real input element, while Flutter's
/// own (synthesised) text input sometimes loses the first tap there.
///
/// Fills its parent; text styling comes from [textColor] / [fontSize].
class NativeSecretInput extends StatelessWidget {
  const NativeSecretInput({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.obscured,
    required this.textColor,
    required this.placeholderColor,
    this.autocomplete = 'off',
    this.onChanged,
    this.onSubmitted,
    this.onFocusChange,
  });

  final TextEditingController controller;
  final String placeholder;
  final bool obscured;
  final Color textColor;
  final Color placeholderColor;

  /// Value of the HTML `autocomplete` attribute, e.g. `current-password`.
  final String autocomplete;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<bool>? onFocusChange;

  @override
  Widget build(BuildContext context) => impl.buildNativeSecretInput(this);
}
