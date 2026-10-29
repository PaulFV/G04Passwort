import 'package:flutter/material.dart';

/// Structural type of a vault entry – decides which fields exist.
enum VaultItemType {
  login('Login', Icons.key_rounded),
  card('Kreditkarte', Icons.credit_card_rounded),
  document('Dokument', Icons.description_rounded),
  note('Sichere Notiz', Icons.sticky_note_2_rounded);

  const VaultItemType(this.label, this.icon);

  final String label;
  final IconData icon;

  static VaultItemType fromName(String? name) => VaultItemType.values
      .firstWhere((t) => t.name == name, orElse: () => VaultItemType.login);
}
