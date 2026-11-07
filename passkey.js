// G04Passwort – Face ID / Fingerabdruck in der Web-App über Passkeys.
//
// Uses WebAuthn with the PRF extension: the passkey (stored in the device's
// keychain, e.g. iCloud-Schlüsselbund) returns a secret that only appears
// after a successful Face ID / fingerprint check. The Dart side uses that
// secret to encrypt the vault key locally. Nothing is sent to any server.
//
// All functions resolve to a JSON string and never reject, so the Dart side
// gets a clear error code instead of a raw JavaScript exception.
//
// IMPORTANT: create() and get() must be called synchronously inside a user
// gesture (tap). Do not await anything before navigator.credentials.*.
//
// © 2026 PaulFV · Alle Rechte vorbehalten
(function () {
  'use strict';

  // Constant PRF input. The browser hashes it with the context string
  // "WebAuthn PRF\0"; the output is unique per passkey.
  var SALT = new TextEncoder().encode('g04passwort/prf/v1');

  function b64(buf) {
    var bytes = new Uint8Array(buf);
    var s = '';
    for (var i = 0; i < bytes.length; i++) s += String.fromCharCode(bytes[i]);
    return btoa(s);
  }

  function unb64(s) {
    var bin = atob(s);
    var out = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
    return out;
  }

  function random(n) {
    return crypto.getRandomValues(new Uint8Array(n));
  }

  function fail(e) {
    var name = (e && e.name) || 'Error';
    var code = 'error';
    if (name === 'NotAllowedError' || name === 'AbortError') code = 'cancelled';
    else if (name === 'InvalidStateError') code = 'exists';
    else if (name === 'NotSupportedError') code = 'unsupported';
    else if (name === 'SecurityError') code = 'insecure';
    return JSON.stringify({
      ok: false,
      error: code,
      message: name + ': ' + ((e && e.message) || String(e)),
    });
  }

  function supported() {
    return !!(window.PublicKeyCredential && navigator.credentials &&
      window.isSecureContext);
  }

  function prfOf(cred) {
    var ext = (cred.getClientExtensionResults && cred.getClientExtensionResults()) || {};
    var prf = ext.prf || {};
    var first = prf.results && prf.results.first;
    return {
      enabled: prf.enabled === undefined ? null : !!prf.enabled,
      secret: first ? b64(first) : null,
    };
  }

  window.g04Passkey = {
    available: function () {
      if (!supported()) {
        return Promise.resolve(JSON.stringify({ ok: true, platform: false, prf: false }));
      }
      var caps = PublicKeyCredential.getClientCapabilities
        ? PublicKeyCredential.getClientCapabilities().catch(function () { return {}; })
        : Promise.resolve({});
      var uv = PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable
        ? PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable().catch(function () { return false; })
        : Promise.resolve(false);
      return Promise.all([uv, caps]).then(function (r) {
        var prf = r[1] && r[1]['extension:prf'];
        return JSON.stringify({
          ok: true,
          platform: !!r[0],
          prf: prf === undefined ? null : !!prf,
        });
      });
    },

    // Registers a new passkey and tries to read the PRF secret right away.
    create: function () {
      try {
        if (!supported()) throw { name: 'NotSupportedError', message: 'WebAuthn fehlt' };
        return navigator.credentials.create({
          publicKey: {
            rp: { name: 'G04Passwort' },
            user: {
              id: random(16),
              name: 'G04Passwort Tresor',
              displayName: 'G04Passwort Tresor',
            },
            challenge: random(32),
            pubKeyCredParams: [
              { type: 'public-key', alg: -7 },
              { type: 'public-key', alg: -257 },
            ],
            authenticatorSelection: {
              authenticatorAttachment: 'platform',
              residentKey: 'required',
              requireResidentKey: true,
              userVerification: 'required',
            },
            attestation: 'none',
            timeout: 120000,
            extensions: { prf: { eval: { first: SALT } } },
          },
        }).then(function (cred) {
          var prf = prfOf(cred);
          return JSON.stringify({
            ok: true,
            id: b64(cred.rawId),
            prfEnabled: prf.enabled,
            secret: prf.secret,
          });
        }, fail);
      } catch (e) {
        return Promise.resolve(fail(e));
      }
    },

    // Face ID / fingerprint check with the passkey [id]; returns the secret.
    get: function (id) {
      try {
        if (!supported()) throw { name: 'NotSupportedError', message: 'WebAuthn fehlt' };
        var options = {
          challenge: random(32),
          userVerification: 'required',
          timeout: 120000,
          extensions: { prf: { eval: { first: SALT } } },
        };
        if (id) {
          options.allowCredentials = [
            { type: 'public-key', id: unb64(id), transports: ['internal', 'hybrid'] },
          ];
        }
        return navigator.credentials.get({ publicKey: options }).then(function (cred) {
          var prf = prfOf(cred);
          if (!prf.secret) {
            return JSON.stringify({ ok: false, error: 'noprf', message: 'PRF nicht unterstützt' });
          }
          return JSON.stringify({ ok: true, id: b64(cred.rawId), secret: prf.secret });
        }, fail);
      } catch (e) {
        return Promise.resolve(fail(e));
      }
    },
  };
})();
