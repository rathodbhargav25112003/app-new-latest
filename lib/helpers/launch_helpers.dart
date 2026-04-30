import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_feedback.dart';

/// LaunchHelpers — centralized URL / email / WhatsApp / phone launchers.
///
/// Replaces 7+ scattered copies of `_launchURL` / `_launchEmail` /
/// `_launchWhatsApp` across the codebase. Each call:
///  • Uses [launchUrl] (the modern, non-deprecated API).
///  • Selects the right [LaunchMode] for the platform.
///  • Surfaces a friendly error via [AppFeedback] when the system can't
///    handle the URL.
class LaunchHelpers {
  LaunchHelpers._();

  /// Open an arbitrary URL in an external browser. Returns false if
  /// the platform can't launch it.
  static Future<bool> openUrl(BuildContext ctx, String url) async {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && ctx.mounted) {
        AppFeedback.error(ctx, "Couldn’t open the link.");
      }
      return ok;
    } catch (_) {
      if (ctx.mounted) {
        AppFeedback.error(ctx, "Couldn’t open the link.");
      }
      return false;
    }
  }

  /// Open the system mail composer prefilled with [email] and optional
  /// subject/body. Falls back to a friendly error if no mail app.
  static Future<bool> openEmail(
    BuildContext ctx,
    String email, {
    String? subject,
    String? body,
  }) async {
    if (email.isEmpty) return false;
    final params = <String, String>{};
    if (subject != null) params['subject'] = subject;
    if (body != null) params['body'] = body;
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: params.isEmpty
          ? null
          : params.entries
              .map((e) =>
                  '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
              .join('&'),
    );
    try {
      final ok = await launchUrl(uri);
      if (!ok && ctx.mounted) {
        AppFeedback.error(ctx, "No email app available.");
      }
      return ok;
    } catch (_) {
      if (ctx.mounted) {
        AppFeedback.error(ctx, "No email app available.");
      }
      return false;
    }
  }

  /// Open WhatsApp chat with [phone] (10-digit Indian number, no
  /// country code — we prepend "91"). Optional [message] gets URL-
  /// encoded as a prefilled draft.
  static Future<bool> openWhatsApp(
    BuildContext ctx,
    String phone, {
    String? message,
  }) async {
    if (phone.isEmpty) return false;
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.https(
      'wa.me',
      '/91$cleaned',
      message == null ? null : {'text': message},
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && ctx.mounted) {
        AppFeedback.error(ctx, "WhatsApp isn't installed.");
      }
      return ok;
    } catch (_) {
      if (ctx.mounted) {
        AppFeedback.error(ctx, "WhatsApp isn't installed.");
      }
      return false;
    }
  }

  /// Open the system dialer with [phone] prefilled.
  static Future<bool> openTel(BuildContext ctx, String phone) async {
    if (phone.isEmpty) return false;
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      final ok = await launchUrl(uri);
      if (!ok && ctx.mounted) {
        AppFeedback.error(ctx, "Couldn’t open dialer.");
      }
      return ok;
    } catch (_) {
      if (ctx.mounted) {
        AppFeedback.error(ctx, "Couldn’t open dialer.");
      }
      return false;
    }
  }
}
