import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/circular_gauge.dart';
import '../../../widgets/common.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/neon_button.dart';
import '../../vault/application/vault_providers.dart';

/// Colour for a security score.
Color scoreColor(int score) => switch (score) {
      >= 75 => AppColors.success,
      >= 50 => AppColors.warning,
      _ => AppColors.danger,
    };

/// Sicherheitszentrum (design screen 7).
class SecurityCenterScreen extends ConsumerWidget {
  const SecurityCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(securityReportProvider);
    final color = scoreColor(report.score);

    return G04Scaffold(
      title: 'Sicherheitszentrum',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.shield_rounded,
                  size: 210,
                  color: color.withValues(alpha: 0.12),
                  shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 30)],
                ),
                CircularGauge(
                  value: report.score / 100,
                  color: color,
                  size: 170,
                  strokeWidth: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${report.score}%', style: context.text.displaySmall),
                      Text(report.scoreLabel, style: context.text.bodySmall?.copyWith(color: color)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text(report.scoreLabel, style: context.text.titleLarge)),
          const SizedBox(height: 18),
          GlassTile(
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.success,
            title: 'Starke Passwörter',
            value: '${report.strong}',
            onTap: () => context.push(Routes.analysis),
          ),
          GlassTile(
            icon: Icons.copy_all_rounded,
            iconColor: AppColors.warning,
            title: 'Doppelte Passwörter',
            value: '${report.reused}',
            onTap: () => context.push(Routes.analysis),
          ),
          GlassTile(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.danger,
            title: 'Schwache Passwörter',
            value: '${report.weak}',
            onTap: () => context.push(Routes.analysis),
          ),
          GlassTile(
            icon: Icons.update_rounded,
            iconColor: AppColors.warning,
            title: 'Älter als 1 Jahr',
            value: '${report.old}',
            onTap: () => context.push(Routes.analysis),
          ),
          const GlassTile(
            icon: Icons.travel_explore_rounded,
            iconColor: AppColors.danger,
            title: 'Leckage-Warnungen',
            subtitle: 'Online-Prüfung (Have I Been Pwned, k-Anonymität) in Vorbereitung',
            value: '0',
          ),
          GlassTile(
            icon: Icons.verified_user_rounded,
            iconColor: AppColors.success,
            title: '2FA aktiviert',
            value: '${report.withTotp}',
            onTap: () => context.push(Routes.authenticator),
          ),
          const SizedBox(height: 14),
          NeonButton(label: 'Details anzeigen', onPressed: () => context.push(Routes.analysis)),
        ],
      ),
    );
  }
}
