import 'package:flutter/material.dart';

import 'vault_item_type.dart';

/// Categories shown in "Kategorien". Each category maps to a default item
/// type (which decides the form fields) plus icon & colour.
///
/// Besides the classic categories it covers technical access data such as
/// devices, HMIs, routers and portals.
enum ItemCategory {
  login('Logins', Icons.person_rounded, Color(0xFF2F8CFF), VaultItemType.login),
  card(
    'Kreditkarten',
    Icons.credit_card_rounded,
    Color(0xFF7C5CFF),
    VaultItemType.card,
  ),
  document(
    'Dokumente',
    Icons.description_rounded,
    Color(0xFF38A3FF),
    VaultItemType.document,
  ),
  note(
    'Notizen',
    Icons.sticky_note_2_rounded,
    Color(0xFFFFC857),
    VaultItemType.note,
  ),
  wifi('WLAN', Icons.wifi_rounded, Color(0xFF38D6FF), VaultItemType.login),
  license(
    'Software-Lizenzen',
    Icons.vpn_key_rounded,
    Color(0xFF4C7DFF),
    VaultItemType.login,
  ),
  identity(
    'Identitäten',
    Icons.badge_rounded,
    Color(0xFF2EE59D),
    VaultItemType.document,
  ),
  device(
    'Geräte',
    Icons.devices_other_rounded,
    Color(0xFF5AC8FA),
    VaultItemType.login,
  ),
  hmi(
    'HMI / Steuerungen',
    Icons.precision_manufacturing_rounded,
    Color(0xFFFF8A3D),
    VaultItemType.login,
  ),
  router(
    'Router & Netzwerk',
    Icons.router_rounded,
    Color(0xFF00C2A8),
    VaultItemType.login,
  ),
  portal(
    'Portale',
    Icons.language_rounded,
    Color(0xFF9B7BFF),
    VaultItemType.login,
  ),
  other(
    'Sonstiges',
    Icons.category_rounded,
    Color(0xFF8FA3C4),
    VaultItemType.login,
  );

  const ItemCategory(this.label, this.icon, this.color, this.defaultType);

  final String label;
  final IconData icon;
  final Color color;
  final VaultItemType defaultType;

  static ItemCategory fromName(String? name) => ItemCategory.values.firstWhere(
    (c) => c.name == name,
    orElse: () => ItemCategory.other,
  );

  /// Default category for a newly created item of [type].
  static ItemCategory forType(VaultItemType type) => switch (type) {
    VaultItemType.login => ItemCategory.login,
    VaultItemType.card => ItemCategory.card,
    VaultItemType.document => ItemCategory.document,
    VaultItemType.note => ItemCategory.note,
  };
}
