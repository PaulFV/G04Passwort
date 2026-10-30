import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../models/vault_item.dart';
import '../../../../models/vault_item_type.dart';
import '../../../../widgets/glass_card.dart';
import '../../application/vault_providers.dart';

/// Rounded, glowing avatar for an item: first letter on the category colour
/// (brand logos are intentionally not bundled).
class ItemAvatar extends StatelessWidget {
  const ItemAvatar({super.key, required this.item, this.size = 42});

  final VaultItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = item.category.color;
    final letter = item.title.trim().isEmpty
        ? '?'
        : item.title.trim()[0].toUpperCase();
    final showIcon = item.type != VaultItemType.login;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.15)!,
            Color.lerp(color, Colors.black, 0.45)!,
          ],
        ),
        border: Border.all(
          color: Color.lerp(color, Colors.white, 0.5)!.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: -3,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: showIcon
          ? Icon(item.category.icon, color: Colors.white, size: size * 0.5)
          : Text(
              letter,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.44,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

/// List row of a vault item with quick copy action.
class VaultItemTile extends ConsumerWidget {
  const VaultItemTile({super.key, required this.item, this.trailing});

  final VaultItem item;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final password = item.login?.password ?? '';
    return GlassCard(
      onTap: () => context.push(Routes.item(item.id)),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 14,
      child: Row(
        children: [
          ItemAvatar(item: item),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (item.favorite) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Color(0xFFFFC857),
                      ),
                    ],
                  ],
                ),
                if (item.subtitle.isNotEmpty)
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (password.isNotEmpty)
            IconButton(
              tooltip: 'Passwort kopieren',
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: () async {
                final ok = await ref.read(vaultActionsProvider).copy(password);
                if (!context.mounted) return;
                ok ? context.showSnack('Passwort kopiert') : context.showError(kCopyFailed);
              },
            )
          else
            Icon(
              Icons.chevron_right_rounded,
              color: context.colors.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

/// Search field with "+" button as on the design board.
class VaultSearchBar extends StatelessWidget {
  const VaultSearchBar({
    super.key,
    this.onTap,
    this.onAdd,
    this.onChanged,
    this.autofocus = false,
    this.controller,
  });

  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      borderRadius: 30,
      borderColor: accent.withValues(alpha: 0.5),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(Icons.search_rounded, color: context.colors.onSurfaceVariant),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              readOnly: onTap != null,
              onTap: onTap,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Suche im Tresor …',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 14,
                ),
              ),
            ),
          ),
          if (onAdd != null)
            Padding(
              padding: const EdgeInsets.all(4),
              child: IconButton.filled(
                tooltip: 'Neuer Eintrag',
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shadowColor: accent,
                  elevation: 6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
