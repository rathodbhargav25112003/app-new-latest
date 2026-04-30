// ════════════════════════════════════════════════════════════════════
// JailbreakGuard — root / jailbreak detection
// ════════════════════════════════════════════════════════════════════
//
// Wraps `flutter_jailbreak_detection` with two product-shaped helpers:
//
//   • `isCompromised()` — fire-and-forget bool check
//   • `runWithBanner(context)` — shows a soft persistent banner at
//     the top of the home shell when the device is rooted. We do NOT
//     hard-block: jailbroken users are real users (medical PG
//     aspirants on enthusiast Android devices); we just flag them so
//     paid subscribers get a nudge to use a clean device for exam-
//     mode mocks where screen-recording matters.
//
// Stored result is cached for the session — re-detection on every
// route push is wasteful.

import 'package:flutter/material.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class JailbreakGuard {
  static final JailbreakGuard _instance = JailbreakGuard._();
  JailbreakGuard._();
  factory JailbreakGuard() => _instance;

  bool? _cachedResult;

  /// True when the platform reports the device is rooted (Android) or
  /// jailbroken (iOS). Cached for the lifetime of the app session.
  Future<bool> isCompromised() async {
    if (_cachedResult != null) return _cachedResult!;
    try {
      final v = await FlutterJailbreakDetection.jailbroken;
      _cachedResult = v;
      return v;
    } catch (_) {
      _cachedResult = false;
      return false;
    }
  }

  /// Whether the device is in developer mode (Android only). Some
  /// banks count this as compromise; we don't, but the flag is
  /// useful for analytics tagging.
  Future<bool> isDevMode() async {
    try {
      return await FlutterJailbreakDetection.developerMode;
    } catch (_) { return false; }
  }

  /// Returns a small banner widget to drop above the home scaffold
  /// when the device is compromised. Returns SizedBox.shrink() when
  /// the device is clean — caller doesn't need to branch.
  Widget banner(BuildContext context) {
    return FutureBuilder<bool>(
      future: isCompromised(),
      builder: (ctx, snap) {
        if (!(snap.data ?? false)) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.error.withOpacity(0.20)),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: scheme.error),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Device security check failed. Mock-attempt screen recording may be blocked on this device.",
                  style: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
