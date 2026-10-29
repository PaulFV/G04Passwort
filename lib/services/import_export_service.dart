import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../core/errors/vault_exceptions.dart';
import '../database/app_database.dart';
import '../models/item_category.dart';
import '../models/vault_item.dart';
import '../models/vault_item_type.dart';
import '../repositories/auth_repository.dart';
import '../repositories/vault_repository.dart';
import 'crypto/crypto_service.dart';
import 'crypto/vault_header.dart';

/// Result summary of an import.
class ImportResult {
  const ImportResult({required this.imported, required this.skipped});

  final int imported;
  final int skipped;
}

/// Backup (encrypted), CSV import (Bitwarden, 1Password, Chrome, KeePass,
/// Firefox …) and CSV export.
class ImportExportService {
  ImportExportService({
    required AppDatabase database,
    required CryptoService crypto,
    required AuthRepository auth,
    required VaultRepository vault,
  })  : _db = database,
        _crypto = crypto,
        _auth = auth,
        _vault = vault;

  static const String backupFormat = 'g04passwort-backup';
  static const int backupVersion = 1;

  final AppDatabase _db;
  final CryptoService _crypto;
  final AuthRepository _auth;
  final VaultRepository _vault;
  final _uuid = const Uuid();

  // ---------------------------------------------------------------------------
  // Encrypted backup (.g04vault)
  // ---------------------------------------------------------------------------

  /// Creates an encrypted backup. The rows are exported as they are stored
  /// (already AES-GCM encrypted) together with the vault header, so the
  /// backup can only be opened with the master password.
  Future<Uint8List> createEncryptedBackup() async {
    final header = await _auth.readHeader();
    if (header == null) throw const VaultLockedException();
    List<Map<String, Object>> rows(List<EncryptedRow> r) => [
          for (final row in r)
            {'id': row.id, 'payload': row.payload, 'updated': row.updatedAt.millisecondsSinceEpoch},
        ];
    final json = {
      'format': backupFormat,
      'version': backupVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'header': header.toJson(),
      'items': rows(await _db.readAll(AppDatabase.tableItems)),
      'folders': rows(await _db.readAll(AppDatabase.tableFolders)),
      'attachments': rows(await _db.readAll(AppDatabase.tableAttachments)),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(json)));
  }

  /// Restores an encrypted backup created with [password] (the master
  /// password that was active when the backup was made). Items are merged:
  /// for equal ids the newer version wins.
  Future<ImportResult> restoreEncryptedBackup(Uint8List bytes, String password) async {
    final json = _decodeBackup(bytes);
    final header = VaultHeader.fromJson(json['header'] as Map<String, dynamic>);
    final backupKey = await _auth.unwrapKey(header, password);
    try {
      return await _restore(json, backupKey);
    } finally {
      CryptoService.wipe(backupKey);
    }
  }

  /// Merges a snapshot of the *same* vault (cloud sync) using the current
  /// in-memory vault key – no password prompt needed.
  Future<ImportResult> mergeSnapshot(Uint8List bytes) =>
      _restore(_decodeBackup(bytes), _auth.requireKey());

  Map<String, dynamic> _decodeBackup(Uint8List bytes) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } on Object {
      throw const InvalidBackupException();
    }
    if (json['format'] != backupFormat) throw const InvalidBackupException();
    return json;
  }

  Future<ImportResult> _restore(Map<String, dynamic> json, Uint8List backupKey) async {
    var imported = 0;
    var skipped = 0;
    {
      final restored = <VaultItem>[];
      for (final raw in json['items'] as List<dynamic>) {
        final row = raw as Map<String, dynamic>;
        try {
          final item = VaultItem.fromJson(
            await _crypto.decryptJson(row['payload'] as String, backupKey, aad: 'item:${row['id']}'),
          );
          final existing = _vault.byId(item.id);
          if (existing != null && !item.updatedAt.isAfter(existing.updatedAt)) {
            skipped++;
            continue;
          }
          restored.add(item);
        } on VaultException {
          skipped++;
        }
      }
      for (final raw in json['attachments'] as List<dynamic>? ?? const []) {
        final row = raw as Map<String, dynamic>;
        final id = row['id'] as String;
        try {
          final plain = await _crypto.decrypt(
            base64Decode(row['payload'] as String),
            backupKey,
            aad: utf8.encode('file:$id'),
          );
          await _vault.putAttachment(id, plain);
        } on VaultException {
          // ignore broken attachment
        }
      }
      for (final raw in json['folders'] as List<dynamic>? ?? const []) {
        final row = raw as Map<String, dynamic>;
        try {
          final folder = VaultFolder.fromJson(
            await _crypto.decryptJson(row['payload'] as String, backupKey, aad: 'folder:${row['id']}'),
          );
          await _vault.saveFolder(folder.name, id: folder.id);
        } on VaultException {
          // ignore broken folder
        }
      }
      await _vault.saveAll(restored);
      imported = restored.length;
    }
    return ImportResult(imported: imported, skipped: skipped);
  }

  // ---------------------------------------------------------------------------
  // CSV
  // ---------------------------------------------------------------------------

  /// Imports a CSV export of another password manager. Column names are
  /// detected automatically (Bitwarden, 1Password, Chrome/Edge, Firefox,
  /// KeePass/KeePassXC, LastPass).
  Future<ImportResult> importCsv(String content) async {
    final rows = parseCsv(content);
    if (rows.length < 2) throw const InvalidBackupException('Die CSV-Datei ist leer.');
    final header = rows.first.map((h) => h.trim().toLowerCase()).toList();

    int col(List<String> names) => header.indexWhere(names.contains);
    final iTitle = col(['name', 'title', 'titel', 'account']);
    final iUrl = col(['url', 'login_uri', 'website', 'web site', 'origin']);
    final iUser = col(['username', 'login_username', 'login name', 'user name', 'benutzername', 'email']);
    final iPass = col(['password', 'login_password', 'passwort', 'kennwort']);
    final iNotes = col(['notes', 'note', 'extra', 'comments', 'notizen']);
    final iTotp = col(['totp', 'login_totp', 'otpauth', 'one-time password']);
    final iFolder = col(['folder', 'grouping', 'group', 'ordner']);
    final iFav = col(['favorite', 'fav']);
    if (iPass < 0 && iUser < 0) {
      throw const InvalidBackupException('Spalten „username“/„password“ nicht gefunden.');
    }

    String cell(List<String> row, int i) => i >= 0 && i < row.length ? row[i].trim() : '';

    final folderIds = <String, String>{};
    final items = <VaultItem>[];
    var skipped = 0;
    for (final row in rows.skip(1)) {
      if (row.every((c) => c.trim().isEmpty)) continue;
      final pass = cell(row, iPass);
      final user = cell(row, iUser);
      final url = cell(row, iUrl);
      if (pass.isEmpty && user.isEmpty) {
        skipped++;
        continue;
      }
      final folderName = cell(row, iFolder);
      String? folderId;
      if (folderName.isNotEmpty) {
        folderId = folderIds[folderName] ??=
            (await _vault.saveFolder(folderName)).id;
      }
      final now = DateTime.now();
      var title = cell(row, iTitle);
      if (title.isEmpty) title = Uri.tryParse(url)?.host ?? user;
      final totp = cell(row, iTotp);
      items.add(
        VaultItem(
          id: _uuid.v4(),
          type: VaultItemType.login,
          title: title,
          category: ItemCategory.login,
          folderId: folderId,
          favorite: cell(row, iFav) == '1' || cell(row, iFav).toLowerCase() == 'true',
          notes: cell(row, iNotes),
          login: LoginData(
            username: user,
            password: pass,
            urls: url.isEmpty ? const [] : [url],
            totpSecret: totp.isEmpty ? null : totp,
            passwordChangedAt: now,
          ),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    await _vault.saveAll(items);
    return ImportResult(imported: items.length, skipped: skipped);
  }

  /// Exports all logins as **unencrypted** CSV (Bitwarden compatible).
  String exportCsv(List<VaultItem> items) {
    final buffer = StringBuffer('folder,favorite,type,name,notes,login_uri,login_username,login_password,login_totp\n');
    for (final i in items.where((i) => i.type == VaultItemType.login)) {
      final l = i.login!;
      buffer.writeln([
        '',
        i.favorite ? '1' : '',
        'login',
        i.title,
        i.notes,
        l.urls.join(' '),
        l.username,
        l.password,
        l.totpSecret ?? '',
      ].map(_escape).join(','));
    }
    return buffer.toString();
  }

  static String _escape(String v) =>
      v.contains(RegExp('[",\n\r]')) ? '"${v.replaceAll('"', '""')}"' : v;

  /// RFC 4180 CSV parser (quotes, escaped quotes, embedded newlines).
  static List<List<String>> parseCsv(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;
    final text = input.startsWith('\uFEFF') ? input.substring(1) : input;
    final separator = _isSemicolonCsv(text) ? ';' : ',';
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(c);
        }
      } else if (c == '"') {
        inQuotes = true;
      } else if (c == separator) {
        row.add(field.toString());
        field.clear();
      } else if (c == '\n' || c == '\r') {
        if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        row.add(field.toString());
        field.clear();
        rows.add(row);
        row = <String>[];
      } else {
        field.write(c);
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }

  /// German Excel exports use ";" as separator.
  static bool _isSemicolonCsv(String text) {
    final firstLine = text.split('\n').first;
    return ';'.allMatches(firstLine).length > ','.allMatches(firstLine).length;
  }
}
