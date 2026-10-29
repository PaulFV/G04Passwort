import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/vault_exceptions.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/common.dart';
import '../../../widgets/feature_icon.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/glass_card.dart';
import '../../settings/application/settings_controller.dart';
import '../application/backup_controller.dart';

/// Backup, Import & Export.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  BackupController get _c => ref.read(backupControllerProvider);

  Future<void> _run(Future<String?> Function() action) async {
    setState(() => _busy = true);
    try {
      final message = await action();
      if (message != null && mounted) context.showSnack(message);
    } on VaultException catch (e) {
      if (mounted) context.showError(e.message);
    } on Object catch (e) {
      if (mounted) context.showError('Fehler: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askPassword() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup entschlüsseln'),
        content: AppTextField(
          controller: controller,
          label: 'Master-Passwort des Backups',
          isSecret: true,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Wiederherstellen'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final last = ref.watch(settingsControllerProvider.select((s) => s.lastBackupAt));
    return G04Scaffold(
      title: 'Backup',
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              GlassCard(
                child: Row(
                  children: [
                    const FeatureIconImage(FeatureIcon.importExport, size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Letztes Backup', style: context.text.titleSmall),
                          Text(
                            last == null ? 'Noch kein Backup erstellt' : DateFormat.yMMMd('de_DE').add_Hm().format(last),
                            style: context.text.bodySmall?.copyWith(
                              color: last == null ? AppColors.warning : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SectionHeader('Sichern'),
              GlassTile(
                icon: Icons.enhanced_encryption_rounded,
                iconColor: AppColors.success,
                title: 'Verschlüsseltes Backup erstellen',
                subtitle: '.g04vault – nur mit deinem Master-Passwort lesbar',
                onTap: () => _run(() async =>
                    await _c.exportEncryptedBackup() ? 'Backup gespeichert' : null),
              ),
              GlassTile(
                icon: Icons.restore_rounded,
                title: 'Backup wiederherstellen',
                subtitle: 'Einträge werden zusammengeführt (neuere Version gewinnt)',
                onTap: () => _run(() async {
                  final file = await _c.pickFile(['g04vault', 'json']);
                  if (file == null) return null;
                  final pw = await _askPassword();
                  if (pw == null || pw.isEmpty) return null;
                  final r = await _c.restoreBackup(file.bytes, pw);
                  return '${r.imported} Einträge wiederhergestellt, ${r.skipped} übersprungen';
                }),
              ),
              const SectionHeader('Import'),
              GlassTile(
                icon: Icons.file_upload_outlined,
                title: 'Passwörter importieren (CSV)',
                subtitle: 'Bitwarden, 1Password, KeePass, Chrome, Edge, Firefox, LastPass',
                onTap: () => _run(() async {
                  final file = await _c.pickFile(['csv']);
                  if (file == null) return null;
                  final r = await _c.importCsv(file.bytes);
                  return '${r.imported} Einträge importiert, ${r.skipped} übersprungen';
                }),
              ),
              const SectionHeader('Export'),
              GlassTile(
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.warning,
                title: 'Unverschlüsselt exportieren (CSV)',
                subtitle: 'Nur für den Umzug zu einem anderen Manager',
                onTap: () => _run(() async {
                  final ok = await context.confirm(
                    title: 'Unverschlüsselter Export',
                    message: 'Die CSV-Datei enthält alle Passwörter im Klartext. '
                        'Lösche sie sofort nach dem Import in die Ziel-App.',
                    confirmLabel: 'Trotzdem exportieren',
                    destructive: true,
                  );
                  if (!ok) return null;
                  return await _c.exportCsv() ? 'CSV exportiert' : null;
                }),
              ),
            ],
          ),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x88000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
