import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/l10n/l10n.dart';
import '../core/utils/platform_quirks.dart';
import 'native_input/native_secret_input.dart';

/// Themed text field. With [isSecret] it obscures its value and shows a
/// visibility toggle. Secret fields disable autocorrect, suggestions and
/// personalised keyboard learning.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.icon,
    this.isSecret = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.autofocus = false,
    this.suffix,
    this.inputFormatters,
    this.autofillHints,
    this.readOnly = false,
    this.monospace = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final bool isSecret;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final bool autofocus;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final bool readOnly;
  final bool monospace;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.isSecret;
  bool _nativeFocused = false;

  /// iPhone/iPad web app: secret fields use a real browser input, because
  /// iOS Safari sometimes does not open the keyboard for Flutter's own one.
  bool get _useNativeInput =>
      PlatformQuirks.isIosWeb &&
      widget.isSecret &&
      !widget.readOnly &&
      widget.controller != null;

  @override
  Widget build(BuildContext context) {
    final toggle = widget.isSecret
        ? IconButton(
            tooltip: _obscured ? tr('Anzeigen') : tr('Verbergen'),
            icon: Icon(
              _obscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () => setState(() => _obscured = !_obscured),
          )
        : null;

    Widget? suffix;
    if (toggle != null && widget.suffix != null) {
      suffix = Row(
        mainAxisSize: MainAxisSize.min,
        children: [toggle, widget.suffix!],
      );
    } else {
      suffix = toggle ?? widget.suffix;
    }

    if (_useNativeInput) return _buildNative(context, suffix);

    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      obscureText: _obscured,
      enableSuggestions: !widget.isSecret,
      autocorrect: !widget.isSecret,
      enableIMEPersonalizedLearning: !widget.isSecret,
      keyboardType: widget.isSecret
          ? TextInputType.visiblePassword
          : widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.isSecret ? 1 : widget.maxLines,
      minLines: 1,
      autofocus: PlatformQuirks.autofocus(widget.autofocus),
      readOnly: widget.readOnly,
      inputFormatters: widget.inputFormatters,
      autofillHints: PlatformQuirks.autofillHints(widget.autofillHints),
      style: widget.monospace || (widget.isSecret && !_obscured)
          ? const TextStyle(fontFamily: 'monospace', letterSpacing: 0.5)
          : null,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.icon == null ? null : Icon(widget.icon),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _buildNative(BuildContext context, Widget? suffix) {
    final theme = Theme.of(context);
    final controller = widget.controller!;
    final hints = widget.autofillHints ?? const <String>[];
    // Login fields may use the iCloud keychain; a new master password is
    // chosen by the user (no generated "strong password").
    final autocomplete = hints.contains(AutofillHints.password)
        ? 'current-password'
        : 'off';
    return FormField<String>(
      validator: widget.validator == null
          ? null
          : (_) => widget.validator!(controller.text),
      builder: (field) {
        final decoration = InputDecoration(
          prefixIcon: widget.icon == null ? null : Icon(widget.icon),
          suffixIcon: suffix,
          errorText: field.errorText,
        ).applyDefaults(theme.inputDecorationTheme);
        return Stack(
          children: [
            InputDecorator(
              decoration: decoration,
              isFocused: _nativeFocused,
              isEmpty: true,
              child: const SizedBox(height: 24),
            ),
            Positioned(
              left: widget.icon == null ? 18 : 50,
              right: suffix == null ? 18 : 50,
              top: 0,
              height: 56,
              child: NativeSecretInput(
                controller: controller,
                placeholder: widget.label ?? widget.hint ?? '',
                obscured: _obscured,
                autocomplete: autocomplete,
                textColor: theme.colorScheme.onSurface,
                placeholderColor: theme.colorScheme.onSurfaceVariant,
                onChanged: (v) {
                  field.didChange(v);
                  widget.onChanged?.call(v);
                },
                onSubmitted: widget.onSubmitted,
                onFocusChange: (f) {
                  if (mounted) setState(() => _nativeFocused = f);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
