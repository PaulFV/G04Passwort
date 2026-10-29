import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../core/constants/app_constants.dart';

/// Encrypted row as stored in SQLite. [payload] is a base64 AES-GCM
/// envelope – the database never sees plaintext vault data.
class EncryptedRow {
  const EncryptedRow({
    required this.id,
    required this.payload,
    required this.updatedAt,
  });

  final String id;
  final String payload;
  final DateTime updatedAt;
}

/// Local SQLite database (Drift).
///
/// The schema is intentionally minimal and "dumb": every table stores only
/// an id, a timestamp (needed for sync conflict resolution) and an
/// encrypted payload. Filtering & searching happens in memory after
/// decryption. Because no column contains plaintext, the database file is
/// safe even if it is copied off the device.
///
/// Raw SQL is used instead of generated table classes so the project
/// builds without a `build_runner` step.
class AppDatabase extends GeneratedDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static QueryExecutor _openConnection() => driftDatabase(
    name: AppConstants.databaseName,
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );

  static const tableItems = 'vault_items';
  static const tableFolders = 'folders';
  static const tableAttachments = 'attachments';

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await customStatement('''
            CREATE TABLE IF NOT EXISTS vault_meta (
              key TEXT NOT NULL PRIMARY KEY,
              value TEXT NOT NULL
            )''');
      for (final table in [tableItems, tableFolders, tableAttachments]) {
        await customStatement('''
              CREATE TABLE IF NOT EXISTS $table (
                id TEXT NOT NULL PRIMARY KEY,
                payload TEXT NOT NULL,
                updated_at INTEGER NOT NULL
              )''');
      }
    },
    onUpgrade: (m, from, to) async {
      // Future schema migrations go here.
    },
  );

  // ---------------------------------------------------------------------------
  // Meta (vault header etc.)
  // ---------------------------------------------------------------------------

  Future<String?> readMeta(String key) async {
    final rows = await customSelect(
      'SELECT value FROM vault_meta WHERE key = ?',
      variables: [Variable.withString(key)],
    ).get();
    return rows.isEmpty ? null : rows.first.read<String>('value');
  }

  Future<void> writeMeta(String key, String value) => customStatement(
    'INSERT OR REPLACE INTO vault_meta (key, value) VALUES (?, ?)',
    [key, value],
  );

  Future<void> deleteMeta(String key) =>
      customStatement('DELETE FROM vault_meta WHERE key = ?', [key]);

  // ---------------------------------------------------------------------------
  // Encrypted rows
  // ---------------------------------------------------------------------------

  Future<List<EncryptedRow>> readAll(String table) async {
    final rows = await customSelect(
      'SELECT id, payload, updated_at FROM $table ORDER BY updated_at DESC',
    ).get();
    return rows
        .map(
          (r) => EncryptedRow(
            id: r.read<String>('id'),
            payload: r.read<String>('payload'),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              r.read<int>('updated_at'),
            ),
          ),
        )
        .toList();
  }

  Future<EncryptedRow?> readOne(String table, String id) async {
    final rows = await customSelect(
      'SELECT id, payload, updated_at FROM $table WHERE id = ?',
      variables: [Variable.withString(id)],
    ).get();
    if (rows.isEmpty) return null;
    final r = rows.first;
    return EncryptedRow(
      id: r.read<String>('id'),
      payload: r.read<String>('payload'),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(r.read<int>('updated_at')),
    );
  }

  Future<void> upsert(String table, EncryptedRow row) => customStatement(
    'INSERT OR REPLACE INTO $table (id, payload, updated_at) VALUES (?, ?, ?)',
    [row.id, row.payload, row.updatedAt.millisecondsSinceEpoch],
  );

  Future<void> upsertAll(String table, List<EncryptedRow> rows) =>
      transaction(() async {
        for (final row in rows) {
          await upsert(table, row);
        }
      });

  Future<void> deleteRow(String table, String id) =>
      customStatement('DELETE FROM $table WHERE id = ?', [id]);

  /// Removes all vault data (used by "Tresor zurücksetzen").
  Future<void> wipe() => transaction(() async {
    for (final t in [
      'vault_meta',
      tableItems,
      tableFolders,
      tableAttachments,
    ]) {
      await customStatement('DELETE FROM $t');
    }
  });
}
