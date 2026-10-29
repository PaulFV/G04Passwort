import 'dart:async';

import 'package:flutter/services.dart';

/// Copies secrets to the clipboard and clears them automatically.
///
/// The clipboard is only cleared if it still contains the copied value,
/// so content the user copied afterwards is never destroyed.
class ClipboardService {
  Timer? _timer;

  /// Last secret copied by the app (kept only until it is cleared).
  String? _pending;

  /// Copies [text]. If [clearAfter] is non-null the clipboard is wiped
  /// after that duration.
  Future<void> copy(String text, {Duration? clearAfter}) async {
    await Clipboard.setData(ClipboardData(text: text));
    _timer?.cancel();
    _pending = null;
    if (clearAfter == null) return;
    _pending = text;
    _timer = Timer(clearAfter, () async {
      try {
        final current = await Clipboard.getData(Clipboard.kTextPlain);
        if (current?.text == text) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      } on Object {
        // Some platforms deny clipboard reads in the background – ignore.
      } finally {
        _pending = null;
      }
    });
  }

  /// Clears a pending secret right away (e.g. when the vault is locked).
  /// Unrelated clipboard content of the user is left untouched.
  Future<void> clearNow() async {
    _timer?.cancel();
    final secret = _pending;
    _pending = null;
    if (secret == null) return;
    try {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text != null && current!.text != secret) return;
    } on Object {
      // Reading may be denied (web) – clear to be safe.
    }
    await Clipboard.setData(const ClipboardData(text: ''));
  }

  void dispose() => _timer?.cancel();
}
