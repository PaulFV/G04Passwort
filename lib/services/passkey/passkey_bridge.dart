import 'passkey_bridge_stub.dart'
    if (dart.library.js_interop) 'passkey_bridge_web.dart'
    as impl;

/// Low level access to WebAuthn passkeys in the browser (web/passkey.js).
///
/// Every call returns the decoded JSON answer of the JavaScript side, e.g.
/// `{ok: true, id: ..., secret: ...}` or `{ok: false, error: 'cancelled'}`.
/// On non-web platforms all calls answer `{ok: false, error: 'unsupported'}`.
///
/// [create] and [get] must be started synchronously from a tap handler –
/// browsers only allow passkey prompts during a user gesture.
abstract final class PasskeyBridge {
  static Future<Map<String, Object?>> available() => impl.available();

  static Future<Map<String, Object?>> create() => impl.create();

  static Future<Map<String, Object?>> get(String? credentialId) =>
      impl.get(credentialId);
}
