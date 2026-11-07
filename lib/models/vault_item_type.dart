import 'package:flutter/material.dart';

import '../core/l10n/l10n.dart';

/// Structural type of a vault entry – decides which fields exist.
enum VaultItemType {
  login('Login', Icons.key_rounded),
  card('Kreditkarte', Icons.credit_card_rounded),
  document('Dokument', Icons.description_rounded),
  note('Sichere Notiz', Icons.sticky_note_2_rounded);

  const VaultItemType(this._labelDe, this.icon);

  final String _labelDe;

  /// Translated label.
  String get label => tr(_labelDe);
  final IconData icon;

  static VaultItemType fromName(String? name) => VaultItemType.values
      .firstWhere((t) => t.name == name, orElse: () => VaultItemType.login);
}
