import 'package:flutter/foundation.dart';

import 'item_category.dart';
import 'vault_item_type.dart';

typedef Json = Map<String, dynamic>;

List<T> _list<T>(Object? raw, T Function(Json) parse) =>
    (raw as List<dynamic>? ?? const [])
        .map((e) => parse(e as Json))
        .toList(growable: false);

DateTime? _date(Object? raw) =>
    raw == null ? null : DateTime.fromMillisecondsSinceEpoch(raw as int);

/// A previous password of a login (Passwort-Verlauf).
@immutable
class PasswordHistoryEntry {
  const PasswordHistoryEntry({required this.password, required this.changedAt});

  factory PasswordHistoryEntry.fromJson(Json j) => PasswordHistoryEntry(
        password: j['p'] as String,
        changedAt: _date(j['t'])!,
      );

  final String password;
  final DateTime changedAt;

  Json toJson() => {'p': password, 't': changedAt.millisecondsSinceEpoch};
}

/// User defined extra field (e.g. "PIN", "Seriennummer", "IP-Adresse").
@immutable
class CustomField {
  const CustomField({required this.name, required this.value, this.secret = false});

  factory CustomField.fromJson(Json j) => CustomField(
        name: j['n'] as String? ?? '',
        value: j['v'] as String? ?? '',
        secret: j['s'] as bool? ?? false,
      );

  final String name;
  final String value;
  final bool secret;

  Json toJson() => {'n': name, 'v': value, 's': secret};
}

/// Metadata of an encrypted file attachment (content stored separately).
@immutable
class AttachmentRef {
  const AttachmentRef({
    required this.id,
    required this.name,
    required this.size,
    this.mimeType = 'application/octet-stream',
  });

  factory AttachmentRef.fromJson(Json j) => AttachmentRef(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Datei',
        size: j['size'] as int? ?? 0,
        mimeType: j['mime'] as String? ?? 'application/octet-stream',
      );

  final String id;
  final String name;
  final int size;
  final String mimeType;

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toUpperCase();
  }

  Json toJson() => {'id': id, 'name': name, 'size': size, 'mime': mimeType};
}

/// Fields of a login – also used for devices, HMIs, routers, WLAN, licences.
@immutable
class LoginData {
  const LoginData({
    this.username = '',
    this.password = '',
    this.urls = const [],
    this.totpSecret,
    this.host,
    this.passwordChangedAt,
    this.passwordHistory = const [],
  });

  factory LoginData.fromJson(Json j) => LoginData(
        username: j['user'] as String? ?? '',
        password: j['pass'] as String? ?? '',
        urls: (j['urls'] as List<dynamic>? ?? const []).cast<String>(),
        totpSecret: j['totp'] as String?,
        host: j['host'] as String?,
        passwordChangedAt: _date(j['pwAt']),
        passwordHistory: _list(j['hist'], PasswordHistoryEntry.fromJson),
      );

  final String username;
  final String password;
  final List<String> urls;

  /// Base32 secret or full `otpauth://` URI for 2FA codes.
  final String? totpSecret;

  /// IP address / hostname for devices, HMIs and routers.
  final String? host;
  final DateTime? passwordChangedAt;
  final List<PasswordHistoryEntry> passwordHistory;

  bool get hasTotp => totpSecret != null && totpSecret!.trim().isNotEmpty;
  String? get primaryUrl => urls.isEmpty ? null : urls.first;

  LoginData copyWith({
    String? username,
    String? password,
    List<String>? urls,
    String? totpSecret,
    bool clearTotp = false,
    String? host,
    DateTime? passwordChangedAt,
    List<PasswordHistoryEntry>? passwordHistory,
  }) =>
      LoginData(
        username: username ?? this.username,
        password: password ?? this.password,
        urls: urls ?? this.urls,
        totpSecret: clearTotp ? null : (totpSecret ?? this.totpSecret),
        host: host ?? this.host,
        passwordChangedAt: passwordChangedAt ?? this.passwordChangedAt,
        passwordHistory: passwordHistory ?? this.passwordHistory,
      );

  Json toJson() => {
        'user': username,
        'pass': password,
        'urls': urls,
        if (totpSecret != null) 'totp': totpSecret,
        if (host != null) 'host': host,
        if (passwordChangedAt != null) 'pwAt': passwordChangedAt!.millisecondsSinceEpoch,
        'hist': passwordHistory.map((e) => e.toJson()).toList(),
      };
}

/// Fields of a payment card.
@immutable
class CardData {
  const CardData({
    this.holder = '',
    this.number = '',
    this.expiryMonth,
    this.expiryYear,
    this.cvv = '',
    this.pin = '',
  });

  factory CardData.fromJson(Json j) => CardData(
        holder: j['holder'] as String? ?? '',
        number: j['number'] as String? ?? '',
        expiryMonth: j['expM'] as int?,
        expiryYear: j['expY'] as int?,
        cvv: j['cvv'] as String? ?? '',
        pin: j['pin'] as String? ?? '',
      );

  final String holder;
  final String number;
  final int? expiryMonth;
  final int? expiryYear;
  final String cvv;
  final String pin;

  String get digits => number.replaceAll(RegExp(r'\D'), '');

  String get last4 => digits.length >= 4 ? digits.substring(digits.length - 4) : digits;

  /// Masked number like "•••• 4242".
  String get masked => digits.isEmpty ? '' : '•••• $last4';

  String get expiryLabel => expiryMonth == null || expiryYear == null
      ? ''
      : '${expiryMonth.toString().padLeft(2, '0')}/${(expiryYear! % 100).toString().padLeft(2, '0')}';

  /// Card brand detected from the IIN prefix.
  String get brand {
    final d = digits;
    if (d.startsWith('4')) return 'VISA';
    if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(d)) return 'Mastercard';
    if (RegExp(r'^3[47]').hasMatch(d)) return 'AMEX';
    if (RegExp(r'^(6011|65)').hasMatch(d)) return 'Discover';
    if (d.startsWith('62')) return 'UnionPay';
    if (RegExp(r'^35').hasMatch(d)) return 'JCB';
    return 'Karte';
  }

  bool get isExpired {
    if (expiryMonth == null || expiryYear == null) return false;
    final now = DateTime.now();
    final year = expiryYear! < 100 ? 2000 + expiryYear! : expiryYear!;
    return DateTime(year, expiryMonth! + 1).isBefore(now);
  }

  Json toJson() => {
        'holder': holder,
        'number': number,
        if (expiryMonth != null) 'expM': expiryMonth,
        if (expiryYear != null) 'expY': expiryYear,
        'cvv': cvv,
        'pin': pin,
      };
}

/// Fields of an identity / contract document with optional encrypted files.
@immutable
class DocumentData {
  const DocumentData({
    this.documentType = 'Sonstige',
    this.number = '',
    this.fullName = '',
    this.issuer = '',
    this.issueDate,
    this.expiryDate,
    this.attachments = const [],
  });

  factory DocumentData.fromJson(Json j) => DocumentData(
        documentType: j['type'] as String? ?? 'Sonstige',
        number: j['number'] as String? ?? '',
        fullName: j['name'] as String? ?? '',
        issuer: j['issuer'] as String? ?? '',
        issueDate: _date(j['issued']),
        expiryDate: _date(j['expires']),
        attachments: _list(j['files'], AttachmentRef.fromJson),
      );

  static const types = [
    'Reisepass',
    'Personalausweis',
    'Führerschein',
    'Vertrag',
    'Versicherung',
    'Zeugnis',
    'Sonstige',
  ];

  final String documentType;
  final String number;
  final String fullName;
  final String issuer;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final List<AttachmentRef> attachments;

  int get totalSize => attachments.fold(0, (s, a) => s + a.size);

  DocumentData copyWith({List<AttachmentRef>? attachments}) => DocumentData(
        documentType: documentType,
        number: number,
        fullName: fullName,
        issuer: issuer,
        issueDate: issueDate,
        expiryDate: expiryDate,
        attachments: attachments ?? this.attachments,
      );

  Json toJson() => {
        'type': documentType,
        'number': number,
        'name': fullName,
        'issuer': issuer,
        if (issueDate != null) 'issued': issueDate!.millisecondsSinceEpoch,
        if (expiryDate != null) 'expires': expiryDate!.millisecondsSinceEpoch,
        'files': attachments.map((a) => a.toJson()).toList(),
      };
}

/// A single vault entry. The complete object is serialised to JSON and
/// encrypted with AES-256-GCM before it touches the database.
@immutable
class VaultItem {
  const VaultItem({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
    this.tags = const [],
    this.favorite = false,
    this.notes = '',
    this.login,
    this.card,
    this.document,
    this.customFields = const [],
  });

  factory VaultItem.fromJson(Json j) {
    final type = VaultItemType.fromName(j['type'] as String?);
    return VaultItem(
      id: j['id'] as String,
      type: type,
      title: j['title'] as String? ?? '',
      category: ItemCategory.fromName(j['cat'] as String?),
      folderId: j['folder'] as String?,
      tags: (j['tags'] as List<dynamic>? ?? const []).cast<String>(),
      favorite: j['fav'] as bool? ?? false,
      notes: j['notes'] as String? ?? '',
      login: j['login'] == null ? null : LoginData.fromJson(j['login'] as Json),
      card: j['card'] == null ? null : CardData.fromJson(j['card'] as Json),
      document: j['doc'] == null ? null : DocumentData.fromJson(j['doc'] as Json),
      customFields: _list(j['fields'], CustomField.fromJson),
      createdAt: _date(j['created'])!,
      updatedAt: _date(j['updated'])!,
    );
  }

  final String id;
  final VaultItemType type;
  final String title;
  final ItemCategory category;
  final String? folderId;
  final List<String> tags;
  final bool favorite;
  final String notes;
  final LoginData? login;
  final CardData? card;
  final DocumentData? document;
  final List<CustomField> customFields;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Short secondary text for list tiles.
  String get subtitle => switch (type) {
        VaultItemType.login => login?.username.isNotEmpty == true
            ? login!.username
            : (login?.host ?? login?.primaryUrl ?? ''),
        VaultItemType.card => card?.masked ?? '',
        VaultItemType.document => document?.attachments.isNotEmpty == true
            ? '${document!.attachments.length} Datei(en)'
            : (document?.documentType ?? ''),
        VaultItemType.note => notes.split('\n').first,
      };

  /// Lower-cased text used by the in-memory search.
  String get searchText => [
        title,
        notes,
        category.label,
        ...tags,
        login?.username,
        login?.host,
        ...?login?.urls,
        card?.holder,
        card?.brand,
        document?.documentType,
        document?.number,
        ...customFields.where((f) => !f.secret).map((f) => '${f.name} ${f.value}'),
      ].whereType<String>().join(' ').toLowerCase();

  VaultItem copyWith({
    String? title,
    ItemCategory? category,
    String? folderId,
    bool clearFolder = false,
    List<String>? tags,
    bool? favorite,
    String? notes,
    LoginData? login,
    CardData? card,
    DocumentData? document,
    List<CustomField>? customFields,
    DateTime? updatedAt,
  }) =>
      VaultItem(
        id: id,
        type: type,
        title: title ?? this.title,
        category: category ?? this.category,
        folderId: clearFolder ? null : (folderId ?? this.folderId),
        tags: tags ?? this.tags,
        favorite: favorite ?? this.favorite,
        notes: notes ?? this.notes,
        login: login ?? this.login,
        card: card ?? this.card,
        document: document ?? this.document,
        customFields: customFields ?? this.customFields,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Json toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'cat': category.name,
        if (folderId != null) 'folder': folderId,
        'tags': tags,
        'fav': favorite,
        'notes': notes,
        if (login != null) 'login': login!.toJson(),
        if (card != null) 'card': card!.toJson(),
        if (document != null) 'doc': document!.toJson(),
        'fields': customFields.map((f) => f.toJson()).toList(),
        'created': createdAt.millisecondsSinceEpoch,
        'updated': updatedAt.millisecondsSinceEpoch,
      };
}

/// A user-created folder ("Ordner").
@immutable
class VaultFolder {
  const VaultFolder({required this.id, required this.name, required this.updatedAt});

  factory VaultFolder.fromJson(Json j) => VaultFolder(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        updatedAt: _date(j['updated']) ?? DateTime.now(),
      );

  final String id;
  final String name;
  final DateTime updatedAt;

  Json toJson() => {'id': id, 'name': name, 'updated': updatedAt.millisecondsSinceEpoch};
}
