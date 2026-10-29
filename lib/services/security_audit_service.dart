import '../models/security_report.dart';
import '../models/vault_item.dart';
import '../models/vault_item_type.dart';
import 'password_analyzer_service.dart';

/// Computes the security center report: weak, reused (duplicates) and old
/// passwords, 2FA coverage and an overall score from 0–100.
class SecurityAuditService {
  const SecurityAuditService(this._analyzer);

  final PasswordAnalyzerService _analyzer;

  /// Passwords older than this are flagged as "alt".
  static const Duration maxPasswordAge = Duration(days: 365);

  SecurityReport audit(List<VaultItem> items, {DateTime? now}) {
    final logins = items
        .where(
          (i) =>
              i.type == VaultItemType.login &&
              (i.login?.password.isNotEmpty ?? false),
        )
        .toList();
    if (logins.isEmpty) return SecurityReport.empty;

    final reference = now ?? DateTime.now();
    final byPassword = <String, List<String>>{};
    for (final item in logins) {
      byPassword.putIfAbsent(item.login!.password, () => []).add(item.id);
    }
    final reusedGroups = byPassword.values
        .where((ids) => ids.length > 1)
        .toList();
    final reusedIds = reusedGroups.expand((g) => g).toSet();

    final audits = [
      for (final item in logins)
        ItemAudit(
          itemId: item.id,
          strength: _analyzer.analyze(item.login!.password),
          reused: reusedIds.contains(item.id),
          old:
              reference
                  .difference(item.login!.passwordChangedAt ?? item.createdAt)
                  .compareTo(maxPasswordAge) >
              0,
          hasTotp: item.login!.hasTotp,
        ),
    ];

    final n = audits.length;
    final weakRatio = audits.where((a) => a.strength.score <= 1).length / n;
    final mediumRatio = audits.where((a) => a.strength.score == 2).length / n;
    final reusedRatio = reusedIds.length / n;
    final oldRatio = audits.where((a) => a.old).length / n;
    final score =
        (100 -
                weakRatio * 45 -
                mediumRatio * 15 -
                reusedRatio * 30 -
                oldRatio * 10)
            .round()
            .clamp(0, 100);

    return SecurityReport(
      audits: audits,
      reusedGroups: reusedGroups,
      score: score,
    );
  }
}
