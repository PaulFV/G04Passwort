import 'dart:convert';

import '../core/constants/app_constants.dart';
import '../models/app_settings.dart';
import '../services/secure_storage_service.dart';

/// Persists [AppSettings].
abstract interface class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._storage);

  final SecureStorageService _storage;

  @override
  Future<AppSettings> load() async {
    final raw = await _storage.read(StorageKeys.settings);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) =>
      _storage.write(StorageKeys.settings, jsonEncode(settings.toJson()));
}
