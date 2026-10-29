import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../models/item_category.dart';
import '../../../models/security_report.dart';
import '../../../models/vault_item.dart';
import '../../../models/vault_item_type.dart';
import '../../../services/totp_service.dart';
import '../../auth/application/auth_controller.dart';
import '../../settings/application/settings_controller.dart';

/// Live, decrypted vault items (empty while locked).
final vaultItemsProvider = StreamProvider<List<VaultItem>>((ref) {
  final unlocked = ref.watch(authControllerProvider.select((s) => s.status == AuthStatus.unlocked));
  if (!unlocked) return Stream.value(const []);
  return ref.watch(vaultRepositoryProvider).watchItems();
});

/// Synchronous view of [vaultItemsProvider].
final itemsProvider = Provider<List<VaultItem>>(
  (ref) => ref.watch(vaultItemsProvider).value ?? const [],
);

final foldersStreamProvider = StreamProvider<List<VaultFolder>>((ref) {
  final unlocked = ref.watch(authControllerProvider.select((s) => s.status == AuthStatus.unlocked));
  if (!unlocked) return Stream.value(const []);
  return ref.watch(vaultRepositoryProvider).watchFolders();
});

final foldersProvider = Provider<List<VaultFolder>>(
  (ref) => ref.watch(foldersStreamProvider).value ?? const [],
);

final itemByIdProvider = Provider.family<VaultItem?, String>((ref, id) {
  for (final item in ref.watch(itemsProvider)) {
    if (item.id == id) return item;
  }
  return null;
});

final favoritesProvider = Provider<List<VaultItem>>(
  (ref) => ref.watch(itemsProvider).where((i) => i.favorite).toList(),
);

final itemsByTypeProvider = Provider.family<List<VaultItem>, VaultItemType>(
  (ref, type) => ref.watch(itemsProvider).where((i) => i.type == type).toList(),
);

final itemsByCategoryProvider = Provider.family<List<VaultItem>, ItemCategory>(
  (ref, c) => ref.watch(itemsProvider).where((i) => i.category == c).toList(),
);

final categoryCountsProvider = Provider<Map<ItemCategory, int>>((ref) {
  final counts = {for (final c in ItemCategory.values) c: 0};
  for (final item in ref.watch(itemsProvider)) {
    counts[item.category] = counts[item.category]! + 1;
  }
  return counts;
});

final allTagsProvider = Provider<List<String>>((ref) {
  final tags = <String>{for (final i in ref.watch(itemsProvider)) ...i.tags};
  return tags.toList()..sort();
});

/// Items with a TOTP secret (2FA Authenticator).
final totpItemsProvider = Provider<List<VaultItem>>(
  (ref) => ref.watch(itemsProvider).where((i) => i.login?.hasTotp ?? false).toList(),
);

/// Most recently changed items (Passwort-Verlauf / letzte Änderungen).
final recentItemsProvider = Provider<List<VaultItem>>((ref) {
  final list = [...ref.watch(itemsProvider)]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return list;
});

/// Security center report, recomputed whenever items change.
final securityReportProvider = Provider<SecurityReport>(
  (ref) => ref.watch(securityAuditServiceProvider).audit(ref.watch(itemsProvider)),
);

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

class SearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQueryController, String>(SearchQueryController.new);

final searchResultsProvider = Provider<List<VaultItem>>((ref) {
  final q = ref.watch(searchQueryProvider).trim().toLowerCase();
  final items = ref.watch(itemsProvider);
  if (q.isEmpty) return items;
  final terms = q.split(RegExp(r'\s+'));
  return items.where((i) {
    final text = i.searchText;
    return terms.every(text.contains);
  }).toList();
});

// ---------------------------------------------------------------------------
// TOTP
// ---------------------------------------------------------------------------

/// Ticks every second while listened to (drives TOTP countdowns).
final clockProvider = StreamProvider<DateTime>(
  (ref) => Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
);

/// Current TOTP code of an item (null if no / invalid secret).
final totpCodeProvider = FutureProvider.family<TotpCode?, String>((ref, itemId) async {
  ref.watch(clockProvider);
  final secret = ref.watch(itemByIdProvider(itemId))?.login?.totpSecret;
  if (secret == null) return null;
  final service = ref.watch(totpServiceProvider);
  final config = service.parse(secret);
  if (config == null) return null;
  return service.generate(config);
});

// ---------------------------------------------------------------------------
// Actions (use cases) – UI calls these, never repositories directly.
// ---------------------------------------------------------------------------

class VaultActions {
  VaultActions(this._ref);

  final Ref _ref;

  VaultItem newItem(VaultItemType type) => _ref.read(vaultRepositoryProvider).newItem(type);

  Future<VaultItem> save(VaultItem item) => _ref.read(vaultRepositoryProvider).save(item);

  Future<void> delete(String id) => _ref.read(vaultRepositoryProvider).delete(id);

  Future<void> toggleFavorite(String id) => _ref.read(vaultRepositoryProvider).toggleFavorite(id);

  Future<VaultFolder> createFolder(String name) => _ref.read(vaultRepositoryProvider).saveFolder(name);

  Future<void> renameFolder(String id, String name) =>
      _ref.read(vaultRepositoryProvider).saveFolder(name, id: id);

  Future<void> deleteFolder(String id) => _ref.read(vaultRepositoryProvider).deleteFolder(id);

  Future<AttachmentRef> addAttachment(String name, Uint8List bytes, {String? mimeType}) =>
      _ref.read(vaultRepositoryProvider).addAttachment(name, bytes, mimeType: mimeType);

  Future<Uint8List> readAttachment(String id) => _ref.read(vaultRepositoryProvider).readAttachment(id);

  Future<void> deleteAttachment(String id) => _ref.read(vaultRepositoryProvider).deleteAttachment(id);

  /// Copies a value; secrets are wiped after the configured delay.
  Future<void> copy(String value, {bool secret = true}) => _ref.read(clipboardServiceProvider).copy(
        value,
        clearAfter: secret ? _ref.read(clipboardClearDurationProvider) : null,
      );
}

final vaultActionsProvider = Provider<VaultActions>(VaultActions.new);
