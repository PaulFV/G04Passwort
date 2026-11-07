import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/l10n/l10n.dart';
import '../core/theme/app_colors.dart';

/// Five-step strength scale (comparable to zxcvbn's 0–4 score).
enum PasswordStrengthLevel {
  veryWeak('Sehr schwach', AppColors.danger),
  weak('Schwach', Color(0xFFFF7A45)),
  fair('Mittel', AppColors.warning),
  strong('Stark', Color(0xFF7BE36A)),
  veryStrong('Sehr stark', AppColors.success);

  const PasswordStrengthLevel(this._labelDe, this.color);

  final String _labelDe;

  /// Translated label.
  String get label => tr(_labelDe);
  final Color color;
}

/// Result of a password analysis.
@immutable
class PasswordStrength {
  const PasswordStrength({
    required this.score,
    required this.entropyBits,
    this.feedback = const [],
    this.isEmpty = false,
  });

  static const empty = PasswordStrength(
    score: 0,
    entropyBits: 0,
    isEmpty: true,
  );

  /// 0 (very weak) … 4 (very strong).
  final int score;

  /// Estimated entropy after penalties.
  final double entropyBits;

  /// Human readable hints how to improve the password.
  final List<String> feedback;
  final bool isEmpty;

  PasswordStrengthLevel get level =>
      PasswordStrengthLevel.values[score.clamp(0, 4)];

  bool get isWeak => !isEmpty && score <= 1;
  bool get isStrong => score >= 3;

  /// Rough offline-attack crack time estimate (10^10 guesses/s).
  String get crackTimeLabel {
    if (isEmpty) return '–';
    final seconds = (entropyBits >= 1000)
        ? double.infinity
        : _pow2(entropyBits) / 2 / 1e10;
    if (seconds < 1) return 'sofort';
    if (seconds < 60) return tr('{round} Sekunden', {'round': seconds.round()});
    if (seconds < 3600) return tr('{v} Minuten', {'v': (seconds / 60).round()});
    if (seconds < 86400) return tr('{v} Stunden', {'v': (seconds / 3600).round()});
    if (seconds < 31536000) return tr('{v} Tage', {'v': (seconds / 86400).round()});
    final years = seconds / 31536000;
    if (years < 1000) return tr('{round} Jahre', {'round': years.round()});
    if (years < 1e6) return tr('{v} Tsd. Jahre', {'v': (years / 1000).round()});
    return tr('Jahrhunderte+');
  }

  static double _pow2(double bits) => math.pow(2, bits).toDouble();
}
