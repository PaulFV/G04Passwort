import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/responsive.dart';
import '../../../widgets/common.dart';
import '../../../widgets/g04_scaffold.dart';
import '../application/vault_providers.dart';
import 'widgets/item_widgets.dart';

/// Passwort-Verlauf: recently changed entries. The per-item password
/// history is shown in the item detail view.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recentItemsProvider);
    final fmt = DateFormat.yMMMd(L10n.intlLocale).add_Hm();
    return G04Scaffold(
      title: tr('Passwort-Verlauf'),
      wide: true,
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.history_rounded,
              title: tr('Noch keine Änderungen'),
            )
          : ResponsiveListView.builder(
                    gridItemExtent: 78,
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final changes = item.login?.passwordHistory.length ?? 0;
                return VaultItemTile(
                  item: item,
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        fmt.format(item.updatedAt),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      if (changes > 0)
                        Text(
                          tr('{changes} frühere', {'changes': changes}),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
