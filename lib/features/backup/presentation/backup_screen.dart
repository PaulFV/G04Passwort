import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
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
      if (mounted) context.showError(tr('Fehler: {e}', {'e': e}));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askPassword() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Backup entschlüsseln')),
        content: AppTextField(
          controller: controller,
          label: tr('Master-Passwort des Backups'),
          isSecret: true,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('Abbrechen')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(tr('Wiederherstellen')),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final last = ref.watch(
      settingsControllerProvider.select((s) => s.lastBackupAt),
    );
    return G04Scaffold(
      title: tr('Backup'),
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
                          Text(
                            tr('Letztes Backup'),
                            style: context.text.titleSmall,
                          ),
                          Text(
                            last == null
                                ? tr('Noch kein Backup erstellt')
                                : DateFormat.yMMMd(
                                    L10n.intlLocale,
                                  ).add_Hm().format(last),
                            style: context.text.bodySmall?.copyWith(
                              color: last == null
                                  ? AppColors.warning
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SectionHeader(tr('Sichern')),
              GlassTile(
                icon: Icons.enhanced_encryption_rounded,
                iconColor: AppColors.success,
                title: tr('Verschlüsseltes Backup erstellen'),
                subtitle: tr('.g04vault – nur mit deinem Master-Passwort lesbar'),
                onTap: () => _run(
                  () async => await _c.exportEncryptedBackup()
                      ? tr('Backup gespeichert')
                      : null,
                ),
              ),
              GlassTile(
                icon: Icons.restore_rounded,
                title: tr('Backup wiederherstellen'),
                subtitle:
                    tr('Einträge werden zusammengeführt (neuere Version gewinnt)'),
                onTap: () => _run(() async {
                  final file = await _c.pickFile(['g04vault', 'json']);
                  if (file == null) return null;
                  final pw = await _askPassword();
                  if (pw == null || pw.isEmpty) return null;
                  final r = await _c.restoreBackup(file.bytes, pw);
                  return tr('{imported} Einträge wiederhergestellt, {skipped} übersprungen', {'imported': r.imported, 'skipped': r.skipped});
                }),
              ),
              SectionHeader(tr('Import')),
              GlassTile(
                icon: Icons.file_upload_outlined,
                title: tr('Passwörter importieren (CSV)'),
                subtitle:
                    tr('Bitwarden, 1Password, KeePass, Chrome, Edge, Firefox, LastPass'),
                onTap: () => _run(() async {
                  final file = await _c.pickFile(['csv']);
                  if (file == null) return null;
                  final r = await _c.importCsv(file.bytes);
                  return tr('{imported} Einträge importiert, {skipped} übersprungen', {'imported': r.imported, 'skipped': r.skipped});
                }),
              ),
              SectionHeader(tr('Export')),
              GlassTile(
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.warning,
                title: tr('Unverschlüsselt exportieren (CSV)'),
                subtitle: tr('Nur für den Umzug zu einem anderen Manager'),
                onTap: () => _run(() async {
                  final ok = await context.confirm(
                    title: tr('Unverschlüsselter Export'),
                    message:
                        tr('Die CSV-Datei enthält alle Passwörter im Klartext. '
      'Lösche sie sofort nach dem Import in die Ziel-App.'),
                    confirmLabel: tr('Trotzdem exportieren'),
                    destructive: true,
                  );
                  if (!ok) return null;
                  return await _c.exportCsv() ? tr('CSV exportiert') : null;
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
