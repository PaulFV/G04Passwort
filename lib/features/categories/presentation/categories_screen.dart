import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/extensions/context_x.dart';
import '../../../models/item_category.dart';
import '../../../widgets/common.dart';
import '../../../widgets/feature_icon.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../vault/application/vault_providers.dart';

/// Kategorien (design screen 8) plus folders (Ordner) and tags.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  String _route(ItemCategory c) => switch (c) {
    ItemCategory.card => Routes.cards,
    ItemCategory.document => Routes.documents,
    ItemCategory.note => Routes.notes,
    _ => '${Routes.vault}?category=${c.name}',
  };

  Future<void> _folderDialog(
    BuildContext context,
    WidgetRef ref, {
    String? id,
    String? name,
  }) async {
    final controller = TextEditingController(text: name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'Neuer Ordner' : 'Ordner umbenennen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.trim().isEmpty) return;
    final actions = ref.read(vaultActionsProvider);
    if (id == null) {
      await actions.createFolder(result);
    } else {
      await actions.renameFolder(id, result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(categoryCountsProvider);
    final folders = ref.watch(foldersProvider);
    final items = ref.watch(itemsProvider);
    final tags = ref.watch(allTagsProvider);

    return G04Scaffold(
      title: 'Kategorien',
      actions: [
        IconButton(
          tooltip: 'Suche',
          icon: const Icon(Icons.search_rounded),
          onPressed: () => context.push(Routes.search),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          for (final (i, c) in ItemCategory.values.indexed)
            AnimatedEntrance(
              index: i,
              child: GlassTile(
                icon: c.icon,
                iconColor: c.color,
                title: c.label,
                value: '${counts[c]}',
                onTap: () => context.push(_route(c)),
              ),
            ),
          SectionHeader(
            'Ordner',
            actionLabel: 'Neu',
            onAction: () => _folderDialog(context, ref),
          ),
          if (folders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Noch keine Ordner – erstelle z. B. „Arbeit“, „Kunden“ oder „Anlage Halle 2“.',
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          for (final f in folders)
            GlassTile(
              leading: const FeatureIconImage(FeatureIcon.folder, size: 38),
              title: f.name,
              value: '${items.where((i) => i.folderId == f.id).length}',
              onTap: () => context.push('${Routes.vault}?folder=${f.id}'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'rename') {
                    await _folderDialog(context, ref, id: f.id, name: f.name);
                  } else {
                    final ok = await context.confirm(
                      title: 'Ordner löschen?',
                      message:
                          'Die Einträge bleiben erhalten und werden keinem Ordner mehr zugeordnet.',
                      destructive: true,
                      confirmLabel: 'Löschen',
                    );
                    if (ok)
                      await ref.read(vaultActionsProvider).deleteFolder(f.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Umbenennen')),
                  PopupMenuItem(value: 'delete', child: Text('Löschen')),
                ],
              ),
            ),
          if (tags.isNotEmpty) ...[
            const SectionHeader('Tags'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in tags)
                  ActionChip(
                    avatar: const Icon(Icons.sell_outlined, size: 16),
                    label: Text(t),
                    onPressed: () => context.push(
                      '${Routes.vault}?tag=${Uri.encodeComponent(t)}',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
