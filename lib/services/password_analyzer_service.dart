import 'dart:math';

import '../models/password_strength.dart';

/// Offline password strength estimation (no network, no external data).
///
/// Starts with the brute-force entropy (`length × log2(pool)`) and applies
/// penalties for patterns attackers try first: common passwords, keyboard
/// rows, sequences, repetitions, years and dictionary-like words.
class PasswordAnalyzerService {
  const PasswordAnalyzerService();

  static const _common = {
    '123456', '123456789', '12345678', 'password', 'passwort', 'qwerty',
    'qwertz', '111111', '123123', 'abc123', 'password1', 'iloveyou',
    'admin', 'welcome', 'monkey', 'dragon', 'letmein', 'hallo', 'hallo123',
    'schatz', 'master', 'sommer', 'fussball', 'football',
    'baseball', 'sunshine', 'princess', 'login', 'test', 'test123',
    'root', 'toor', '000000', '1234', '12345', 'geheim', 'secret',
  };

  static const _sequences = [
    'abcdefghijklmnopqrstuvwxyz',
    '01234567890',
    'qwertzuiopasdfghjklyxcvbnm',
    'qwertyuiopasdfghjklzxcvbnm',
  ];

  PasswordStrength analyze(String password) {
    if (password.isEmpty) return PasswordStrength.empty;

    final lower = password.toLowerCase();
    final feedback = <String>[];

    var pool = 0;
    final hasLower = password.contains(RegExp('[a-z]'));
    final hasUpper = password.contains(RegExp('[A-Z]'));
    final hasDigit = password.contains(RegExp('[0-9]'));
    final hasSymbol = password.contains(RegExp(r'[^a-zA-Z0-9]'));
    if (hasLower) pool += 26;
    if (hasUpper) pool += 26;
    if (hasDigit) pool += 10;
    if (hasSymbol) pool += 33;

    // Effective length: collapse runs of the same character.
    final effective = password.replaceAllMapped(RegExp(r'(.)\1{2,}'), (m) => m[1]! * 2);
    var entropy = effective.length * (log(max(pool, 1)) / ln2);

    if (_common.contains(lower) ||
        _common.contains(lower.replaceAll(RegExp(r'[0-9!.]+$'), ''))) {
      entropy = min(entropy, 8);
      feedback.add('Sehr häufiges Passwort – leicht zu erraten.');
    }

    final seqLen = _longestSequence(lower);
    if (seqLen >= 3) {
      entropy -= seqLen * 2.5;
      feedback.add('Vermeide Folgen wie „abc“, „123“ oder Tastaturreihen.');
    }
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) {
      feedback.add('Vermeide wiederholte Zeichen.');
    }
    if (RegExp(r'(19|20)\d{2}').hasMatch(password)) {
      entropy -= 6;
      feedback.add('Jahreszahlen sind leicht zu erraten.');
    }
    if (password.length < 8) feedback.add('Nutze mindestens 12 Zeichen.');
    if (!hasSymbol && password.length < 20) feedback.add('Füge Sonderzeichen hinzu.');
    if (!(hasUpper && hasLower) && password.length < 20) {
      feedback.add('Kombiniere Groß- und Kleinbuchstaben.');
    }
    if (RegExp(r'^[a-zA-Z]+[0-9]{1,4}[!?.]?$').hasMatch(password)) {
      entropy -= 10;
      feedback.add('Muster „Wort + Zahl“ ist sehr verbreitet.');
    }

    entropy = max(0, entropy);
    final score = switch (entropy) {
      < 28 => 0,
      < 40 => 1,
      < 60 => 2,
      < 80 => 3,
      _ => 4,
    };
    return PasswordStrength(score: score, entropyBits: entropy, feedback: feedback);
  }

  int _longestSequence(String s) {
    var best = 0;
    for (final seq in _sequences) {
      for (var len = min(s.length, 8); len >= 3; len--) {
        if (len <= best) break;
        for (var i = 0; i + len <= s.length; i++) {
          final part = s.substring(i, i + len);
          final reversed = part.split('').reversed.join();
          if (seq.contains(part) || seq.contains(reversed)) {
            best = len;
            break;
          }
        }
      }
    }
    return best;
  }
}
