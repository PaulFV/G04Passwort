import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/responsive.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_constants.dart';
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
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            RadioGroup<int>(
              groupValue: current,
              onChanged: (v) => Navigator.pop(context, v),
              child: Column(
                children: [
                  for (final o in options)
                    RadioListTile<int>(
                      value: o,
                      title: Text(AppSettings.durationLabel(o)),
                    ),
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
      title: tr('Einstellungen'),
      wide: true,
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
                        s.displayName.isEmpty ? tr('Mein Profil') : s.displayName,
                        style: context.text.titleMedium,
                      ),
                      if (s.email.isNotEmpty)
                        Text(
                          s.email,
                          style: context.text.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 4),
                      StatusBadge(
                        tr('Premium'),
                        color: AppColors.neonBlueLight,
                      ),
                    ],
                  ),
                ),
                StatusBadge(tr('Aktiv')),
              ],
            ),
          ),
          ResponsiveGrid(
            minItemWidth: 380,
            children: [
          GlassTile(
            leading: const FeatureIconImage(FeatureIcon.security, size: 38),
            title: tr('Sicherheit'),
            subtitle: tr('Master-Passwort ändern'),
            onTap: () => context.push(Routes.changeMasterPassword),
          ),
          GlassTile(
            leading: const FeatureIconImage(FeatureIcon.cloud, size: 38),
            title: tr('Cloud-Synchronisation'),
            value: syncActive ? tr('Aktiv') : tr('Aus'),
            onTap: () => context.push(Routes.sync),
          ),
          GlassTile(
            leading: const FeatureIconImage(FeatureIcon.settings, size: 38),
            title: tr('Design'),
            value: s.darkMode ? tr('Dunkel') : tr('Hell'),
            onTap: () => context.push(Routes.design),
          ),
          GlassTile(
            icon: Icons.language_rounded,
            title: tr('Sprache'),
            value: _languageLabel(s.languageCode),
            onTap: () => _pickLanguage(context, ref, s.languageCode),
          ),
          GlassTile(
            icon: Icons.timer_outlined,
            title: tr('Auto-Lock'),
            value: AppSettings.durationLabel(s.autoLockSeconds),
            onTap: () => _pickDuration(
              context,
              title: tr('Automatisch sperren nach'),
              options: AppSettings.autoLockOptions,
              current: s.autoLockSeconds,
              onSelected: settings.setAutoLock,
            ),
          ),
          GlassTile(
            icon: Icons.phonelink_lock_rounded,
            title: tr('Beim Verlassen der App sperren'),
            trailing: Switch(
              value: s.lockOnBackground,
              onChanged: settings.setLockOnBackground,
            ),
          ),
          GlassTile(
            leading: const FeatureIconImage(FeatureIcon.biometric, size: 38),
            title: kIsWeb ? tr('App-Sperre (Face ID / Passkey)') : tr('App-Sperre (Biometrie)'),
            subtitle: auth.biometricHardware
                ? (kIsWeb
                      ? tr('Mit Face ID / Fingerabdruck entsperren')
                      : tr('Fingerabdruck / Face ID'))
                : (kIsWeb
                      ? tr('Dieser Browser unterstützt keine Passkeys')
                      : tr('Keine Biometrie auf diesem Gerät')),
            trailing: Switch(
              value: s.biometricEnabled,
              onChanged: !auth.biometricHardware
                  ? null
                  : (v) => _toggleBiometric(context, ref, v),
            ),
          ),
          GlassTile(
            icon: Icons.screenshot_monitor_rounded,
            title: tr('Screenshots blockieren'),
            subtitle: tr('Verbirgt Inhalte in Screenshots und App-Übersicht'),
            trailing: Switch(
              value: s.screenshotProtection,
              onChanged: settings.setScreenshotProtection,
            ),
          ),
          GlassTile(
            icon: Icons.content_paste_off_rounded,
            title: tr('Zwischenablage leeren'),
            value: AppSettings.durationLabel(s.clipboardClearSeconds),
            onTap: () => _pickDuration(
              context,
              title: tr('Kopierte Passwörter löschen nach'),
              options: AppSettings.clipboardOptions,
              current: s.clipboardClearSeconds,
              onSelected: settings.setClipboardClear,
            ),
          ),
          GlassTile(
            leading: const FeatureIconImage(FeatureIcon.passwords, size: 38),
            title: tr('Auto-Save'),
            value: s.autoSaveEnabled ? tr('Aktiv') : tr('Aus'),
            onTap: () => context.push(Routes.autoSave),
          ),
          GlassTile(
            leading: const FeatureIconImage(FeatureIcon.importExport, size: 38),
            title: tr('Backup, Import & Export'),
            onTap: () => context.push(Routes.backup),
          ),
          GlassTile(
            icon: Icons.info_outline_rounded,
            title: tr('Über G04Passwort'),
            onTap: () => context.push(Routes.about),
          ),
          GlassTile(
            icon: Icons.copyright_rounded,
            title: tr('Copyright'),
            subtitle: AppConstants.rightsReserved,
            onTap: () => context.push(Routes.copyright),
          ),
          GlassTile(
            icon: Icons.privacy_tip_outlined,
            title: tr('Datenschutz'),
            subtitle: tr('Kein Konto, kein Tracking – deine Daten bleiben verschlüsselt auf dem Gerät.'),
            onTap: () => context.push(Routes.privacy),
          ),
          GlassTile(
            icon: Icons.lock_rounded,
            title: tr('Tresor jetzt sperren'),
            onTap: () => ref.read(authControllerProvider.notifier).lock(manual: true),
          ),
          GlassTile(
            icon: Icons.delete_forever_rounded,
            iconColor: AppColors.danger,
            title: tr('Tresor zurücksetzen'),
            subtitle: tr('Löscht alle Daten auf diesem Gerät'),
            onTap: () async {
              final ok = await context.confirm(
                title: tr('Tresor zurücksetzen?'),
                message:
                    tr('Alle Einträge, Dokumente und Schlüssel werden unwiderruflich gelöscht. '
      'Erstelle vorher ein Backup!'),
                confirmLabel: tr('Alles löschen'),
                destructive: true,
              );
              if (ok)
                await ref.read(authControllerProvider.notifier).resetVault();
            },
          ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Switches biometric unlock on/off. Must start the prompt synchronously –
/// the web app's passkey dialog needs the user's tap.
Future<void> _toggleBiometric(
  BuildContext context,
  WidgetRef ref,
  bool enabled,
) async {
  final auth = ref.read(authControllerProvider.notifier);
  var result = await auth.setBiometricEnabled(enabled);
  if (result.needsConfirmation) {
    if (!context.mounted) return auth.cancelBiometricSetup();
    result =
        await showDialog<BiometricSetup>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.face_retouching_natural_rounded,
              size: 40,
              color: AppColors.neonBlueLight,
            ),
            title: Text(tr('Fast fertig')),
            content: Text(
              tr('Der Passkey wurde angelegt. Bestätige jetzt einmal mit '
      'Face ID / Fingerabdruck, um das Entsperren zu aktivieren.'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  auth.cancelBiometricSetup();
                  Navigator.pop(dialogContext);
                },
                child: Text(tr('Abbrechen')),
              ),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: () async {
                  final r = await auth.confirmBiometricSetup();
                  if (dialogContext.mounted) Navigator.pop(dialogContext, r);
                },
                child: Text(tr('Bestätigen')),
              ),
            ],
          ),
        ) ??
        const BiometricSetup.failed(null);
  }
  if (!context.mounted) return;
  if (result.ok) {
    if (enabled) {
      context.showSnack(
        kIsWeb ? tr('Face ID / Passkey aktiviert') : tr('Biometrie aktiviert'),
        icon: Icons.verified_user_rounded,
      );
    }
  } else if (result.error != null) {
    context.showError(result.error!);
  }
}

String _languageLabel(String code) => switch (code) {
  'de' => 'Deutsch',
  'en' => 'English',
  _ => tr('Systemsprache'),
};

/// Lets the user choose System / Deutsch / English.
Future<void> _pickLanguage(
  BuildContext context,
  WidgetRef ref,
  String current,
) async {
  final picked = await showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              tr('Sprache'),
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
          ),
          for (final code in [L10n.system, 'de', 'en'])
            ListTile(
              leading: Icon(
                code == current
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: code == current ? AppColors.neonBlueLight : null,
              ),
              title: Text(_languageLabel(code)),
              subtitle: code == L10n.system
                  ? Text(tr('Wie auf deinem Gerät eingestellt'))
                  : null,
              onTap: () => Navigator.pop(sheetContext, code),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (picked != null && picked != current) {
    await ref.read(settingsControllerProvider.notifier).setLanguage(picked);
  }
}
