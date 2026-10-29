import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../widgets/common.dart';
import '../../../widgets/feature_icon.dart';
import '../../../widgets/g04_scaffold.dart';

/// Mehr / Weitere Funktionen (design screen 16).
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <({FeatureIcon icon, String title, String? subtitle, String route})>[
      (icon: FeatureIcon.importExport, title: 'Passwort-Import', subtitle: 'Bitwarden, KeePass, 1Password', route: Routes.backup),
      (icon: FeatureIcon.passwords, title: 'Passwort-Verlauf', subtitle: 'Letzte Änderungen', route: Routes.history),
      (icon: FeatureIcon.notes, title: 'Sichere Notizen', subtitle: null, route: Routes.notes),
      (icon: FeatureIcon.totp, title: 'TOTP Generator', subtitle: '2FA Authenticator', route: Routes.authenticator),
      (icon: FeatureIcon.security, title: 'Sicherheitszentrum', subtitle: null, route: Routes.security),
      (icon: FeatureIcon.analysis, title: 'Passwort-Analyse', subtitle: null, route: Routes.analysis),
      (icon: FeatureIcon.cards, title: 'Kreditkarten', subtitle: null, route: Routes.cards),
      (icon: FeatureIcon.documents, title: 'Dokumente', subtitle: null, route: Routes.documents),
      (icon: FeatureIcon.favorites, title: 'Favoriten', subtitle: null, route: '${Routes.vault}?filter=favorites'),
      (icon: FeatureIcon.search, title: 'Suche', subtitle: null, route: Routes.search),
      (icon: FeatureIcon.cloud, title: 'Cloud Sync', subtitle: null, route: Routes.sync),
      (icon: FeatureIcon.settings, title: 'Einstellungen', subtitle: null, route: Routes.settings),
    ];
    return G04Scaffold(
      title: 'Mehr',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          for (final (i, e) in entries.indexed)
            AnimatedEntrance(
              index: i,
              child: GlassTile(
                leading: FeatureIconImage(e.icon, size: 40),
                title: e.title,
                subtitle: e.subtitle,
                onTap: () => context.push(e.route),
              ),
            ),
          GlassTile(
            icon: Icons.person_rounded,
            title: 'Profil',
            onTap: () => context.push(Routes.profile),
          ),
          GlassTile(
            icon: Icons.info_outline_rounded,
            title: 'Über G04Passwort',
            onTap: () => context.push(Routes.about),
          ),
        ],
      ),
    );
  }
}
