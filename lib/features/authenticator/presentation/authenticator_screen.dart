import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/responsive.dart';
import '../../../app/routes.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/vault_item.dart';
import '../../../widgets/circular_gauge.dart';
import '../../../widgets/common.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/neon_button.dart';
import '../../vault/application/vault_providers.dart';
import '../../vault/presentation/widgets/item_widgets.dart';

/// 2FA Authenticator (design screen 6): live TOTP codes with countdown.
class AuthenticatorScreen extends ConsumerWidget {
  const AuthenticatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(totpItemsProvider);
    return G04Scaffold(
      title: '2FA Authenticator',
      wide: true,
      body: Column(
        children: [
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    icon: Icons.qr_code_2_rounded,
                    title: 'Keine 2FA-Codes',
                    message:
                        'Füge bei einem Login den TOTP-Schlüssel (Base32 oder otpauth://-Link) hinzu.',
                  )
                : ResponsiveListView.builder(
                    gridItemExtent: 124,
                    itemCount: items.length,
                    itemBuilder: (_, i) => AnimatedEntrance(
                      index: i,
                      child: _TotpCard(item: items[i]),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: NeonButton(
              label: 'Neu hinzufügen',
              icon: Icons.add_rounded,
              onPressed: () => context.push(Routes.newItem),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotpCard extends ConsumerWidget {
  const _TotpCard({required this.item});

  final VaultItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(totpCodeProvider(item.id)).value;
    final warn = (code?.remaining ?? 30) <= 5;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: code == null
          ? null
          : () async {
              final ok = await ref.read(vaultActionsProvider).copy(code.code);
              if (!context.mounted) return;
              ok ? context.showSnack('Code kopiert') : context.showError(kCopyFailed);
            },
      child: Row(
        children: [
          ItemAvatar(item: item, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.login!.username.isNotEmpty)
                  Text(
                    item.login!.username,
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                Text(
                  code?.formatted ?? '––– –––',
                  style: context.text.headlineSmall?.copyWith(
                    color: warn ? AppColors.danger : AppColors.neonBlueLight,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: warn ? AppColors.danger : AppColors.neonBlue,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          CircularGauge(
            value: code?.progress ?? 0,
            color: warn ? AppColors.danger : AppColors.cyan,
            size: 44,
            strokeWidth: 4,
            animate: false,
            child: Text(
              '${code?.remaining ?? ''}',
              style: context.text.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}
