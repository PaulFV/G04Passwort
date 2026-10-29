import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/vault_item.dart';
import '../../../models/vault_item_type.dart';
import '../../../widgets/circular_gauge.dart';
import '../../../widgets/common.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/neon_button.dart';
import '../../../widgets/strength_meter.dart';
import '../../generator/application/generator_controller.dart';
import '../application/vault_providers.dart';
import 'widgets/field_row.dart';
import 'widgets/item_widgets.dart';
import 'widgets/payment_card.dart';

/// Eintrag Details (design screen 4).
class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(itemByIdProvider(itemId));
    if (item == null) {
      return const G04Scaffold(
        title: 'Eintrag',
        body: EmptyState(icon: Icons.search_off_rounded, title: 'Eintrag nicht gefunden'),
      );
    }
    final actions = ref.read(vaultActionsProvider);
    final date = DateFormat.yMMMd('de_DE').add_Hm();

    return G04Scaffold(
      title: 'Eintrag',
      actions: [
        IconButton(
          tooltip: item.favorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten',
          icon: Icon(
            item.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
            color: item.favorite ? const Color(0xFFFFC857) : null,
          ),
          onPressed: () => actions.toggleFavorite(item.id),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          GlassCard(
            margin: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                ItemAvatar(item: item, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: context.text.titleLarge),
                      Text(
                        item.login?.primaryUrl ?? item.category.label,
                        style: context.text.bodySmall?.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...switch (item.type) {
            VaultItemType.login => _loginFields(context, ref, item),
            VaultItemType.card => _cardFields(item),
            VaultItemType.document => _documentFields(context, ref, item),
            VaultItemType.note => <Widget>[],
          },
          for (final f in item.customFields)
            FieldRow(label: f.name, value: f.value, secret: f.secret),
          FieldRow(
            label: 'Kategorie',
            value: [
              item.category.label,
              if (item.folderId != null)
                ...ref.watch(foldersProvider).where((f) => f.id == item.folderId).map((f) => 'Ordner: ${f.name}'),
            ].join(' · '),
            copyable: false,
          ),
          if (item.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in item.tags)
                    ActionChip(
                      avatar: const Icon(Icons.sell_outlined, size: 16),
                      label: Text(t),
                      onPressed: () => context.push('${Routes.vault}?tag=${Uri.encodeComponent(t)}'),
                    ),
                ],
              ),
            ),
          FieldRow(
            label: 'Notizen',
            value: item.notes.isEmpty ? 'Keine Notizen' : item.notes,
            copyable: item.notes.isNotEmpty,
            maxLines: 12,
          ),
          if (item.login?.passwordHistory.isNotEmpty ?? false) _PasswordHistory(item: item),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Erstellt ${date.format(item.createdAt)} · Geändert ${date.format(item.updatedAt)}',
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: NeonButton.outline(
                  label: 'Bearbeiten',
                  icon: Icons.edit_rounded,
                  onPressed: () => context.push(Routes.editItem(item.id)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeonButton.outline(
                  label: 'Löschen',
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  onPressed: () => _delete(context, ref, item),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _loginFields(BuildContext context, WidgetRef ref, VaultItem item) {
    final l = item.login!;
    final strength = ref.watch(passwordStrengthProvider(l.password));
    return [
      if (l.username.isNotEmpty) FieldRow(label: 'Benutzername', value: l.username),
      FieldRow(
        label: 'Passwort',
        value: l.password,
        secret: true,
        footer: l.password.isEmpty ? null : StrengthMeter(strength: strength),
      ),
      if (l.hasTotp) _TotpRow(itemId: item.id),
      for (final url in l.urls) FieldRow(label: 'Webseite', value: url),
      if (l.host != null && l.host!.isNotEmpty)
        FieldRow(label: 'Host / IP-Adresse', value: l.host!, monospace: true),
    ];
  }

  List<Widget> _cardFields(VaultItem item) {
    final c = item.card!;
    return [
      Padding(padding: const EdgeInsets.only(bottom: 14), child: PaymentCardView(item: item)),
      FieldRow(label: 'Kartennummer', value: c.number, secret: true, monospace: true),
      FieldRow(label: 'Karteninhaber', value: c.holder),
      FieldRow(label: 'Gültig bis', value: c.expiryLabel, copyable: false),
      if (c.cvv.isNotEmpty) FieldRow(label: 'CVV', value: c.cvv, secret: true),
      if (c.pin.isNotEmpty) FieldRow(label: 'PIN', value: c.pin, secret: true),
    ];
  }

  List<Widget> _documentFields(BuildContext context, WidgetRef ref, VaultItem item) {
    final d = item.document!;
    final date = DateFormat.yMd('de_DE');
    return [
      FieldRow(label: 'Dokumenttyp', value: d.documentType, copyable: false),
      if (d.number.isNotEmpty) FieldRow(label: 'Nummer', value: d.number, secret: true),
      if (d.fullName.isNotEmpty) FieldRow(label: 'Name', value: d.fullName),
      if (d.issuer.isNotEmpty) FieldRow(label: 'Ausstellende Behörde', value: d.issuer),
      if (d.expiryDate != null)
        FieldRow(label: 'Gültig bis', value: date.format(d.expiryDate!), copyable: false),
      for (final a in d.attachments)
        GlassTile(
          icon: Icons.picture_as_pdf_rounded,
          iconColor: AppColors.danger,
          title: a.name,
          subtitle: '${a.extension} · ${formatBytes(a.size)} · verschlüsselt',
          trailing: const Icon(Icons.download_rounded),
          onTap: () => _exportAttachment(context, ref, a),
        ),
    ];
  }

  Future<void> _exportAttachment(BuildContext context, WidgetRef ref, AttachmentRef a) async {
    try {
      final bytes = await ref.read(vaultActionsProvider).readAttachment(a.id);
      await FilePicker.saveFile(fileName: a.name, bytes: bytes, mimeType: a.mimeType);
    } on Object catch (e) {
      if (context.mounted) context.showError('Datei konnte nicht gespeichert werden: $e');
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, VaultItem item) async {
    final ok = await context.confirm(
      title: 'Eintrag löschen?',
      message: '„${item.title}“ wird endgültig gelöscht.',
      confirmLabel: 'Löschen',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(vaultActionsProvider).delete(item.id);
    if (context.mounted) {
      context.pop();
      context.showSnack('Eintrag gelöscht');
    }
  }
}

/// Live 2FA code with countdown ring.
class _TotpRow extends ConsumerWidget {
  const _TotpRow({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(totpCodeProvider(itemId)).value;
    if (code == null) {
      return const FieldRow(label: '2FA-Code', value: 'Ungültiger TOTP-Schlüssel', copyable: false);
    }
    return FieldRow(
      label: '2FA-Code (TOTP)',
      value: code.code,
      monospace: true,
      footer: Row(
        children: [
          CircularGauge(
            value: code.progress,
            color: code.remaining <= 5 ? AppColors.danger : AppColors.cyan,
            size: 22,
            strokeWidth: 3,
            animate: false,
          ),
          const SizedBox(width: 8),
          Text('${code.remaining} s', style: context.text.bodySmall),
        ],
      ),
    );
  }
}

class _PasswordHistory extends StatelessWidget {
  const _PasswordHistory({required this.item});

  final VaultItem item;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMd('de_DE').add_Hm();
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      borderRadius: 14,
      child: ExpansionTile(
        shape: const Border(),
        leading: const Icon(Icons.history_rounded),
        title: Text('Passwort-Verlauf (${item.login!.passwordHistory.length})'),
        children: [
          for (final h in item.login!.passwordHistory)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: FieldRow(label: 'Bis ${date.format(h.changedAt)}', value: h.password, secret: true),
            ),
        ],
      ),
    );
  }
}

/// Human readable file size.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}
