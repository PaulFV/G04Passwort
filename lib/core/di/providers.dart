import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../models/app_settings.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/vault_repository.dart';
import '../../services/biometric_service.dart';
import '../../services/clipboard_service.dart';
import '../../services/crypto/crypto_service.dart';
import '../../services/crypto/key_derivation_service.dart';
import '../../services/import_export_service.dart';
import '../../services/password_analyzer_service.dart';
import '../../services/password_generator_service.dart';
import '../../services/screen_protection_service.dart';
import '../../services/secure_storage_service.dart';
import '../../services/security_audit_service.dart';
import '../../services/sync/cloud_sync.dart';
import '../../services/totp_service.dart';

/// Dependency injection graph of G04Passwort.
///
/// Every service and repository is exposed through a Riverpod provider so
/// it can be overridden in tests (`ProviderScope(overrides: [...])`).

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);

final cryptoServiceProvider = Provider<CryptoService>((ref) => CryptoService());

final keyDerivationProvider = Provider<KeyDerivationService>(
  (ref) => const KeyDerivationService(),
);

final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(),
);

final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  final service = ClipboardService();
  ref.onDispose(service.dispose);
  return service;
});

final screenProtectionProvider = Provider<ScreenProtectionService>(
  (ref) => ScreenProtectionService(),
);

final totpServiceProvider = Provider<TotpService>((ref) => const TotpService());

final passwordGeneratorProvider = Provider<PasswordGeneratorService>(
  (ref) => PasswordGeneratorService(),
);

final passwordAnalyzerProvider = Provider<PasswordAnalyzerService>(
  (ref) => const PasswordAnalyzerService(),
);

final securityAuditServiceProvider = Provider<SecurityAuditService>(
  (ref) => SecurityAuditService(ref.watch(passwordAnalyzerProvider)),
);

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(secureStorageProvider)),
);

/// Settings loaded in `main()` before the first frame (overridden there).
final initialSettingsProvider = Provider<AppSettings>(
  (ref) => const AppSettings(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    database: ref.watch(databaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    kdf: ref.watch(keyDerivationProvider),
    storage: ref.watch(secureStorageProvider),
  ),
);

final vaultRepositoryProvider = Provider<VaultRepository>(
  (ref) => VaultRepositoryImpl(
    database: ref.watch(databaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    auth: ref.watch(authRepositoryProvider),
  ),
);

final importExportServiceProvider = Provider<ImportExportService>(
  (ref) => ImportExportService(
    database: ref.watch(databaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    auth: ref.watch(authRepositoryProvider),
    vault: ref.watch(vaultRepositoryProvider),
  ),
);

final cloudSyncProvidersProvider = Provider<List<CloudSyncProvider>>(
  (ref) => const [
    GoogleDriveSyncProvider(),
    OneDriveSyncProvider(),
    ICloudSyncProvider(),
    WebDavSyncProvider(),
  ],
);

final syncServiceProvider = Provider<SyncService>((ref) {
  final io = ref.watch(importExportServiceProvider);
  return SyncService(
    providers: ref.watch(cloudSyncProvidersProvider),
    createSnapshot: io.createEncryptedBackup,
    mergeSnapshot: io.mergeSnapshot,
  );
});
