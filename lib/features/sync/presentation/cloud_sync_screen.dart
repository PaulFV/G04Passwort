import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/di/providers.dart';
import '../../../core/errors/vault_exceptions.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/sync/cloud_sync.dart';
import '../../../widgets/common.dart';
import '../../../widgets/feature_icon.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/neon_button.dart';
import '../../settings/application/settings_controller.dart';

/// Cloud-Synchronisation (design screen 13).
///
/// Zero-knowledge architecture: only the encrypted backup is exchanged.
/// Providers are prepared behind [CloudSyncProvider]; until a provider is
/// implemented, enabling it shows a "coming soon" message.
class CloudSyncScreen extends ConsumerStatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  ConsumerState<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends ConsumerState<CloudSyncScreen> {
  SyncStatus _status = SyncStatus.idle;

  Future<void> _toggle(CloudSyncProvider p, bool enable) async {
    final settings = ref.read(settingsControllerProvider.notifier);
    if (!enable) {
      await p.disconnect();
      await settings.setSyncProvider(p.id, false);
      return;
    }
    try {
      await p.connect();
      await settings.setSyncProvider(p.id, true);
    } on FeatureNotAvailableException catch (e) {
      if (mounted) context.showSnack(e.message, icon: Icons.schedule_rounded);
    }
  }

  Future<void> _syncNow() async {
    final enabled = ref
        .read(settingsControllerProvider)
        .syncProviders
        .entries
        .where((e) => e.value)
        .map((e) => e.key);
    setState(() => _status = SyncStatus.syncing);
    try {
      final count = await ref.read(syncServiceProvider).syncNow(enabled);
      setState(
        () =>
            _status = count == 0 ? SyncStatus.unavailable : SyncStatus.success,
      );
    } on Object {
      setState(() => _status = SyncStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final providers = ref.watch(cloudSyncProvidersProvider);
    final enabled = ref.watch(
      settingsControllerProvider.select((s) => s.syncProviders),
    );

    return G04Scaffold(
      title: tr('Cloud-Synchronisation'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          GlassCard(
            child: Column(
              children: [
                const FeatureIconImage(FeatureIcon.cloud, size: 84),
                const SizedBox(height: 10),
                Text(
                  tr('Automatisch synchronisieren'),
                  style: context.text.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  tr('Ihre Daten sicher in der Cloud – Ende-zu-Ende verschlüsselt. '
      'Der Anbieter sieht nur verschlüsselte Daten.'),
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SectionHeader(tr('Anbieter')),
          for (final p in providers)
            GlassTile(
              icon: p.icon,
              title: p.name,
              subtitle: p.isAvailable ? null : tr('In Vorbereitung'),
              trailing: Switch(
                value: enabled[p.id] ?? false,
                onChanged: (v) => _toggle(p, v),
              ),
            ),
          const SizedBox(height: 16),
          NeonButton(
            label: tr('Jetzt synchronisieren'),
            icon: Icons.sync_rounded,
            loading: _status == SyncStatus.syncing,
            onPressed: _syncNow,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              switch (_status) {
                SyncStatus.success => tr('Synchronisation erfolgreich'),
                SyncStatus.error => tr('Synchronisation fehlgeschlagen'),
                SyncStatus.unavailable => tr('Kein aktiver Anbieter verfügbar'),
                _ => '',
              },
              style: context.text.bodySmall?.copyWith(
                color: _status == SyncStatus.success
                    ? AppColors.success
                    : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
