const _unsupported = <String, Object?>{'ok': false, 'error': 'unsupported'};

Future<Map<String, Object?>> available() async => const {
  'ok': true,
  'platform': false,
  'prf': false,
};

Future<Map<String, Object?>> create() async => _unsupported;

Future<Map<String, Object?>> get(String? credentialId) async => _unsupported;
