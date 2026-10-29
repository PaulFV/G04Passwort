import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_x.dart';
import '../../../widgets/common.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../vault/application/vault_providers.dart';
import '../../vault/presentation/widgets/item_widgets.dart';

/// Suche – instant full-text search over titles, usernames, URLs, hosts,
/// tags, notes and categories (in memory, after decryption).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: ref.read(searchQueryProvider));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(String q) => ref.read(searchQueryProvider.notifier).set(q);

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final tags = ref.watch(allTagsProvider);

    return G04Scaffold(
      title: 'Suche',
      body: Column(
        children: [
          VaultSearchBar(controller: _controller, autofocus: true, onChanged: _set),
          if (tags.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(top: 8),
                children: [
                  for (final t in tags)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text('#$t'),
                        onPressed: () {
                          _controller.text = t;
                          _set(t);
                        },
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                query.isEmpty ? '${results.length} Einträge' : '${results.length} Treffer',
                style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const EmptyState(icon: Icons.search_off_rounded, title: 'Keine Treffer')
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: results.length,
                    itemBuilder: (_, i) => VaultItemTile(item: results[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
