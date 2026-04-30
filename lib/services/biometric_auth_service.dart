// ════════════════════════════════════════════════════════════════════
// BiometricAuthService — Face ID / Touch ID / Android fingerprint
// ════════════════════════════════════════════════════════════════════
//
// Wraps the `local_auth` plugin into a single small surface used by
// app-open lock + (optionally) sensitive-action gates (e.g. revoke
// session).
//
// Lifecycle from the student's POV:
//   1. After first successful login, prompt: "Use Face ID next time?"
//   2. If Yes → store `biometric_enabled = true` in
//      flutter_secure_storage.
//   3. On every subsequent cold-boot, if `biometric_enabled == true`
//      AND device supports biometrics → prompt before letting the
//      user into the dashboard. PIN fallback handled by
//      AppLockService.
//
// We deliberately store NO credentials with biometric — the existing
// JWT in SharedPreferences continues to be the auth token. Biometric
// is a *gate* not a *credential*.

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._();
  BiometricAuthService._();
  factory BiometricAuthService() => _instance;

  final LocalAuthentication _auth = LocalAuthentication();
  static const _kEnabledKey = 'biometric_enabled';
  static const _storage = FlutterSecureStorage();

  /// Whether the OS reports biometric hardware + an enrolled fingerprint
  /// or face. Doesn't tell us if the user has opted in.
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// True when the user has opted in via `setEnabled(true)`.
  Future<bool> isEnabled() async {
    final v = await _storage.read(key: _kEnabledKey);
    return v == 'true';
  }

  /// Toggle the opt-in flag. Pair with the post-login prompt.
  Future<void> setEnabled(bool enabled) async {
    await _storage.write(key: _kEnabledKey, value: enabled ? 'true' : 'false');
  }

  /// Trigger the OS biometric prompt. Returns true on success, false
  /// on cancel / error / not-supported. Always falls back gracefully —
  /// caller decides whether to route to the PIN screen or the login
  /// screen on `false`.
  Future<bool> authenticate({
    String reason = 'Confirm to continue',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      // notAvailable / passcodeNotSet / lockedOut / permanentlyLockedOut
      // all surface here. Caller can decide to fall back.
      if (e.code == auth_error.notAvailable
          || e.code == auth_error.notEnrolled
          || e.code == auth_error.passcodeNotSet) {
        return false;
      }
      return false;
    }
  }

  /// One-stop "should we even try biometric on this cold-boot?" check.
  /// Returns true only if hardware exists AND user opted in.
  Future<bool> shouldGate() async {
    if (!await isAvailable()) return false;
    return isEnabled();
  }
}
