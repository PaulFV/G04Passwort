import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/glass_card.dart';
import '../legal_texts.dart';

/// Which tab of the legal screen opens first.
enum LegalTab { privacy, copyright }

/// Rechtliches: Datenschutzerklärung and Copyright.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, this.initialTab = LegalTab.privacy});

  final LegalTab initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab.index,
      child: G04Scaffold(
        title: 'Rechtliches',
        body: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Datenschutz'),
                Tab(text: 'Copyright'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  const _LegalList(
                    headline: 'Datenschutzerklärung',
                    intro: PrivacyText.intro,
                    sections: PrivacyText.sections,
                    footer: PrivacyText.updated,
                  ),
                  const _CopyrightView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalList extends StatelessWidget {
  const _LegalList({
    required this.headline,
    required this.intro,
    required this.sections,
    required this.footer,
  });

  final String headline;
  final String intro;
  final List<LegalSection> sections;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Text(headline, style: context.text.headlineSmall),
        const SizedBox(height: 8),
        Text(intro, style: context.text.bodyMedium?.copyWith(height: 1.5)),
        const SizedBox(height: 12),
        for (final s in sections)
          GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                for (final p in s.paragraphs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SelectableText(
                      p,
                      style: context.text.bodySmall?.copyWith(
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Center(
          child: Text(footer, style: context.text.labelSmall?.copyWith(color: AppColors.textMuted)),
        ),
      ],
    );
  }
}

class _CopyrightView extends StatelessWidget {
  const _CopyrightView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Text(CopyrightText.headline, style: context.text.headlineSmall),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final p in CopyrightText.paragraphs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    p,
                    style: context.text.bodyMedium?.copyWith(height: 1.5, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassTile(
          icon: Icons.description_outlined,
          title: 'Open-Source-Lizenzen',
          subtitle: 'Flutter, Pakete und Schriftart Roboto',
          onTap: () => showLicensePage(
            context: context,
            applicationName: AppConstants.appName,
            applicationVersion: AppConstants.version,
            applicationLegalese: AppConstants.rightsReserved,
          ),
        ),
      ],
    );
  }
}
