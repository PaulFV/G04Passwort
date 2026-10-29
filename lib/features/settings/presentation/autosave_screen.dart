import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/g04_logo.dart';
import '../../../widgets/glass_card.dart';
import '../application/settings_controller.dart';

/// Auto-Save (design screen 15): "Logins automatisch speichern".
///
/// The preference is stored now; the system integration (Android Autofill
/// Service, iOS Credential Provider Extension, browser extension) is the
/// next roadmap step and plugs into this setting.
class AutoSaveScreen extends ConsumerWidget {
  const AutoSaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(settingsControllerProvider.select((s) => s.autoSaveEnabled));
    return G04Scaffold(
      title: 'Auto-Save',
      body: ListView(
        children: [
          const SizedBox(height: 12),
          Center(child: Image.asset(kLock3dAsset, height: 180)),
          const SizedBox(height: 16),
          Text('Logins automatisch speichern', textAlign: TextAlign.center, style: context.text.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Bei der Anmeldung auf Websites und in Apps werden neue Zugangsdaten '
            'erkannt und sicher in deinem Tresor gespeichert.',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 22),
          GlassTile(
            icon: Icons.save_as_rounded,
            title: 'Auto-Save aktiv',
            trailing: Switch(
              value: enabled,
              onChanged: ref.read(settingsControllerProvider.notifier).setAutoSave,
            ),
          ),
          const SizedBox(height: 8),
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.cyan),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'System-Autofill (Android Autofill-Dienst, iOS Passwort-Autofill) ist in Vorbereitung. '
                    'Bis dahin kannst du Zugangsdaten per Kopieren übernehmen – die Zwischenablage wird automatisch geleert.',
                    style: context.text.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
