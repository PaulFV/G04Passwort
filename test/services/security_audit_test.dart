import 'package:flutter_test/flutter_test.dart';
import 'package:g04passwort/models/item_category.dart';
import 'package:g04passwort/models/vault_item.dart';
import 'package:g04passwort/models/vault_item_type.dart';
import 'package:g04passwort/services/password_analyzer_service.dart';
import 'package:g04passwort/services/security_audit_service.dart';

VaultItem login(String id, String password, {DateTime? changed, String? totp}) {
  final now = DateTime(2026, 10, 1);
  return VaultItem(
    id: id,
    type: VaultItemType.login,
    title: id,
    category: ItemCategory.login,
    createdAt: now,
    updatedAt: now,
    login: LoginData(password: password, passwordChangedAt: changed ?? now, totpSecret: totp),
  );
}

void main() {
  const audit = SecurityAuditService(PasswordAnalyzerService());

  test('empty vault scores 100', () {
    expect(audit.audit(const []).score, 100);
  });

  test('detects duplicates, weak, old and 2FA', () {
    final report = audit.audit(
      [
        login('a', r'G7f#k9!Qp2@Z8&Lm', totp: 'JBSWY3DPEHPK3PXP'),
        login('b', '123456'),
        login('c', '123456'),
        login('d', r'X!9vB$e2#Lq7^Wm4', changed: DateTime(2024, 1, 1)),
      ],
      now: DateTime(2026, 10, 2),
    );
    expect(report.total, 4);
    expect(report.reused, 2);
    expect(report.reusedGroups.single, containsAll(['b', 'c']));
    expect(report.weak, 2);
    expect(report.old, 1);
    expect(report.withTotp, 1);
    expect(report.score, lessThan(100));
  });
}
