import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/vault_item_type.dart';
import '../../../widgets/common.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/neon_button.dart';
import '../../vault/application/vault_providers.dart';
import '../../vault/presentation/widgets/item_widgets.dart';

/// Kreditkarten (design screen 9).
class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(itemsByTypeProvider(VaultItemType.card));
    return G04Scaffold(
      title: 'Kreditkarten',
      body: Column(
        children: [
          Expanded(
            child: cards.isEmpty
                ? const EmptyState(
                    icon: Icons.credit_card_rounded,
                    title: 'Keine Karten',
                    message:
                        'Speichere Kredit-, Debit- und Kundenkarten sicher verschlüsselt.',
                  )
                : ListView(
                    children: [
                      for (final c in cards)
                        VaultItemTile(
                          item: c,
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                c.card!.brand,
                                style: context.text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.neonBlueLight,
                                ),
                              ),
                              if (c.card!.isExpired)
                                const StatusBadge(
                                  'Abgelaufen',
                                  color: AppColors.danger,
                                )
                              else if (c.card!.expiryLabel.isNotEmpty)
                                Text(
                                  c.card!.expiryLabel,
                                  style: context.text.labelSmall,
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: NeonButton(
              label: 'Neue Kreditkarte',
              icon: Icons.add_rounded,
              onPressed: () => context.push('${Routes.newItem}?type=card'),
            ),
          ),
        ],
      ),
    );
  }
}
