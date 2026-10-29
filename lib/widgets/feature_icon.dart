import 'package:flutter/material.dart';

/// The 16 feature icons taken 1:1 from the asset sheet (assets/icons).
enum FeatureIcon {
  passwords('ic_passwords', 'Passwörter'),
  generator('ic_generator', 'Generator'),
  security('ic_security', 'Sicherheit'),
  cards('ic_cards', 'Kreditkarten'),
  documents('ic_documents', 'Dokumente'),
  notes('ic_notes', 'Notizen'),
  cloud('ic_cloud', 'Cloud Sync'),
  settings('ic_settings', 'Einstellungen'),
  biometric('ic_biometric', 'Biometrie'),
  search('ic_search', 'Suche'),
  folder('ic_folder', 'Ordner'),
  favorites('ic_favorites', 'Favoriten'),
  tags('ic_tags', 'Tags'),
  totp('ic_totp', '2FA / TOTP'),
  importExport('ic_import_export', 'Import / Export'),
  analysis('ic_analysis', 'Analyse');

  const FeatureIcon(this.file, this.label);

  final String file;
  final String label;

  String get asset => 'assets/icons/$file.png';
}

/// Renders a [FeatureIcon] image tile.
class FeatureIconImage extends StatelessWidget {
  const FeatureIconImage(this.icon, {super.key, this.size = 56});

  final FeatureIcon icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      icon.asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
