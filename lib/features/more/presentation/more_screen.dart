import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../app/routes.dart';
import '../../../core/utils/responsive.dart';
import '../../../widgets/common.dart';
import '../../../widgets/feature_icon.dart';
import '../../../widgets/g04_scaffold.dart';

/// Mehr / Weitere Funktionen (design screen 16).
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries =
        <({FeatureIcon icon, String title, String? subtitle, String route})>[
          (
            icon: FeatureIcon.importExport,
            title: tr('Passwort-Import'),
            subtitle: tr('Bitwarden, KeePass, 1Password'),
            route: Routes.backup,
          ),
          (
            icon: FeatureIcon.passwords,
            title: tr('Passwort-Verlauf'),
            subtitle: tr('Letzte Änderungen'),
            route: Routes.history,
          ),
          (
            icon: FeatureIcon.notes,
            title: tr('Sichere Notizen'),
            subtitle: null,
            route: Routes.notes,
          ),
          (
            icon: FeatureIcon.totp,
            title: tr('TOTP Generator'),
            subtitle: tr('2FA Authenticator'),
            route: Routes.authenticator,
          ),
          (
            icon: FeatureIcon.security,
            title: tr('Sicherheitszentrum'),
            subtitle: null,
            route: Routes.security,
          ),
          (
            icon: FeatureIcon.analysis,
            title: tr('Passwort-Analyse'),
            subtitle: null,
            route: Routes.analysis,
          ),
          (
            icon: FeatureIcon.cards,
            title: tr('Kreditkarten'),
            subtitle: null,
            route: Routes.cards,
          ),
          (
            icon: FeatureIcon.documents,
            title: tr('Dokumente'),
            subtitle: null,
            route: Routes.documents,
          ),
          (
            icon: FeatureIcon.favorites,
            title: tr('Favoriten'),
            subtitle: null,
            route: '${Routes.vault}?filter=favorites',
          ),
          (
            icon: FeatureIcon.search,
            title: tr('Suche'),
            subtitle: null,
            route: Routes.search,
          ),
          (
            icon: FeatureIcon.cloud,
            title: tr('Cloud Sync'),
            subtitle: null,
            route: Routes.sync,
          ),
          (
            icon: FeatureIcon.settings,
            title: tr('Einstellungen'),
            subtitle: null,
            route: Routes.settings,
          ),
        ];
    return G04Scaffold(
      title: tr('Mehr'),
      wide: true,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          ResponsiveGrid(
            minItemWidth: 320,
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
            title: tr('Profil'),
            onTap: () => context.push(Routes.profile),
          ),
          GlassTile(
            icon: Icons.info_outline_rounded,
            title: tr('Über G04Passwort'),
            onTap: () => context.push(Routes.about),
          ),
            ],
          ),
        ],
      ),
    );
  }
}
