import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  Widget build(BuildContext context) {
    final toggle = widget.isSecret
        ? IconButton(
            tooltip: _obscured ? 'Anzeigen' : 'Verbergen',
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
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
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
}
