import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/responsive.dart';
import '../../../app/routes.dart';
import '../../../models/item_category.dart';
import '../../../models/vault_item.dart';
import '../../../widgets/common.dart';
import '../../../widgets/g04_scaffold.dart';
import '../application/vault_providers.dart';
import 'widgets/item_widgets.dart';

/// Sort order of the password list.
enum _Sort { name, recent }

/// Passwortliste – all items, optionally filtered by category, favourites,
/// folder or tag.
class PasswordListScreen extends ConsumerStatefulWidget {
  const PasswordListScreen({
    super.key,
    this.category,
    this.favoritesOnly = false,
    this.folderId,
    this.tag,
  });

  final ItemCategory? category;
  final bool favoritesOnly;
  final String? folderId;
  final String? tag;

  @override
  ConsumerState<PasswordListScreen> createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends ConsumerState<PasswordListScreen> {
  _Sort _sort = _Sort.name;

  String get _title {
    if (widget.favoritesOnly) return tr('Favoriten');
    if (widget.category != null) return widget.category!.label;
    if (widget.tag != null) return '#${widget.tag}';
    if (widget.folderId != null) {
      for (final f in ref.read(foldersProvider)) {
        if (f.id == widget.folderId) return f.name;
      }
    }
    return tr('Alle Einträge');
  }

  List<VaultItem> _filter(List<VaultItem> items) {
    var list = items.where((i) {
      if (widget.favoritesOnly && !i.favorite) return false;
      if (widget.category != null && i.category != widget.category)
        return false;
      if (widget.folderId != null && i.folderId != widget.folderId)
        return false;
      if (widget.tag != null && !i.tags.contains(widget.tag)) return false;
      return true;
    }).toList();
    if (_sort == _Sort.recent) {
      list = list..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filter(ref.watch(itemsProvider));
    final newRoute = widget.category == null
        ? Routes.newItem
        : '${Routes.newItem}?type=${widget.category!.defaultType.name}&category=${widget.category!.name}';
    return G04Scaffold(
      title: _title,
      wide: true,
      actions: [
        PopupMenuButton<_Sort>(
          tooltip: tr('Sortieren'),
          icon: const Icon(Icons.sort_rounded),
          initialValue: _sort,
          onSelected: (s) => setState(() => _sort = s),
          itemBuilder: (_) => [
            PopupMenuItem(value: _Sort.name, child: Text(tr('Name (A–Z)'))),
            PopupMenuItem(value: _Sort.recent, child: Text(tr('Zuletzt geändert'))),
          ],
        ),
        IconButton(
          tooltip: tr('Suche'),
          icon: const Icon(Icons.search_rounded),
          onPressed: () => context.push(Routes.search),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        tooltip: tr('Neuer Eintrag'),
        onPressed: () => context.push(newRoute),
        child: const Icon(Icons.add_rounded),
      ),
      body: items.isEmpty
          ? EmptyState(
              icon: widget.category?.icon ?? Icons.key_rounded,
              title: tr('Noch keine Einträge'),
              message: tr('Tippe auf +, um einen neuen Eintrag anzulegen.'),
            )
          : ResponsiveListView.builder(
                    gridItemExtent: 78,
              padding: const EdgeInsets.only(top: 4, bottom: 96),
              itemCount: items.length,
              itemBuilder: (context, i) => AnimatedEntrance(
                index: i,
                child: VaultItemTile(item: items[i]),
              ),
            ),
    );
  }
}
