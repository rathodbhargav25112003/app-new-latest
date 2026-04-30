// ════════════════════════════════════════════════════════════════════
// AppLockService — boot-time gate orchestrator
// ════════════════════════════════════════════════════════════════════
//
// One method to call from the splash flow:
//
//   final ok = await AppLockService().runBootGate(context);
//   if (!ok) Navigator.pushReplacementNamed(context, Routes.login);
//
// Internal logic:
//   1. If biometric is opted-in AND device supports it, prompt.
//      • success → return true
//      • failure / cancel → fall through to PIN
//   2. If a PIN is set, push PinEntryScreen.
//      • success → return true
//      • backed-out → return false
//   3. Neither configured → return true (no gate).
//
// The boot screen calls this AFTER the JWT-validity check so users
// without auth go straight to login regardless.

import 'package:flutter/material.dart';
import '../modules/login/pin_entry_screen.dart';
import 'biometric_auth_service.dart';
import 'pin_lock_service.dart';

class AppLockService {
  static final AppLockService _instance = AppLockService._();
  AppLockService._();
  factory AppLockService() => _instance;

  /// Returns true when the student passed the gate (or no gate
  /// configured). Returns false when they backed out without
  /// unlocking — caller should bounce them to login.
  Future<bool> runBootGate(BuildContext context) async {
    final bio = BiometricAuthService();
    final pin = PinLockService();

    final bioGate = await bio.shouldGate();
    final pinSet = await pin.isSet();

    // Nothing configured → no gate.
    if (!bioGate && !pinSet) return true;

    if (bioGate) {
      final ok = await bio.authenticate(reason: 'Unlock Sushruta');
      if (ok) return true;
      // Biometric failed — fall through to PIN if available.
      if (!pinSet) return false;
    }

    if (pinSet && context.mounted) {
      final ok = await Navigator.of(context).push<bool>(
        PinEntryScreen.route(),
      );
      return ok == true;
    }

    return false;
  }

  /// Convenience for the post-login "want biometric next time?" prompt.
  /// Shows a soft Apple-style dialog the first time we detect the
  /// device supports biometrics AND the student hasn't opted in yet.
  Future<void> maybeOfferBiometric(BuildContext context) async {
    final bio = BiometricAuthService();
    if (!await bio.isAvailable()) return;
    if (await bio.isEnabled()) return;
    if (!context.mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Use biometrics next time?'),
        content: const Text(
          'Unlock Sushruta with Face ID, Touch ID, or fingerprint instead of typing your password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
    if (result == true) {
      // Verify once before storing the opt-in so we know the
      // hardware actually responds for this user.
      final ok = await bio.authenticate(reason: 'Confirm to enable biometrics');
      if (ok) await bio.setEnabled(true);
    }
  }

  /// Same idea but for the PIN. Show after biometric is declined OR
  /// alongside the biometric prompt. Pushes a small "Set 4-digit PIN"
  /// screen so the student can opt in. We don't ship the setup UI
  /// here to avoid coupling — the integrator can call
  /// `Navigator.pushNamed(context, Routes.setPin)` to a screen they
  /// own, and that screen ultimately calls `PinLockService().setPin()`.
}
