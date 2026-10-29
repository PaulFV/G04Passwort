import 'package:flutter/material.dart';

/// Feature icons taken 1:1 from the design board (assets/icons).
enum FeatureIcon {
  aes('feat_aes', 'AES-256', 'Verschlüsselung'),
  biometric('feat_biometric', 'Biometrie', 'Fingerabdruck & Face ID'),
  cloud('feat_cloud', 'Cloud-Sync', 'Optional'),
  twofa('feat_twofa', '2FA', 'Zwei-Faktor-Authentifizierung'),
  autolock('feat_autolock', 'Auto-Lock', 'Sperre bei Inaktivität'),
  generator('feat_generator', 'Passwort-Generator', 'Starke Passwörter'),
  autosave('feat_autosave', 'Automatisches Speichern', 'von Logins'),
  securityCheck('feat_securitycheck', 'Sicherheits-Check', 'Schwache & doppelte Passwörter erkennen'),
  cards('feat_cards', 'Kreditkarten', 'Sicher speichern'),
  documents('feat_documents', 'Dokumente', '& Notizen');

  const FeatureIcon(this.file, this.title, this.subtitle);

  final String file;
  final String title;
  final String subtitle;

  String get asset => 'assets/icons/$file.png';
}

/// Renders a [FeatureIcon] image tile.
class FeatureIconImage extends StatelessWidget {
  const FeatureIconImage(this.icon, {super.key, this.size = 64});

  final FeatureIcon icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      icon.asset,
      width: size,
      height: size * 0.84,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
