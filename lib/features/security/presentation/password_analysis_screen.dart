import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/security_report.dart';
import '../../../widgets/circular_gauge.dart';
import '../../../widgets/common.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../vault/application/vault_providers.dart';
import '../../vault/presentation/widgets/item_widgets.dart';
import 'security_center_screen.dart' show scoreColor;

/// Passwort-Analyse (design screen 14): score plus lists of weak, reused
/// and old passwords so the user can fix them one by one.
class PasswordAnalysisScreen extends ConsumerWidget {
  const PasswordAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(securityReportProvider);
    final items = {for (final i in ref.watch(itemsProvider)) i.id: i};
    final color = scoreColor(report.score);

    Widget section(
      String title,
      Iterable<ItemAudit> audits, {
      String Function(ItemAudit a)? label,
    }) {
      final list = audits.where((a) => items.containsKey(a.itemId)).toList();
      if (list.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader('$title (${list.length})'),
          for (final a in list)
            VaultItemTile(
              item: items[a.itemId]!,
              trailing: StatusBadge(
                label?.call(a) ?? a.strength.level.label,
                color: a.strength.level.color,
              ),
            ),
        ],
      );
    }

    return G04Scaffold(
      title: tr('Passwort-Analyse'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Center(
            child: CircularGauge(
              value: report.score / 100,
              color: color,
              size: 150,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${report.score}%', style: context.text.headlineMedium),
                  Text(
                    report.scoreLabel,
                    style: context.text.bodySmall?.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GlassTile(
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.success,
            title: tr('Starke Passwörter'),
            value: '${report.strong}',
          ),
          GlassTile(
            icon: Icons.remove_circle_rounded,
            iconColor: AppColors.warning,
            title: tr('Mittlere Passwörter'),
            value: '${report.medium}',
          ),
          GlassTile(
            icon: Icons.cancel_rounded,
            iconColor: AppColors.danger,
            title: tr('Schwache Passwörter'),
            value: '${report.weak}',
          ),
          GlassTile(
            icon: Icons.copy_all_rounded,
            iconColor: AppColors.warning,
            title: tr('Doppelte Passwörter'),
            value: '${report.reused}',
          ),
          if (report.total == 0)
            EmptyState(
              icon: Icons.analytics_outlined,
              title: tr('Noch nichts zu analysieren'),
              message:
                  tr('Sobald du Logins speicherst, erscheint hier die Analyse.'),
            ),
          section(tr('Schwach'), report.audits.where((a) => a.strength.score <= 1)),
          section(
            tr('Doppelt verwendet'),
            report.audits.where((a) => a.reused),
            label: (_) => tr('Doppelt'),
          ),
          section(
            tr('Älter als 1 Jahr'),
            report.audits.where((a) => a.old),
            label: (_) => tr('Alt'),
          ),
          section(tr('Mittel'), report.audits.where((a) => a.strength.score == 2)),
        ],
      ),
    );
  }
}
