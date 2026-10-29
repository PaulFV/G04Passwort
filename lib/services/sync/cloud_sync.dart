import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/errors/vault_exceptions.dart';

/// Encrypted vault snapshot exchanged with a cloud provider. The payload is
/// an encrypted backup – providers never see plaintext (zero knowledge).
@immutable
class SyncSnapshot {
  const SyncSnapshot({required this.bytes, required this.modifiedAt, this.revision});

  final Uint8List bytes;
  final DateTime modifiedAt;

  /// Provider specific revision / ETag for optimistic concurrency.
  final String? revision;
}

/// Contract every cloud backend implements (Strategy pattern).
///
/// To add a provider: implement this interface (OAuth + file API), register
/// it in `cloudSyncProvidersProvider` and set [isAvailable] to `true`.
abstract interface class CloudSyncProvider {
  String get id;
  String get name;
  IconData get icon;

  /// Whether the provider is implemented on this platform.
  bool get isAvailable;

  Future<void> connect();
  Future<void> disconnect();

  /// Downloads the latest snapshot or `null` if none exists yet.
  Future<SyncSnapshot?> pull();

  /// Uploads a snapshot. Implementations must use [SyncSnapshot.revision]
  /// to detect concurrent modifications.
  Future<SyncSnapshot> push(SyncSnapshot snapshot);
}

/// Base class for providers that are architecturally prepared but not
/// implemented yet. All operations throw [FeatureNotAvailableException].
abstract class PreparedSyncProvider implements CloudSyncProvider {
  const PreparedSyncProvider();

  @override
  bool get isAvailable => false;

  Never _na() => throw FeatureNotAvailableException('$name-Synchronisation');

  @override
  Future<void> connect() async => _na();

  @override
  Future<void> disconnect() async {}

  @override
  Future<SyncSnapshot?> pull() async => _na();

  @override
  Future<SyncSnapshot> push(SyncSnapshot snapshot) async => _na();
}

/// Google Drive (appDataFolder) – planned.
class GoogleDriveSyncProvider extends PreparedSyncProvider {
  const GoogleDriveSyncProvider();

  @override
  String get id => 'google_drive';

  @override
  String get name => 'Google Drive';

  @override
  IconData get icon => Icons.add_to_drive_rounded;
}

/// Microsoft OneDrive (App Folder) – planned.
class OneDriveSyncProvider extends PreparedSyncProvider {
  const OneDriveSyncProvider();

  @override
  String get id => 'onedrive';

  @override
  String get name => 'OneDrive';

  @override
  IconData get icon => Icons.cloud_queue_rounded;
}

/// Apple iCloud Drive (CloudKit / ubiquity container) – planned.
class ICloudSyncProvider extends PreparedSyncProvider {
  const ICloudSyncProvider();

  @override
  String get id => 'icloud';

  @override
  String get name => 'iCloud';

  @override
  IconData get icon => Icons.cloud_rounded;
}

/// Self-hosted WebDAV (Nextcloud, NAS) – planned.
class WebDavSyncProvider extends PreparedSyncProvider {
  const WebDavSyncProvider();

  @override
  String get id => 'webdav';

  @override
  String get name => 'WebDAV / Nextcloud';

  @override
  IconData get icon => Icons.dns_rounded;
}

/// Status of the last sync run.
enum SyncStatus { idle, syncing, success, error, unavailable }

/// Orchestrates a sync run: pull → merge (last-write-wins per item via the
/// encrypted backup restore) → push.
class SyncService {
  SyncService({
    required this.providers,
    required Future<Uint8List> Function() createSnapshot,
    required Future<void> Function(Uint8List bytes) mergeSnapshot,
  })  : _createSnapshot = createSnapshot,
        _mergeSnapshot = mergeSnapshot;

  final List<CloudSyncProvider> providers;
  final Future<Uint8List> Function() _createSnapshot;
  final Future<void> Function(Uint8List bytes) _mergeSnapshot;

  CloudSyncProvider? byId(String id) {
    for (final p in providers) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Runs a full sync with all [enabledIds]. Returns the number of
  /// providers synced successfully.
  Future<int> syncNow(Iterable<String> enabledIds) async {
    var ok = 0;
    for (final id in enabledIds) {
      final provider = byId(id);
      if (provider == null || !provider.isAvailable) continue;
      final remote = await provider.pull();
      if (remote != null) await _mergeSnapshot(remote.bytes);
      await provider.push(
        SyncSnapshot(
          bytes: await _createSnapshot(),
          modifiedAt: DateTime.now(),
          revision: remote?.revision,
        ),
      );
      ok++;
    }
    return ok;
  }
}
