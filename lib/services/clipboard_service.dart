import 'dart:async';

import 'package:flutter/services.dart';

/// Copies secrets to the clipboard and clears them automatically.
///
/// The clipboard is only cleared if it still contains the copied value,
/// so content the user copied afterwards is never destroyed.
class ClipboardService {
  Timer? _timer;

  /// Copies [text]. If [clearAfter] is non-null the clipboard is wiped
  /// after that duration.
  Future<void> copy(String text, {Duration? clearAfter}) async {
    await Clipboard.setData(ClipboardData(text: text));
    _timer?.cancel();
    if (clearAfter == null) return;
    _timer = Timer(clearAfter, () async {
      try {
        final current = await Clipboard.getData(Clipboard.kTextPlain);
        if (current?.text == text) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      } on Object {
        // Some platforms deny clipboard reads in the background – ignore.
      }
    });
  }

  /// Immediately clears the clipboard (e.g. when the vault is locked).
  Future<void> clearNow() async {
    _timer?.cancel();
    await Clipboard.setData(const ClipboardData(text: ''));
  }

  void dispose() => _timer?.cancel();
}
