import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/di/providers.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/item_category.dart';
import '../../../models/vault_item.dart';
import '../../../models/vault_item_type.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/common.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/neon_button.dart';
import '../../../widgets/strength_meter.dart';
import '../../../widgets/success_dialog.dart';
import '../../generator/application/generator_controller.dart';
import '../application/vault_providers.dart';
import 'item_detail_screen.dart' show formatBytes;

/// Neuer Eintrag / Bearbeiten (design screen 19).
///
/// For a new item the type is chosen with the icon tabs at the top. The
/// widget only maps form fields to a [VaultItem]; persistence and business
/// rules (history, timestamps) live in [VaultActions] / the repository.
class ItemEditorScreen extends ConsumerStatefulWidget {
  const ItemEditorScreen({
    super.key,
    this.itemId,
    this.type = VaultItemType.login,
    this.category,
  });

  final String? itemId;
  final VaultItemType type;
  final ItemCategory? category;

  @override
  ConsumerState<ItemEditorScreen> createState() => _ItemEditorScreenState();
}

class _ItemEditorScreenState extends ConsumerState<ItemEditorScreen> {
  final _form = GlobalKey<FormState>();
  late VaultItem _item;
  bool _saving = false;

  // Common
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _tagInput = TextEditingController();
  // Login
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _url = TextEditingController();
  final _totp = TextEditingController();
  final _host = TextEditingController();
  // Card
  final _holder = TextEditingController();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _pin = TextEditingController();
  // Document
  final _docNumber = TextEditingController();
  final _docName = TextEditingController();
  final _docIssuer = TextEditingController();
  String _docType = DocumentData.types.last;
  DateTime? _docExpiry;
  List<AttachmentRef> _attachments = [];

  late ItemCategory _category;
  String? _folderId;
  bool _favorite = false;
  List<String> _tags = [];
  List<CustomField> _fields = [];

  bool get _isNew => widget.itemId == null;

  @override
  void initState() {
    super.initState();
    final existing = widget.itemId == null
        ? null
        : ref.read(itemByIdProvider(widget.itemId!));
    _load(existing ?? ref.read(vaultActionsProvider).newItem(widget.type));
    if (existing == null && widget.category != null)
      _category = widget.category!;
    _password.addListener(() => setState(() {}));
  }

  void _load(VaultItem item) {
    _item = item;
    _title.text = item.title;
    _notes.text = item.notes;
    _category = item.category;
    _folderId = item.folderId;
    _favorite = item.favorite;
    _tags = [...item.tags];
    _fields = [...item.customFields];
    final l = item.login;
    _username.text = l?.username ?? '';
    _password.text = l?.password ?? '';
    _url.text = l?.urls.join(', ') ?? '';
    _totp.text = l?.totpSecret ?? '';
    _host.text = l?.host ?? '';
    final c = item.card;
    _holder.text = c?.holder ?? '';
    _number.text = c?.number ?? '';
    _expiry.text = c?.expiryLabel ?? '';
    _cvv.text = c?.cvv ?? '';
    _pin.text = c?.pin ?? '';
    final d = item.document;
    _docNumber.text = d?.number ?? '';
    _docName.text = d?.fullName ?? '';
    _docIssuer.text = d?.issuer ?? '';
    _docType = d?.documentType ?? DocumentData.types.last;
    _docExpiry = d?.expiryDate;
    _attachments = [...?d?.attachments];
  }

  void _switchType(VaultItemType type) {
    if (!_isNew || type == _item.type) return;
    setState(() {
      final fresh = ref.read(vaultActionsProvider).newItem(type);
      _item = fresh;
      _category = fresh.category;
    });
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _notes,
      _tagInput,
      _username,
      _password,
      _url,
      _totp,
      _host,
      _holder,
      _number,
      _expiry,
      _cvv,
      _pin,
      _docNumber,
      _docName,
      _docIssuer,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  VaultItem _build() {
    final exp = RegExp(
      r'^(\d{1,2})\s*/\s*(\d{2,4})$',
    ).firstMatch(_expiry.text.trim());
    return _item.copyWith(
      title: _title.text,
      notes: _notes.text,
      category: _category,
      folderId: _folderId,
      clearFolder: _folderId == null,
      favorite: _favorite,
      tags: _tags,
      customFields: _fields.where((f) => f.name.trim().isNotEmpty).toList(),
      login: _item.type == VaultItemType.login
          ? (_item.login ?? const LoginData()).copyWith(
              username: _username.text.trim(),
              password: _password.text,
              urls: _url.text
                  .split(RegExp(r'[,\s]+'))
                  .where((u) => u.isNotEmpty)
                  .toList(),
              totpSecret: _totp.text.trim().isEmpty ? null : _totp.text.trim(),
              clearTotp: _totp.text.trim().isEmpty,
              host: _host.text.trim(),
            )
          : null,
      card: _item.type == VaultItemType.card
          ? CardData(
              holder: _holder.text.trim(),
              number: _number.text.trim(),
              expiryMonth: exp == null ? null : int.parse(exp.group(1)!),
              expiryYear: exp == null ? null : int.parse(exp.group(2)!),
              cvv: _cvv.text.trim(),
              pin: _pin.text.trim(),
            )
          : null,
      document: _item.type == VaultItemType.document
          ? DocumentData(
              documentType: _docType,
              number: _docNumber.text.trim(),
              fullName: _docName.text.trim(),
              issuer: _docIssuer.text.trim(),
              expiryDate: _docExpiry,
              attachments: _attachments,
            )
          : null,
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final saved = await ref.read(vaultActionsProvider).save(_build());
      if (!mounted) return;
      await showSuccessDialog(
        context,
        message: switch (saved.type) {
          VaultItemType.login => 'Ihr Passwort wurde sicher gespeichert.',
          VaultItemType.card => 'Ihre Karte wurde sicher gespeichert.',
          VaultItemType.document => 'Ihr Dokument wurde sicher gespeichert.',
          VaultItemType.note => 'Ihre Notiz wurde sicher gespeichert.',
        },
      );
      if (!mounted) return;
      if (_isNew) {
        context.pushReplacement(Routes.item(saved.id));
      } else {
        context.pop();
      }
    } on Object catch (e) {
      if (mounted) context.showError('Speichern fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _generate() {
    ref.read(generatorControllerProvider.notifier).regenerate();
    _password.text = ref.read(generatorControllerProvider).password;
  }

  Future<void> _addAttachment() async {
    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null) return;
    try {
      final bytes = await file.readAsBytes();
      final attachment = await ref
          .read(vaultActionsProvider)
          .addAttachment(file.name, bytes);
      setState(() => _attachments = [..._attachments, attachment]);
    } on Object catch (e) {
      if (mounted) context.showError('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(foldersProvider);
    return G04Scaffold(
      title: _isNew ? 'Neuer Eintrag' : 'Bearbeiten',
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            if (_isNew) _TypeTabs(selected: _item.type, onSelect: _switchType),
            const SizedBox(height: 12),
            AppTextField(
              controller: _title,
              label: 'Titel',
              hint: switch (_item.type) {
                VaultItemType.login => 'z. B. Google, Router Büro, HMI Linie 3',
                VaultItemType.card => 'z. B. Visa Privat',
                VaultItemType.document => 'z. B. Reisepass',
                VaultItemType.note => 'z. B. WLAN-Passwort',
              },
              icon: Icons.title_rounded,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Bitte Titel eingeben' : null,
            ),
            const SizedBox(height: 12),
            ...switch (_item.type) {
              VaultItemType.login => _loginFields(),
              VaultItemType.card => _cardFields(),
              VaultItemType.document => _documentFields(),
              VaultItemType.note => <Widget>[],
            },
            const SizedBox(height: 12),
            DropdownButtonFormField<ItemCategory>(
              // Re-created when the type tab changes so the new default shows.
              key: ValueKey('category-${_item.type.name}'),
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Kategorie',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final c in ItemCategory.values)
                  DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Icon(c.icon, color: c.color, size: 20),
                        const SizedBox(width: 10),
                        Text(c.label),
                      ],
                    ),
                  ),
              ],
              onChanged: (c) => setState(() => _category = c ?? _category),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: folders.any((f) => f.id == _folderId)
                  ? _folderId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Ordner',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
              items: [
                const DropdownMenuItem<String?>(child: Text('Kein Ordner')),
                for (final f in folders)
                  DropdownMenuItem<String?>(value: f.id, child: Text(f.name)),
              ],
              onChanged: (id) => setState(() => _folderId = id),
            ),
            const SizedBox(height: 12),
            _TagEditor(
              tags: _tags,
              controller: _tagInput,
              onChanged: (t) => setState(() => _tags = t),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _notes,
              label: 'Notizen',
              icon: Icons.notes_rounded,
              maxLines: _item.type == VaultItemType.note ? 10 : 4,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 12),
            ..._customFieldEditors(),
            TextButton.icon(
              onPressed: () => setState(
                () => _fields = [
                  ..._fields,
                  const CustomField(name: '', value: ''),
                ],
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Eigenes Feld hinzufügen'),
            ),
            SwitchListTile(
              value: _favorite,
              onChanged: (v) => setState(() => _favorite = v),
              title: const Text('Favorit'),
              secondary: const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFC857),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            NeonButton(
              label: 'Speichern',
              icon: Icons.save_rounded,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _loginFields() {
    final strength = ref.watch(passwordStrengthProvider(_password.text));
    return [
      AppTextField(
        controller: _username,
        label: 'Benutzername / E-Mail',
        hint: 'z. B. paul@example.com',
        icon: Icons.person_outline_rounded,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.username],
      ),
      const SizedBox(height: 12),
      AppTextField(
        controller: _password,
        label: 'Passwort',
        icon: Icons.key_rounded,
        isSecret: true,
        suffix: IconButton(
          tooltip: 'Passwort generieren',
          icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.cyan),
          onPressed: _generate,
        ),
      ),
      const SizedBox(height: 8),
      StrengthMeter(strength: strength),
      const SizedBox(height: 12),
      AppTextField(
        controller: _url,
        label: 'Webseite / URL',
        icon: Icons.language_rounded,
        keyboardType: TextInputType.url,
      ),
      const SizedBox(height: 12),
      AppTextField(
        controller: _host,
        label: 'Host / IP-Adresse (Geräte, HMI, Router)',
        hint: 'z. B. 192.168.0.1',
        icon: Icons.router_outlined,
        monospace: true,
      ),
      const SizedBox(height: 12),
      AppTextField(
        controller: _totp,
        label: '2FA-Schlüssel (TOTP)',
        hint: 'Base32-Secret oder otpauth://-Link',
        icon: Icons.qr_code_2_rounded,
        validator: (v) =>
            (v ?? '').trim().isEmpty ||
                ref.read(totpServiceProvider).parse(v!) != null
            ? null
            : 'Ungültiger TOTP-Schlüssel',
      ),
    ];
  }

  List<Widget> _cardFields() => [
    AppTextField(
      controller: _holder,
      label: 'Karteninhaber',
      icon: Icons.person_outline_rounded,
    ),
    const SizedBox(height: 12),
    AppTextField(
      controller: _number,
      label: 'Kartennummer',
      icon: Icons.credit_card_rounded,
      keyboardType: TextInputType.number,
      monospace: true,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
    ),
    const SizedBox(height: 12),
    Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: _expiry,
            label: 'Gültig bis (MM/JJ)',
            icon: Icons.event_rounded,
            keyboardType: TextInputType.datetime,
            validator: (v) =>
                (v ?? '').isEmpty ||
                    RegExp(r'^\d{1,2}\s*/\s*\d{2,4}$').hasMatch(v!.trim())
                ? null
                : 'Format MM/JJ',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppTextField(
            controller: _cvv,
            label: 'CVV',
            isSecret: true,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    ),
    const SizedBox(height: 12),
    AppTextField(
      controller: _pin,
      label: 'PIN',
      icon: Icons.pin_outlined,
      isSecret: true,
    ),
  ];

  List<Widget> _documentFields() => [
    DropdownButtonFormField<String>(
      initialValue: _docType,
      decoration: const InputDecoration(
        labelText: 'Dokumenttyp',
        prefixIcon: Icon(Icons.badge_outlined),
      ),
      items: [
        for (final t in DocumentData.types)
          DropdownMenuItem(value: t, child: Text(t)),
      ],
      onChanged: (t) => setState(() => _docType = t ?? _docType),
    ),
    const SizedBox(height: 12),
    AppTextField(
      controller: _docNumber,
      label: 'Dokumentnummer',
      icon: Icons.numbers_rounded,
    ),
    const SizedBox(height: 12),
    AppTextField(
      controller: _docName,
      label: 'Name',
      icon: Icons.person_outline_rounded,
    ),
    const SizedBox(height: 12),
    AppTextField(
      controller: _docIssuer,
      label: 'Ausstellende Behörde',
      icon: Icons.account_balance_outlined,
    ),
    const SizedBox(height: 12),
    GlassTile(
      icon: Icons.event_available_rounded,
      title: 'Gültig bis',
      value: _docExpiry == null
          ? 'Nicht gesetzt'
          : DateFormat.yMd('de_DE').format(_docExpiry!),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _docExpiry ?? DateTime.now(),
          firstDate: DateTime(1950),
          lastDate: DateTime(2100),
        );
        if (picked != null) setState(() => _docExpiry = picked);
      },
    ),
    for (final a in _attachments)
      GlassTile(
        icon: Icons.insert_drive_file_rounded,
        iconColor: AppColors.danger,
        title: a.name,
        subtitle: formatBytes(a.size),
        trailing: IconButton(
          tooltip: 'Entfernen',
          icon: const Icon(Icons.close_rounded),
          onPressed: () async {
            await ref.read(vaultActionsProvider).deleteAttachment(a.id);
            setState(
              () => _attachments = _attachments
                  .where((x) => x.id != a.id)
                  .toList(),
            );
          },
        ),
      ),
    TextButton.icon(
      onPressed: _addAttachment,
      icon: const Icon(Icons.attach_file_rounded),
      label: const Text(
        'Datei anhängen (PDF, Bild – verschlüsselt, max. 10 MB)',
      ),
    ),
  ];

  List<Widget> _customFieldEditors() => [
    for (var i = 0; i < _fields.length; i++)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _fields[i].name,
                decoration: const InputDecoration(labelText: 'Feldname'),
                onChanged: (v) => _fields[i] = CustomField(
                  name: v,
                  value: _fields[i].value,
                  secret: _fields[i].secret,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: _fields[i].value,
                obscureText: _fields[i].secret,
                decoration: const InputDecoration(labelText: 'Wert'),
                onChanged: (v) => _fields[i] = CustomField(
                  name: _fields[i].name,
                  value: v,
                  secret: _fields[i].secret,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Geheim',
              icon: Icon(
                _fields[i].secret
                    ? Icons.lock_rounded
                    : Icons.lock_open_rounded,
              ),
              onPressed: () => setState(
                () => _fields[i] = CustomField(
                  name: _fields[i].name,
                  value: _fields[i].value,
                  secret: !_fields[i].secret,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Entfernen',
              icon: const Icon(Icons.remove_circle_outline_rounded),
              onPressed: () =>
                  setState(() => _fields = [..._fields]..removeAt(i)),
            ),
          ],
        ),
      ),
  ];
}

class _TypeTabs extends StatelessWidget {
  const _TypeTabs({required this.selected, required this.onSelect});

  final VaultItemType selected;
  final ValueChanged<VaultItemType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final t in VaultItemType.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GlassCard(
                onTap: () => onSelect(t),
                padding: const EdgeInsets.symmetric(vertical: 12),
                borderRadius: 14,
                glowColor: t == selected ? AppColors.neonBlue : null,
                borderColor: t == selected ? AppColors.neonBlueLight : null,
                child: Column(
                  children: [
                    Icon(
                      t.icon,
                      color: t == selected
                          ? AppColors.neonBlueLight
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TagEditor extends StatelessWidget {
  const _TagEditor({
    required this.tags,
    required this.controller,
    required this.onChanged,
  });

  final List<String> tags;
  final TextEditingController controller;
  final ValueChanged<List<String>> onChanged;

  void _add() {
    final t = controller.text.trim().replaceAll(',', '');
    if (t.isEmpty || tags.contains(t)) return;
    onChanged([...tags, t]);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Tags',
            hintText: 'Tag eingeben und Enter drücken',
            prefixIcon: const Icon(Icons.sell_outlined),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: _add,
            ),
          ),
          onSubmitted: (_) => _add(),
        ),
        if (tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final t in tags)
                  InputChip(
                    label: Text(t),
                    onDeleted: () =>
                        onChanged(tags.where((x) => x != t).toList()),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
