import 'package:flutter_test/flutter_test.dart';
import 'package:g04passwort/models/app_settings.dart';
import 'package:g04passwort/models/item_category.dart';
import 'package:g04passwort/models/vault_item.dart';
import 'package:g04passwort/models/vault_item_type.dart';

void main() {
  final now = DateTime(2026, 10, 29, 12);

  test('login item JSON round trip', () {
    final item = VaultItem(
      id: '1',
      type: VaultItemType.login,
      title: 'Router Büro',
      category: ItemCategory.router,
      tags: const ['netzwerk'],
      favorite: true,
      createdAt: now,
      updatedAt: now,
      login: LoginData(
        username: 'admin',
        password: 'pw',
        urls: const ['http://192.168.0.1'],
        host: '192.168.0.1',
        passwordHistory: [
          PasswordHistoryEntry(password: 'old', changedAt: now),
        ],
      ),
      customFields: const [
        CustomField(name: 'PIN', value: '1234', secret: true),
      ],
    );
    final copy = VaultItem.fromJson(item.toJson());
    expect(copy.title, 'Router Büro');
    expect(copy.category, ItemCategory.router);
    expect(copy.login!.host, '192.168.0.1');
    expect(copy.login!.passwordHistory.single.password, 'old');
    expect(copy.customFields.single.secret, isTrue);
    expect(copy.favorite, isTrue);
    expect(copy.searchText, contains('192.168.0.1'));
  });

  test('card helpers', () {
    const card = CardData(
      number: '4242 4242 4242 4242',
      expiryMonth: 1,
      expiryYear: 20,
    );
    expect(card.brand, 'VISA');
    expect(card.masked, '•••• 4242');
    expect(card.expiryLabel, '01/20');
    expect(card.isExpired, isTrue);
    expect(const CardData(number: '5555555555554444').brand, 'Mastercard');
    expect(const CardData(number: '378282246310005').brand, 'AMEX');
  });

  test('settings JSON round trip', () {
    const s = AppSettings(
      autoLockSeconds: 300,
      biometricEnabled: true,
      syncProviders: {'icloud': true},
    );
    final copy = AppSettings.fromJson(s.toJson());
    expect(copy.autoLockSeconds, 300);
    expect(copy.biometricEnabled, isTrue);
    expect(copy.syncProviders['icloud'], isTrue);
    expect(AppSettings.durationLabel(0), 'Sofort');
    expect(AppSettings.durationLabel(-1), 'Nie');
  });
}
