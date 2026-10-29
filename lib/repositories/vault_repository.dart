import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/vault_exceptions.dart';
import '../database/app_database.dart';
import '../models/item_category.dart';
import '../models/vault_item.dart';
import '../models/vault_item_type.dart';
import '../services/crypto/crypto_service.dart';
import 'auth_repository.dart';

/// CRUD access to decrypted vault content.
abstract interface class VaultRepository {
  /// Decrypts all rows into the in-memory cache (after unlock).
  Future<void> load();

  /// Emits the current items immediately and after every change.
  Stream<List<VaultItem>> watchItems();
  Stream<List<VaultFolder>> watchFolders();

  List<VaultItem> get items;
  List<VaultFolder> get folders;

  VaultItem? byId(String id);

  /// Inserts or updates an item. Handles password history for logins.
  Future<VaultItem> save(VaultItem item);

  /// Saves many items in one transaction (import, sync).
  Future<void> saveAll(List<VaultItem> items);

  Future<void> delete(String id);
  Future<void> toggleFavorite(String id);

  Future<VaultFolder> saveFolder(String name, {String? id});
  Future<void> deleteFolder(String id);

  Future<AttachmentRef> addAttachment(
    String name,
    Uint8List bytes, {
    String? mimeType,
  });
  Future<Uint8List> readAttachment(String id);
  Future<void> putAttachment(String id, Uint8List bytes);
  Future<void> deleteAttachment(String id);

  /// Drops decrypted data from memory (on lock).
  void clear();

  /// Creates a new empty item of [type] (not yet saved).
  VaultItem newItem(VaultItemType type);
}

class VaultRepositoryImpl implements VaultRepository {
  VaultRepositoryImpl({
    required AppDatabase database,
    required CryptoService crypto,
    required AuthRepository auth,
  }) : _db = database,
       _crypto = crypto,
       _auth = auth;

  final AppDatabase _db;
  final CryptoService _crypto;
  final AuthRepository _auth;
  final _uuid = const Uuid();

  final Map<String, VaultItem> _items = {};
  final Map<String, VaultFolder> _folders = {};
  final _itemsController = StreamController<List<VaultItem>>.broadcast();
  final _foldersController = StreamController<List<VaultFolder>>.broadcast();

  static String _itemAad(String id) => 'item:$id';
  static String _folderAad(String id) => 'folder:$id';
  static String _fileAad(String id) => 'file:$id';

  @override
  List<VaultItem> get items {
    final list = _items.values.toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return List.unmodifiable(list);
  }

  @override
  List<VaultFolder> get folders {
    final list = _folders.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List.unmodifiable(list);
  }

  @override
  VaultItem? byId(String id) => _items[id];

  @override
  Future<void> load() async {
    final key = _auth.requireKey();
    _items.clear();
    _folders.clear();
    for (final row in await _db.readAll(AppDatabase.tableItems)) {
      try {
        final json = await _crypto.decryptJson(
          row.payload,
          key,
          aad: _itemAad(row.id),
        );
        _items[row.id] = VaultItem.fromJson(json);
      } on VaultException {
        // Skip corrupted rows instead of failing the whole vault.
      }
    }
    for (final row in await _db.readAll(AppDatabase.tableFolders)) {
      try {
        final json = await _crypto.decryptJson(
          row.payload,
          key,
          aad: _folderAad(row.id),
        );
        _folders[row.id] = VaultFolder.fromJson(json);
      } on VaultException {
        // ignore corrupted folder
      }
    }
    _emit();
  }

  @override
  Stream<List<VaultItem>> watchItems() async* {
    yield items;
    yield* _itemsController.stream;
  }

  @override
  Stream<List<VaultFolder>> watchFolders() async* {
    yield folders;
    yield* _foldersController.stream;
  }

  @override
  VaultItem newItem(VaultItemType type) {
    final now = DateTime.now();
    return VaultItem(
      id: _uuid.v4(),
      type: type,
      title: '',
      category: ItemCategory.forType(type),
      createdAt: now,
      updatedAt: now,
      login: type == VaultItemType.login
          ? LoginData(passwordChangedAt: now)
          : null,
      card: type == VaultItemType.card ? const CardData() : null,
      document: type == VaultItemType.document ? const DocumentData() : null,
    );
  }

  @override
  Future<VaultItem> save(VaultItem item) async {
    final prepared = _prepare(item);
    await _db.upsert(AppDatabase.tableItems, await _encryptItem(prepared));
    _items[prepared.id] = prepared;
    _emit();
    return prepared;
  }

  @override
  Future<void> saveAll(List<VaultItem> items) async {
    final rows = <EncryptedRow>[];
    for (final item in items) {
      rows.add(await _encryptItem(item));
    }
    await _db.upsertAll(AppDatabase.tableItems, rows);
    for (final item in items) {
      _items[item.id] = item;
    }
    _emit();
  }

  /// Applies business rules before saving: timestamps and password history.
  VaultItem _prepare(VaultItem item) {
    final now = DateTime.now();
    final previous = _items[item.id];
    var login = item.login;
    if (login != null && previous?.login != null) {
      final oldPw = previous!.login!.password;
      if (oldPw.isNotEmpty && oldPw != login.password) {
        final history = [
          PasswordHistoryEntry(password: oldPw, changedAt: now),
          ...login.passwordHistory,
        ].take(AppConstants.passwordHistoryLength).toList();
        login = login.copyWith(
          passwordHistory: history,
          passwordChangedAt: now,
        );
      }
    }
    return item.copyWith(
      title: item.title.trim().isEmpty ? 'Ohne Titel' : item.title.trim(),
      login: login,
      updatedAt: now,
    );
  }

  Future<EncryptedRow> _encryptItem(VaultItem item) async => EncryptedRow(
    id: item.id,
    payload: await _crypto.encryptJson(
      item.toJson(),
      _auth.requireKey(),
      aad: _itemAad(item.id),
    ),
    updatedAt: item.updatedAt,
  );

  @override
  Future<void> delete(String id) async {
    final item = _items[id];
    for (final file in item?.document?.attachments ?? const <AttachmentRef>[]) {
      await deleteAttachment(file.id);
    }
    await _db.deleteRow(AppDatabase.tableItems, id);
    _items.remove(id);
    _emit();
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final item = _items[id];
    if (item == null) return;
    final updated = item.copyWith(favorite: !item.favorite);
    await _db.upsert(AppDatabase.tableItems, await _encryptItem(updated));
    _items[id] = updated;
    _emit();
  }

  @override
  Future<VaultFolder> saveFolder(String name, {String? id}) async {
    final folder = VaultFolder(
      id: id ?? _uuid.v4(),
      name: name.trim(),
      updatedAt: DateTime.now(),
    );
    await _db.upsert(
      AppDatabase.tableFolders,
      EncryptedRow(
        id: folder.id,
        payload: await _crypto.encryptJson(
          folder.toJson(),
          _auth.requireKey(),
          aad: _folderAad(folder.id),
        ),
        updatedAt: folder.updatedAt,
      ),
    );
    _folders[folder.id] = folder;
    _emit();
    return folder;
  }

  @override
  Future<void> deleteFolder(String id) async {
    await _db.deleteRow(AppDatabase.tableFolders, id);
    _folders.remove(id);
    // Items of the folder are kept and simply un-assigned.
    final affected = _items.values.where((i) => i.folderId == id).toList();
    await saveAll([for (final i in affected) i.copyWith(clearFolder: true)]);
    _emit();
  }

  @override
  Future<AttachmentRef> addAttachment(
    String name,
    Uint8List bytes, {
    String? mimeType,
  }) async {
    if (bytes.length > AppConstants.maxAttachmentBytes) {
      throw const InvalidBackupException('Die Datei ist größer als 10 MB.');
    }
    final ref = AttachmentRef(
      id: _uuid.v4(),
      name: name,
      size: bytes.length,
      mimeType: mimeType ?? 'application/octet-stream',
    );
    await putAttachment(ref.id, bytes);
    return ref;
  }

  @override
  Future<void> putAttachment(String id, Uint8List bytes) async {
    final envelope = await _crypto.encrypt(
      bytes,
      _auth.requireKey(),
      aad: utf8.encode(_fileAad(id)),
    );
    await _db.upsert(
      AppDatabase.tableAttachments,
      EncryptedRow(
        id: id,
        payload: base64Encode(envelope),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Uint8List> readAttachment(String id) async {
    final row = await _db.readOne(AppDatabase.tableAttachments, id);
    if (row == null) throw const DataIntegrityException();
    return _crypto.decrypt(
      base64Decode(row.payload),
      _auth.requireKey(),
      aad: utf8.encode(_fileAad(id)),
    );
  }

  @override
  Future<void> deleteAttachment(String id) =>
      _db.deleteRow(AppDatabase.tableAttachments, id);

  @override
  void clear() {
    _items.clear();
    _folders.clear();
    _emit();
  }

  void _emit() {
    _itemsController.add(items);
    _foldersController.add(folders);
  }
}
