import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../app/routes.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common.dart';
import '../../../widgets/feature_icon.dart';
import '../../../widgets/g04_logo.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/glass_card.dart';

/// About – version, security architecture and licences.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return G04Scaffold(
      title: tr('Über'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SizedBox(height: 8),
          Center(child: Image.asset(kLogoAsset, width: 240)),
          const SizedBox(height: 6),
          Center(
            child: Text(
              tr('Version {version} ({buildNumber})', {'version': AppConstants.version, 'buildNumber': AppConstants.buildNumber}),
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 18),
          GridView.extent(
            maxCrossAxisExtent: 120,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.78,
            children: [
              for (final f in FeatureIcon.values)
                Column(
                  children: [
                    FeatureIconImage(f, size: 58),
                    const SizedBox(height: 4),
                    Text(
                      f.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: context.text.labelSmall,
                    ),
                  ],
                ),
            ],
          ),
          SectionHeader(tr('Sicherheitsarchitektur')),
          GlassCard(
            child: Text(
              tr('• Zero-Knowledge: Alle Daten werden ausschließlich lokal ver- und entschlüsselt.\n'
      '• AES-256-GCM (authentifizierte Verschlüsselung) für jeden Eintrag, Ordner und jede Datei.\n'
      '• Argon2id (19 MiB, t=2) leitet den Schlüssel aus dem Master-Passwort ab; PBKDF2-SHA256 als Fallback.\n'
      '• Zufälliger 256-Bit-Tresorschlüssel, gekapselt mit dem Master-Schlüssel.\n'
      '• Schlüssel nur im Arbeitsspeicher; Auto-Lock, Zwischenablage-Löschung, Screenshot-Schutz.'),
            ),
          ),
          SectionHeader(tr('Rechtliches')),
          GlassTile(
            icon: Icons.privacy_tip_outlined,
            title: tr('Datenschutzerklärung'),
            onTap: () => context.push(Routes.privacy),
          ),
          GlassTile(
            icon: Icons.copyright_rounded,
            title: tr('Copyright'),
            subtitle: AppConstants.rightsReserved,
            onTap: () => context.push(Routes.copyright),
          ),
          GlassTile(
            icon: Icons.description_outlined,
            title: tr('Open-Source-Lizenzen'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppConstants.appName,
              applicationVersion: AppConstants.version,
              applicationLegalese: AppConstants.rightsReserved,
            ),
          ),
          GlassTile(
            icon: Icons.code_rounded,
            title: tr('Quellcode'),
            subtitle: AppConstants.repositoryUrl,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              AppConstants.rightsReserved,
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
