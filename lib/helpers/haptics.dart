import 'package:flutter/services.dart';

/// Haptics — single entry point for all haptic feedback in the app.
///
/// Centralizing here means we can:
///  • Throttle haptics globally if needed (avoid back-to-back triggers).
///  • Toggle off in settings (e.g. user preference, low-power mode).
///  • Pick the right intensity for the action without scattering
///    `HapticFeedback.*` calls everywhere.
///
/// Intensity guide:
///  • [selection]  — tab change, chip toggle, segmented control switch
///  • [light]      — minor confirm, info banner, snack open
///  • [medium]     — primary CTA tap, bookmark on/off, option select
///  • [heavy]      — destructive confirm, error, hard-fail
///  • [success]    — successful save, completion, streak +1
///  • [error]      — validation fail, network error
class Haptics {
  Haptics._();

  static bool _enabled = true;

  /// Disable all haptics (e.g. via Settings toggle). Default: enabled.
  static set enabled(bool v) => _enabled = v;
  static bool get enabled => _enabled;

  static void selection() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  static void light() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  static void medium() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Short-tap, equivalent to [light] today but kept as a separate
  /// intent so future versions can swap to a dual-tick on iOS.
  static void success() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Heavy tap, equivalent to [heavy] today but kept as a separate
  /// intent for future expansion.
  static void error() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }
}
