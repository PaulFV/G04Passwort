import 'package:flutter/foundation.dart';

import 'password_strength.dart';

/// Per-item finding of the security audit.
@immutable
class ItemAudit {
  const ItemAudit({
    required this.itemId,
    required this.strength,
    required this.reused,
    required this.old,
    required this.hasTotp,
  });

  final String itemId;
  final PasswordStrength strength;
  final bool reused;
  final bool old;
  final bool hasTotp;
}

/// Aggregated result of the security center analysis.
@immutable
class SecurityReport {
  const SecurityReport({
    required this.audits,
    required this.reusedGroups,
    required this.score,
  });

  static const empty = SecurityReport(audits: [], reusedGroups: [], score: 100);

  final List<ItemAudit> audits;

  /// Groups of item ids sharing the same password (Duplikat-Erkennung).
  final List<List<String>> reusedGroups;

  /// Overall score 0–100.
  final int score;

  int get total => audits.length;
  int get strong => audits.where((a) => a.strength.score >= 3).length;
  int get medium => audits.where((a) => a.strength.score == 2).length;
  int get weak => audits.where((a) => a.strength.score <= 1).length;
  int get reused => audits.where((a) => a.reused).length;
  int get old => audits.where((a) => a.old).length;
  int get withTotp => audits.where((a) => a.hasTotp).length;

  String get scoreLabel => switch (score) {
        >= 90 => 'Sehr sicher',
        >= 75 => 'Sicher',
        >= 50 => 'Verbesserungswürdig',
        _ => 'Gefährdet',
      };
}
