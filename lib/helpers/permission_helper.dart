import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_feedback.dart';
import 'app_tokens.dart';

/// PermissionHelper — wraps [Permission] requests with a "rationale
/// before ask" flow so users know WHY the OS prompt is appearing.
///
/// Apple's HIG and Google's Material guidelines both recommend
/// showing a rationale dialog the first time. After permanent denial,
/// we offer a "Open settings" button instead of asking again (which
/// the OS would silently ignore).
class PermissionHelper {
  PermissionHelper._();

  /// Request [permission] with a friendly rationale dialog if needed.
  /// Returns true if granted.
  ///
  /// [rationaleTitle] / [rationaleBody] — what the user sees BEFORE
  /// the OS prompt the first time.
  /// [permanentlyDeniedBody] — what the user sees if they previously
  /// denied with "Don't ask again". A "Open settings" button is added.
  static Future<bool> ask(
    BuildContext ctx,
    Permission permission, {
    required String rationaleTitle,
    required String rationaleBody,
    String? permanentlyDeniedBody,
  }) async {
    var status = await permission.status;

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      final goToSettings = await _showRationale(
        ctx,
        title: rationaleTitle,
        body: permanentlyDeniedBody ??
            "$rationaleBody\n\nYou previously denied this. Open settings to enable it.",
        primaryLabel: "Open settings",
      );
      if (goToSettings == true) {
        await openAppSettings();
      }
      return false;
    }

    if (status.isDenied) {
      final shouldAsk = await _showRationale(
        ctx,
        title: rationaleTitle,
        body: rationaleBody,
        primaryLabel: "Continue",
      );
      if (shouldAsk != true) return false;
      status = await permission.request();
      if (!status.isGranted && ctx.mounted) {
        AppFeedback.warning(
          ctx,
          "$rationaleTitle is required to continue.",
        );
      }
    }

    return status.isGranted;
  }

  static Future<bool?> _showRationale(
    BuildContext ctx, {
    required String title,
    required String body,
    required String primaryLabel,
  }) {
    return showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppTokens.surface(dCtx),
        shape: RoundedRectangleBorder(borderRadius: AppTokens.radius16),
        title: Text(title, style: AppTokens.titleLg(dCtx)),
        content: Text(body, style: AppTokens.body(dCtx)),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: Text(
              "Not now",
              style: AppTokens.titleSm(dCtx).copyWith(
                color: AppTokens.ink2(dCtx),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: Text(
              primaryLabel,
              style: AppTokens.titleSm(dCtx).copyWith(
                color: AppTokens.accent(dCtx),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
