import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/vault_item_type.dart';
import '../../../widgets/common.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/neon_button.dart';
import '../../vault/application/vault_providers.dart';

/// Sichere Notizen (design screen 11).
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(itemsByTypeProvider(VaultItemType.note));
    return G04Scaffold(
      title: 'Notizen',
      body: Column(
        children: [
          Expanded(
            child: notes.isEmpty
                ? const EmptyState(
                    icon: Icons.sticky_note_2_rounded,
                    title: 'Keine Notizen',
                    message:
                        'WLAN-Zugänge, PINs, Wiederherstellungscodes – alles sicher verschlüsselt.',
                  )
                : ListView(
                    children: [
                      for (final n in notes)
                        GlassCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          onTap: () => context.push(Routes.item(n.id)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(n.category.icon, color: n.category.color),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.title,
                                      style: context.text.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n.notes,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
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
              label: 'Neue Notiz',
              icon: Icons.add_rounded,
              onPressed: () => context.push('${Routes.newItem}?type=note'),
            ),
          ),
        ],
      ),
    );
  }
}
