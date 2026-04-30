// ════════════════════════════════════════════════════════════════════
// PinLockService — 4-digit PIN + lockout state
// ════════════════════════════════════════════════════════════════════
//
// Two responsibilities packaged together because they share the same
// secure-storage backing:
//
//   1. PIN gate    — for users who decline biometric, a 4-digit PIN
//                    stored hashed in flutter_secure_storage acts as
//                    the secondary app-open lock. (Reasonable parity
//                    with banking apps that always offer a PIN.)
//
//   2. Lockout     — counter-based brute-force shield. After 5 wrong
//                    PINs the app self-locks for 5 min. After 10 it
//                    nukes the PIN entirely and forces a re-login
//                    via OTP. Same idiom as iOS's "10 wrong attempts
//                    erases the device" but soft (logs out, doesn't
//                    erase content).
//
// Hashing is SHA-256 with a random per-install salt also kept in
// secure storage. This is NOT a crypto-grade KDF — the PIN is a
// convenience layer; the real auth is the JWT. We just don't want a
// device-rooting attacker to read the PIN in plain.

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinLockService {
  static final PinLockService _instance = PinLockService._();
  PinLockService._();
  factory PinLockService() => _instance;

  static const _storage = FlutterSecureStorage();
  static const _kPin = 'app_pin_hash';
  static const _kSalt = 'app_pin_salt';
  static const _kFails = 'app_pin_fails';
  static const _kLockUntil = 'app_pin_lock_until';

  /// Has the student set a PIN? Returns false on first run.
  Future<bool> isSet() async {
    final pin = await _storage.read(key: _kPin);
    return pin != null && pin.isNotEmpty;
  }

  /// Set / replace the PIN. Hashes with a fresh random salt.
  Future<void> setPin(String pin) async {
    if (pin.length < 4 || pin.length > 8) {
      throw ArgumentError('PIN must be 4–8 digits');
    }
    final salt = _randomSalt();
    final hash = _hash(pin, salt);
    await _storage.write(key: _kSalt, value: salt);
    await _storage.write(key: _kPin, value: hash);
    await _resetFails();
  }

  /// Clear stored PIN — used when the student logs out + opts to
  /// remove the lock OR when 10 wrong attempts force re-login.
  Future<void> clear() async {
    await _storage.delete(key: _kPin);
    await _storage.delete(key: _kSalt);
    await _resetFails();
  }

  /// Returns:
  ///   { valid: true }                            → unlock OK
  ///   { valid: false, lockedSeconds: int }       → wrong AND now locked
  ///   { valid: false, lockedSeconds: 0 }         → wrong, not yet locked
  ///   { valid: false, requiresLogin: true }      → 10 wrong → cleared
  Future<Map<String, dynamic>> verify(String pin) async {
    final until = await _readLockUntil();
    if (until != null && until.isAfter(DateTime.now())) {
      return {
        'valid': false,
        'lockedSeconds': until.difference(DateTime.now()).inSeconds,
      };
    }
    final salt = await _storage.read(key: _kSalt);
    final stored = await _storage.read(key: _kPin);
    if (salt == null || stored == null) {
      return {'valid': false, 'lockedSeconds': 0};
    }
    final hash = _hash(pin, salt);
    if (hash == stored) {
      await _resetFails();
      return {'valid': true};
    }
    final fails = await _bumpFails();
    if (fails >= 10) {
      // Hard reset — require fresh login.
      await clear();
      return {'valid': false, 'requiresLogin': true};
    }
    if (fails >= 5) {
      final lockUntil = DateTime.now().add(const Duration(minutes: 5));
      await _storage.write(
        key: _kLockUntil,
        value: lockUntil.toIso8601String(),
      );
      return {
        'valid': false,
        'lockedSeconds': 300,
      };
    }
    return {'valid': false, 'lockedSeconds': 0, 'remaining': 5 - fails};
  }

  // ─── Internal helpers ─────────────────────────────────────────

  String _hash(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  String _randomSalt() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64Url.encode(bytes);
  }

  Future<int> _bumpFails() async {
    final v = int.tryParse(await _storage.read(key: _kFails) ?? '0') ?? 0;
    final next = v + 1;
    await _storage.write(key: _kFails, value: '$next');
    return next;
  }

  Future<void> _resetFails() async {
    await _storage.delete(key: _kFails);
    await _storage.delete(key: _kLockUntil);
  }

  Future<DateTime?> _readLockUntil() async {
    final s = await _storage.read(key: _kLockUntil);
    if (s == null) return null;
    return DateTime.tryParse(s);
  }
}
