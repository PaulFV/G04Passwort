import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/app_settings.dart';
import '../../../widgets/common.dart';
import '../../../widgets/feature_icon.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/glass_card.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/presentation/profile_screen.dart' show ProfileAvatar;
import '../application/settings_controller.dart';

/// Einstellungen (design screen 12).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _pickDuration(
    BuildContext context, {
    required String title,
    required List<int> options,
    required int current,
    required ValueChanged<int> onSelected,
  }) async {
    final value = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            RadioGroup<int>(
              groupValue: current,
              onChanged: (v) => Navigator.pop(context, v),
              child: Column(
                children: [
                  for (final o in options)
                    RadioListTile<int>(value: o, title: Text(AppSettings.durationLabel(o))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (value != null) onSelected(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider);
    final settings = ref.read(settingsControllerProvider.notifier);
    final auth = ref.watch(authControllerProvider);
    final syncActive = s.syncProviders.values.any((v) => v);

    return G04Scaffold(
      title: 'Einstellungen',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          GlassCard(
            onTap: () => context.push(Routes.profile),
            margin: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                ProfileAvatar(name: s.displayName, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.displayName.isEmpty ? 'Mein Profil' : s.displayName,
                        style: context.text.titleMedium,
                      ),
                      if (s.email.isNotEmpty)
                        Text(s.email, style: context.text.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      const StatusBadge('Premium', color: AppColors.neonBlueLight),
                    ],
                  ),
                ),
                const StatusBadge('Aktiv'),
              ],
            ),
          ),
          GlassTile(
            leading: const FeatureIconImage(FeatureIcon.security, size: 38),
            title: 'Sicherheit',
            subtitle: 'Master-Passwort ändern',
            onTap: () => context.push(Routes.changeMasterPassword),
          ),
          GlassTile(
            leading: const FeatureIconImage(FeatureIcon.cloud, size: 38),
            title: 'Cloud-Synchronisation',
            value: syncActive ? 'Aktiv' : 'Aus',
            onTap: () => context.push(Routes.sync),
          ),
          GlassTile(
            leading: const FeatureIconImage(FeatureIcon.settings, size: 38),
            title: 'Design',
            value: s.darkMode ? 'Dunkel' : 'Hell',
            onTap: () => context.push(Routes.design),
          ),
          const GlassTile(
            icon: Icons.language_rounded,
            title: 'Sprache',
            value: 'Deutsch',
            subtitle: 'Weitere Sprachen in Vorbereitung',
          ),
          GlassTile(
            icon: Icons.timer_outlined,
            title: 'Auto-Lock',
            value: AppSettings.durationLabel(s.autoLockSeconds),
            onTap: () => _pickDuration(
              context,
              title: 'Automatisch sperren nach',
              options: AppSettings.autoLockOptions,
              current: s.autoLockSeconds,
              onSelected: settings.setAutoLock,
            ),
          ),
          GlassTile(
            icon: Icons.phonelink_lock_rounded,
            title: 'Beim Verlassen der App sperren',
            trailing: Switch(value: s.lockOnBackground, onChanged: settings.setLockOnBackground),
          ),
          GlassTile(
            leading: const FeatureIconImage(FeatureIcon.biometric, size: 38),
            title: 'App-Sperre (Biometrie)',
            subtitle: auth.biometricHardware
                ? 'Fingerabdruck / Face ID'
                : (kIsWeb ? 'Im Browser nicht verfügbar' : 'Keine Biometrie auf diesem Gerät'),
            trailing: Switch(
              value: s.biometricEnabled,
              onChanged: !auth.biometricHardware
                  ? null
                  : (v) async {
                      final ok = await ref.read(authControllerProvider.notifier).setBiometricEnabled(v);
                      if (!ok && context.mounted) context.showError('Biometrische Bestätigung fehlgeschlagen');
                    },
            ),
          ),
          GlassTile(
            icon: Icons.screenshot_monitor_rounded,
            title: 'Screenshots blockieren',
            subtitle: 'Verbirgt Inhalte in Screenshots und App-Übersicht',
            trailing: Switch(value: s.screenshotProtection, onChanged: settings.setScreenshotProtection),
          ),
          GlassTile(
            icon: Icons.content_paste_off_rounded,
            title: 'Zwischenablage leeren',
            value: AppSettings.durationLabel(s.clipboardClearSeconds),
            onTap: () => _pickDuration(
              context,
              title: 'Kopierte Passwörter löschen nach',
              options: AppSettings.clipboardOptions,
              current: s.clipboardClearSeconds,
              onSelected: settings.setClipboardClear,
            ),
          ),
          GlassTile(
            leading: const FeatureIconImage(FeatureIcon.passwords, size: 38),
            title: 'Auto-Save',
            value: s.autoSaveEnabled ? 'Aktiv' : 'Aus',
            onTap: () => context.push(Routes.autoSave),
          ),
          GlassTile(
            leading: const FeatureIconImage(FeatureIcon.importExport, size: 38),
            title: 'Backup, Import & Export',
            onTap: () => context.push(Routes.backup),
          ),
          GlassTile(
            icon: Icons.info_outline_rounded,
            title: 'Über G04Passwort',
            onTap: () => context.push(Routes.about),
          ),
          const SizedBox(height: 10),
          GlassTile(
            icon: Icons.lock_rounded,
            title: 'Tresor jetzt sperren',
            onTap: () => ref.read(authControllerProvider.notifier).lock(),
          ),
          GlassTile(
            icon: Icons.delete_forever_rounded,
            iconColor: AppColors.danger,
            title: 'Tresor zurücksetzen',
            subtitle: 'Löscht alle Daten auf diesem Gerät',
            onTap: () async {
              final ok = await context.confirm(
                title: 'Tresor zurücksetzen?',
                message: 'Alle Einträge, Dokumente und Schlüssel werden unwiderruflich gelöscht. '
                    'Erstelle vorher ein Backup!',
                confirmLabel: 'Alles löschen',
                destructive: true,
              );
              if (ok) await ref.read(authControllerProvider.notifier).resetVault();
            },
          ),
        ],
      ),
    );
  }
}
