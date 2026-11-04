import 'dart:convert';
import 'dart:js_interop';

@JS('g04Passkey')
external _G04Passkey? get _passkey;

extension type _G04Passkey(JSObject _) implements JSObject {
  external JSPromise<JSString> available();
  external JSPromise<JSString> create();
  external JSPromise<JSString> get(JSString? id);
}

const _missing = <String, Object?>{
  'ok': false,
  'error': 'unsupported',
  'message': 'passkey.js nicht geladen',
};

Map<String, Object?> _decode(JSString s) =>
    (jsonDecode(s.toDart) as Map).cast<String, Object?>();

Future<Map<String, Object?>> _run(JSPromise<JSString> Function(_G04Passkey p) call) async {
  final p = _passkey;
  if (p == null) return _missing;
  try {
    // `call` starts the browser prompt synchronously (user gesture).
    return _decode(await call(p).toDart);
  } on Object catch (e) {
    return {'ok': false, 'error': 'error', 'message': '$e'};
  }
}

Future<Map<String, Object?>> available() => _run((p) => p.available());

Future<Map<String, Object?>> create() => _run((p) => p.create());

Future<Map<String, Object?>> get(String? credentialId) =>
    _run((p) => p.get(credentialId?.toJS));
