import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'native_secret_input.dart';

Widget buildNativeSecretInput(NativeSecretInput config) =>
    _NativeSecretInput(config: config);

String _css(Color c) =>
    'rgba(${(c.r * 255).round()}, ${(c.g * 255).round()}, '
    '${(c.b * 255).round()}, ${c.a.toStringAsFixed(3)})';

void _ensureStyleSheet() {
  if (web.document.getElementById('g04-native-input-style') != null) return;
  final style = web.document.createElement('style') as web.HTMLStyleElement
    ..id = 'g04-native-input-style'
    ..textContent =
        'input.g04-native{all:unset;box-sizing:border-box;width:100%;'
        'height:100%;font:17px -apple-system,BlinkMacSystemFont,Roboto,sans-serif;'
        'letter-spacing:.3px;-webkit-user-select:text;user-select:text;'
        'touch-action:manipulation;}'
        'input.g04-native::placeholder{color:var(--g04-ph);opacity:1;}';
  web.document.head?.append(style);
}

class _NativeSecretInput extends StatefulWidget {
  const _NativeSecretInput({required this.config});

  final NativeSecretInput config;

  @override
  State<_NativeSecretInput> createState() => _NativeSecretInputState();
}

class _NativeSecretInputState extends State<_NativeSecretInput> {
  web.HTMLInputElement? _input;

  NativeSecretInput get _c => widget.config;

  @override
  void initState() {
    super.initState();
    _c.controller.addListener(_syncFromController);
  }

  @override
  void didUpdateWidget(_NativeSecretInput old) {
    super.didUpdateWidget(old);
    if (old.config.controller != _c.controller) {
      old.config.controller.removeListener(_syncFromController);
      _c.controller.addListener(_syncFromController);
    }
    _applyConfig();
  }

  @override
  void dispose() {
    _c.controller.removeListener(_syncFromController);
    final input = _input;
    if (input != null) input.value = '';
    super.dispose();
  }

  void _syncFromController() {
    final input = _input;
    if (input != null && input.value != _c.controller.text) {
      input.value = _c.controller.text;
    }
  }

  void _applyConfig() {
    final input = _input;
    if (input == null) return;
    input
      ..type = _c.obscured ? 'password' : 'text'
      ..placeholder = _c.placeholder
      ..autocomplete = _c.autocomplete;
    input.style
      ..color = _css(_c.textColor)
      ..setProperty('caret-color', _css(_c.textColor))
      ..setProperty('--g04-ph', _css(_c.placeholderColor));
  }

  void _created(Object element) {
    _ensureStyleSheet();
    final input = element as web.HTMLInputElement;
    _input = input;
    input
      ..className = 'g04-native'
      ..value = _c.controller.text
      ..spellcheck = false
      ..enterKeyHint = 'done'
      ..setAttribute('autocorrect', 'off')
      ..setAttribute('autocapitalize', 'none');
    _applyConfig();

    input.addEventListener(
      'input',
      ((web.Event _) {
        final value = input.value;
        if (_c.controller.text != value) {
          _c.controller.value = TextEditingValue(
            text: value,
            selection: TextSelection.collapsed(offset: value.length),
          );
        }
        _c.onChanged?.call(value);
      }).toJS,
    );
    input.addEventListener(
      'keydown',
      ((web.KeyboardEvent e) {
        if (e.key == 'Enter') {
          e.preventDefault();
          input.blur();
          _c.onSubmitted?.call(input.value);
        }
      }).toJS,
    );
    input.addEventListener(
      'focus',
      ((web.Event _) => _c.onFocusChange?.call(true)).toJS,
    );
    input.addEventListener(
      'blur',
      ((web.Event _) => _c.onFocusChange?.call(false)).toJS,
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView.fromTagName(
      tagName: 'input',
      onElementCreated: _created,
    );
  }
}
