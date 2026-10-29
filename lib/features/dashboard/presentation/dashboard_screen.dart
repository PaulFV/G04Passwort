import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/item_category.dart';
import '../../../widgets/common.dart';
import '../../../widgets/g04_logo.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/glass_card.dart';
import '../../auth/application/auth_controller.dart';
import '../../vault/application/vault_providers.dart';
import '../../vault/presentation/widgets/item_widgets.dart';

/// Tresor Übersicht (design screen 3): search, quick tiles (Alle,
/// Favoriten, Kategorien), favourites and category overview.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);
    final favorites = ref.watch(favoritesProvider);
    final counts = ref.watch(categoryCountsProvider);

    return G04Scaffold(
      showAppBar: false,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(kLogoMarkAsset, width: 40, height: 40),
                  ),
                  const SizedBox(width: 10),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'G04',
                          style: context.text.titleLarge?.copyWith(
                            color: AppColors.neonBlueLight,
                            fontWeight: FontWeight.w900,
                            shadows: const [Shadow(color: AppColors.neonBlue, blurRadius: 12)],
                          ),
                        ),
                        TextSpan(text: 'Passwort', style: context.text.titleLarge),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Sicherheitszentrum',
                    icon: const Icon(Icons.shield_outlined),
                    onPressed: () => context.push(Routes.security),
                  ),
                  IconButton(
                    tooltip: 'Sperren',
                    icon: const Icon(Icons.lock_outline_rounded),
                    onPressed: () => _lock(ref),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: VaultSearchBar(
              onTap: () => context.push(Routes.search),
              onAdd: () => context.push(Routes.newItem),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.person_rounded,
                      label: 'Alle',
                      value: '${items.length}',
                      onTap: () => context.push(Routes.vault),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFFFC857),
                      label: 'Favoriten',
                      value: '${favorites.length}',
                      onTap: () => context.push('${Routes.vault}?filter=favorites'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.grid_view_rounded,
                      label: 'Kategorien',
                      onTap: () => context.go(Routes.categories),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: EmptyState(
                  icon: Icons.lock_open_rounded,
                  title: 'Dein Tresor ist bereit',
                  message: 'Lege deinen ersten Eintrag an oder importiere Passwörter aus einem anderen Manager.',
                  action: Wrap(
                    spacing: 10,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                        onPressed: () => context.push(Routes.newItem),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Neuer Eintrag'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                        onPressed: () => context.push(Routes.backup),
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('Importieren'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (favorites.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: SectionHeader(
                'Favoriten',
                actionLabel: favorites.length > 5 ? 'Alle' : null,
                onAction: () => context.push('${Routes.vault}?filter=favorites'),
              ),
            ),
            SliverList.list(
              children: [
                for (final (i, item) in favorites.take(5).indexed)
                  AnimatedEntrance(index: i, child: VaultItemTile(item: item)),
              ],
            ),
          ],
          if (items.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SectionHeader('Kategorien')),
            SliverList.list(
              children: [
                for (final c in const [
                  ItemCategory.login,
                  ItemCategory.card,
                  ItemCategory.document,
                  ItemCategory.note,
                ])
                  GlassTile(
                    icon: c.icon,
                    iconColor: c.color,
                    title: c.label,
                    value: '${counts[c]}',
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
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _lock(WidgetRef ref) => ref.read(authControllerProvider.notifier).lock();
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.iconColor = AppColors.neonBlueLight,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      borderRadius: 16,
      borderColor: AppColors.neonBlue.withValues(alpha: 0.6),
      child: Column(
        children: [
          Icon(icon, color: iconColor, shadows: [Shadow(color: iconColor, blurRadius: 12)]),
          const SizedBox(height: 6),
          Text(label, style: context.text.labelLarge?.copyWith(fontSize: 13)),
          if (value != null)
            Text(value!, style: context.text.bodySmall?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
