import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../app/routes.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/item_category.dart';
import '../../../models/security_report.dart';
import '../../../widgets/common.dart';
import '../../../widgets/depth.dart';
import '../../../widgets/feature_icon.dart';
import '../../../widgets/g04_logo.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../auth/application/auth_controller.dart';
import '../../vault/application/vault_providers.dart';
import '../../vault/presentation/widgets/item_widgets.dart';

/// Tresor Übersicht (design screen 3): 3D vault status card, search,
/// raised quick tiles (Alle, Favoriten, Kategorien), quick actions,
/// favourites and category overview.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);
    final favorites = ref.watch(favoritesProvider);
    final counts = ref.watch(categoryCountsProvider);
    final report = ref.watch(securityReportProvider);

    return G04Scaffold(
      showAppBar: false,
      wide: true,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(onLock: () => _lock(ref))),
          SliverToBoxAdapter(
            child: _VaultHero(
              entries: items.length,
              report: report,
              onTap: () => context.push(Routes.security),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: VaultSearchBar(
                onTap: () => context.push(Routes.search),
                onAdd: () => context.push(Routes.newItem),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickTile(
                      icon: FeatureIcon.passwords,
                      label: tr('Alle'),
                      value: '${items.length}',
                      onTap: () => context.push(Routes.vault),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickTile(
                      icon: FeatureIcon.favorites,
                      label: tr('Favoriten'),
                      value: '${favorites.length}',
                      accent: const Color(0xFF7C8CFF),
                      onTap: () =>
                          context.push('${Routes.vault}?filter=favorites'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickTile(
                      icon: FeatureIcon.folder,
                      label: tr('Kategorien'),
                      value: '${ItemCategory.values.length}',
                      accent: AppColors.cyan,
                      onTap: () => context.go(Routes.categories),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: SectionHeader(tr('Schnellzugriff'))),
          SliverToBoxAdapter(
            child: Row(
              children: [
                for (final (i, a) in [
                  (FeatureIcon.generator, tr('Generator'), () => context.go(Routes.generator)),
                  (FeatureIcon.totp, '2FA', () => context.push(Routes.authenticator)),
                  (FeatureIcon.analysis, tr('Analyse'), () => context.push(Routes.analysis)),
                  (FeatureIcon.importExport, tr('Backup'), () => context.push(Routes.backup)),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _ActionTile(icon: a.$1, label: a.$2, onTap: a.$3),
                  ),
                ],
              ],
            ),
          ),
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: EmptyState(
                  icon: Icons.lock_open_rounded,
                  title: tr('Dein Tresor ist bereit'),
                  message:
                      tr('Lege deinen ersten Eintrag an oder importiere Passwörter aus einem anderen Manager.'),
                  action: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      Button3D(
                        icon: Icons.add_rounded,
                        label: tr('Neuer Eintrag'),
                        onTap: () => context.push(Routes.newItem),
                      ),
                      Button3D(
                        icon: Icons.file_download_outlined,
                        label: tr('Importieren'),
                        primary: false,
                        onTap: () => context.push(Routes.backup),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (items.isNotEmpty)
            SliverToBoxAdapter(
              child: ResponsiveGrid(
                minItemWidth: 360,
                spacing: 20,
                children: [
                  if (favorites.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionHeader(
                          tr('Favoriten'),
                          actionLabel: favorites.length > 5 ? tr('Alle') : null,
                          onAction: () =>
                              context.push('${Routes.vault}?filter=favorites'),
                        ),
                        for (final (i, item) in favorites.take(5).indexed)
                          AnimatedEntrance(
                            index: i,
                            child: VaultItemTile(item: item),
                          ),
                      ],
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeader(tr('Kategorien')),
                      for (final (c, icon) in const [
                        (ItemCategory.login, FeatureIcon.passwords),
                        (ItemCategory.card, FeatureIcon.cards),
                        (ItemCategory.document, FeatureIcon.documents),
                        (ItemCategory.note, FeatureIcon.notes),
                      ])
                        _CategoryRow(
                          icon: icon,
                          title: c.label,
                          count: counts[c] ?? 0,
                          onTap: () => context.push(switch (c) {
                            ItemCategory.card => Routes.cards,
                            ItemCategory.document => Routes.documents,
                            ItemCategory.note => Routes.notes,
                            _ => '${Routes.vault}?category=${c.name}',
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _lock(WidgetRef ref) => ref.read(authControllerProvider.notifier).lock(manual: true);
}

class _Header extends StatelessWidget {
  const _Header({required this.onLock});

  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(kLogoMarkAsset, width: 40, height: 40),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'G04',
                    style: context.text.titleLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.neonBlueLight
                          : AppColors.neonBlue,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: AppColors.neonBlue, blurRadius: 12),
                      ],
                    ),
                  ),
                  TextSpan(text: 'Passwort', style: context.text.titleLarge),
                ],
              ),
            ),
          ),
          RoundButton3D(
            icon: Icons.shield_outlined,
            tooltip: tr('Sicherheitszentrum'),
            onTap: () => context.push(Routes.security),
          ),
          const SizedBox(width: 10),
          RoundButton3D(
            icon: Icons.lock_outline_rounded,
            tooltip: tr('Sperren'),
            onTap: onLock,
          ),
        ],
      ),
    );
  }
}

/// Large raised status card with the 3D lock from the asset sheet.
class _VaultHero extends StatelessWidget {
  const _VaultHero({
    required this.entries,
    required this.report,
    required this.onTap,
  });

  final int entries;
  final SecurityReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasData = report.total > 0;
    final color = !hasData || report.score >= 75
        ? AppColors.success
        : report.score >= 50
        ? AppColors.warning
        : AppColors.danger;
    return Raised3D(
      onTap: onTap,
      radius: 24,
      depth: 8,
      padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
      semanticLabel: tr('Sicherheitszentrum öffnen'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: color, size: 18,
                        shadows: [Shadow(color: color, blurRadius: 10)]),
                    const SizedBox(width: 6),
                    Text(
                      tr('Tresor gesichert'),
                      style: context.text.labelLarge?.copyWith(color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  hasData ? report.scoreLabel : tr('Bereit für deine Daten'),
                  style: context.text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tr('AES-256-GCM · Zero-Knowledge'),
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(value: '$entries', label: tr('Einträge')),
                    _StatChip(
                      value: hasData ? '${report.score}%' : '–',
                      label: tr('Sicherheit'),
                      color: color,
                    ),
                    _StatChip(value: '${report.withTotp}', label: '2FA'),
                  ],
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/branding/lock_3d.png',
            height: 128,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.neonBlueLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.28),
        border: Border.all(color: c.withValues(alpha: 0.45)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$value ',
              style: context.text.labelLarge?.copyWith(color: c),
            ),
            TextSpan(
              text: label,
              style: context.text.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.accent,
  });

  final FeatureIcon icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Raised3D(
      onTap: onTap,
      accent: accent,
      radius: 18,
      depth: 7,
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
      semanticLabel: '$label: $value',
      child: Column(
        children: [
          FeatureIconImage(icon, size: 46),
          const SizedBox(height: 8),
          Text(
            value,
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final FeatureIcon icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Raised3D(
      onTap: onTap,
      radius: 16,
      depth: 5,
      glow: false,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      semanticLabel: label,
      child: Column(
        children: [
          FeatureIconImage(icon, size: 38),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final FeatureIcon icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Raised3D(
        onTap: onTap,
        radius: 16,
        depth: 5,
        glow: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        semanticLabel: '$title: $count',
        child: Row(
          children: [
            FeatureIconImage(icon, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.neonBlue.withValues(alpha: 0.18),
                border: Border.all(
                  color: AppColors.neonBlue.withValues(alpha: 0.5),
                ),
              ),
              child: Text('$count', style: context.text.labelLarge),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
