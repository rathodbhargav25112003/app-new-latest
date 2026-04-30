import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'app_feedback.dart';
import 'haptics.dart';

/// ShareHelpers — universal share-sheet wrapper.
///
/// All share invocations should go through this so we have a single
/// place to update copy templates, append app branding, and graceful-
/// fallback to clipboard when no share intent is available.
///
/// Three shapes you'll typically use:
///  • [shareQuestion] — share a single MCQ + 4 options (no answer).
///  • [shareQuestionWithSolution] — same but includes the right answer
///    and explanation. Used from solution screens.
///  • [shareStreak] — "I'm on a 7-day streak on Sushruta LGS! 🔥".
///  • [shareApp] — generic app-share with download link.
class ShareHelpers {
  ShareHelpers._();

  /// Marketing tag appended to every share. Override here when the
  /// app moves to play store / iOS app store.
  static const _appTag =
      "\n\n— Sushruta LGS · NEET SS prep companion\nhttps://sushrutalgs.com/app";

  /// Share a question's prompt + options — no answer reveal.
  static Future<void> shareQuestion(
    BuildContext ctx, {
    required String questionText,
    required List<String> optionLabels,
  }) async {
    Haptics.light();
    final body = StringBuffer()
      ..writeln(_stripHtml(questionText))
      ..writeln();
    for (var i = 0; i < optionLabels.length; i++) {
      body.writeln('${String.fromCharCode(65 + i)}. ${_stripHtml(optionLabels[i])}');
    }
    body.write(_appTag);
    await _shareOrCopy(ctx, body.toString(),
        subject: 'NEET SS practice question');
  }

  /// Share a question + correct answer + (optional) explanation.
  static Future<void> shareQuestionWithSolution(
    BuildContext ctx, {
    required String questionText,
    required List<String> optionLabels,
    required int correctIndex,
    String? explanation,
  }) async {
    Haptics.light();
    final body = StringBuffer()
      ..writeln(_stripHtml(questionText))
      ..writeln();
    for (var i = 0; i < optionLabels.length; i++) {
      final mark = i == correctIndex ? '✓' : ' ';
      body.writeln(
          '$mark ${String.fromCharCode(65 + i)}. ${_stripHtml(optionLabels[i])}');
    }
    body.writeln('\nCorrect answer: ${String.fromCharCode(65 + correctIndex)}');
    if (explanation != null && explanation.trim().isNotEmpty) {
      body.writeln('\n${_stripHtml(explanation)}');
    }
    body.write(_appTag);
    await _shareOrCopy(ctx, body.toString(),
        subject: 'NEET SS solution explainer');
  }

  /// Share user's streak (for social proof + retention).
  static Future<void> shareStreak(BuildContext ctx, {required int streak}) async {
    Haptics.light();
    final fire = streak >= 30 ? '🔥🔥🔥' : streak >= 7 ? '🔥🔥' : '🔥';
    final text =
        "I'm on a $streak-day streak in NEET SS prep on Sushruta LGS $fire"
        "$_appTag";
    await _shareOrCopy(ctx, text, subject: 'My NEET SS streak');
  }

  /// Share the app generically.
  static Future<void> shareApp(BuildContext ctx) async {
    Haptics.light();
    const text = "Studying for NEET SS? Check out Sushruta LGS — "
        "videos, notes, mock exams, and AI doubt-solver in one app.\n\n"
        "https://sushrutalgs.com/app";
    await _shareOrCopy(ctx, text, subject: 'Sushruta LGS');
  }

  /// Share a labelled URL (e.g. a PDF link from the reader).
  /// Composes "{text}\n{url}" → system share.
  static Future<void> openUrlAsLink(
    BuildContext ctx, {
    required String text,
    required String url,
  }) async {
    Haptics.light();
    final body = "$text\n$url$_appTag";
    await _shareOrCopy(ctx, body, subject: text);
  }

  // ─────────────────────────────────────────────────────────────────

  static Future<void> _shareOrCopy(
    BuildContext ctx,
    String text, {
    String? subject,
  }) async {
    try {
      await Share.share(text, subject: subject);
    } catch (_) {
      // Some surfaces (desktop, certain Android variants) don't have
      // a system share intent. Fall back to clipboard.
      try {
        await Clipboard.setData(ClipboardData(text: text));
        if (ctx.mounted) {
          AppFeedback.success(ctx, "Copied to clipboard");
        }
      } catch (_) {
        if (ctx.mounted) {
          AppFeedback.error(ctx, "Couldn't share. Try again later.");
        }
      }
    }
  }

  /// Crude HTML-tag stripper. We render question text via
  /// [Html] in the UI, but for a plain-text share we want to surface
  /// just the words. Image alt-text is dropped.
  static String _stripHtml(String input) {
    if (input.isEmpty) return input;
    return input
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
