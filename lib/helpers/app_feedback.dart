import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';
import 'haptics.dart';

/// AppFeedback — centralized SnackBar / toast surface.
///
/// Use this instead of building per-screen [SnackBar] decorations. It
/// wraps every notification in the AppTokens vocabulary (radius12,
/// floating behaviour, semantic colour) and fires the matching
/// [HapticFeedback] for the severity tier. The same call site works
/// across light + dark themes because the colours are token-aware.
///
/// Usage:
/// ```dart
/// AppFeedback.success(context, 'Profile updated');
/// AppFeedback.error(context, 'Could not save');
/// AppFeedback.info(context, 'Reconnected');
/// ```
class AppFeedback {
  AppFeedback._();

  /// Green success bar — light haptic.
  static void success(BuildContext ctx, String msg, {Duration? duration}) {
    Haptics.success();
    _show(
      ctx,
      msg,
      AppTokens.success(ctx),
      icon: Icons.check_circle_rounded,
      duration: duration,
    );
  }

  /// Red destructive bar — heavy haptic.
  static void error(BuildContext ctx, String msg, {Duration? duration}) {
    Haptics.error();
    _show(
      ctx,
      msg,
      AppTokens.danger(ctx),
      icon: Icons.error_outline_rounded,
      duration: duration,
    );
  }

  /// Neutral info bar — light haptic.
  static void info(BuildContext ctx, String msg, {Duration? duration}) {
    Haptics.light();
    _show(
      ctx,
      msg,
      AppTokens.ink(ctx),
      icon: Icons.info_outline_rounded,
      duration: duration,
    );
  }

  /// Warning amber bar — medium haptic.
  static void warning(BuildContext ctx, String msg, {Duration? duration}) {
    Haptics.medium();
    _show(
      ctx,
      msg,
      AppTokens.warning(ctx),
      icon: Icons.warning_amber_rounded,
      duration: duration,
    );
  }

  static void _show(
    BuildContext ctx,
    String msg,
    Color bg, {
    IconData? icon,
    Duration? duration,
  }) {
    // Defensive: messenger may be null during transitions.
    final messenger = ScaffoldMessenger.maybeOf(ctx);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(
          AppTokens.s16,
          0,
          AppTokens.s16,
          AppTokens.s16,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppTokens.radius12),
        elevation: 4,
        duration: duration ?? const Duration(seconds: 3),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: AppTokens.s8),
            ],
            Expanded(
              child: Text(
                msg,
                style: AppTokens.body(ctx).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
