import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/di/providers.dart';
import '../../../services/import_export_service.dart';
import '../../settings/application/settings_controller.dart';
import '../../vault/application/vault_providers.dart';

/// Use cases of the Backup screen (file dialogs + import/export service).
class BackupController {
  BackupController(this._ref);

  final Ref _ref;

  ImportExportService get _io => _ref.read(importExportServiceProvider);

  String get _stamp => DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());

  /// Saves an encrypted backup. Returns `false` if the user cancelled.
  Future<bool> exportEncryptedBackup() async {
    final bytes = await _io.createEncryptedBackup();
    final uri = await FilePicker.saveFile(
      fileName: 'G04Passwort_Backup_$_stamp.g04vault',
      bytes: bytes,
      mimeType: 'application/json',
    );
    if (uri == null) return false;
    await _ref.read(settingsControllerProvider.notifier).markBackupDone();
    return true;
  }

  /// Exports all logins as plain CSV (after explicit user confirmation).
  Future<bool> exportCsv() async {
    final csv = _io.exportCsv(_ref.read(itemsProvider));
    final uri = await FilePicker.saveFile(
      fileName: 'G04Passwort_Export_$_stamp.csv',
      bytes: Uint8List.fromList(utf8.encode(csv)),
      mimeType: 'text/csv',
    );
    return uri != null;
  }

  /// Lets the user pick a file. Returns `null` when cancelled.
  Future<({String name, Uint8List bytes})?> pickFile(List<String> extensions) async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: extensions);
    if (file == null) return null;
    return (name: file.name, bytes: await file.readAsBytes());
  }

  Future<ImportResult> restoreBackup(Uint8List bytes, String password) =>
      _io.restoreEncryptedBackup(bytes, password);

  Future<ImportResult> importCsv(Uint8List bytes) => _io.importCsv(utf8.decode(bytes, allowMalformed: true));
}

final backupControllerProvider = Provider<BackupController>(BackupController.new);
