// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';

/// Global loading overlay used throughout the exam flows.
///
/// Preserved public contract:
///   • Top-level `showLoadingDialog(BuildContext context)` returns
///     `Future<dynamic>` — identical signature and return type.
///   • Uses `showDialog` with `barrierDismissible: false` so callers
///     can rely on it staying up until a `Navigator.pop` fires.
///   • Still renders `assets/image/loading.json` via Lottie.
///
/// The redesign swaps hard-coded white/8-radius for themed surface +
/// AppTokens.r12, adds a soft drop shadow, and lifts the box to 84px
/// so the Lottie reads comfortably on higher-DPI devices.
Future<dynamic> showLoadingDialog(BuildContext context) {
  return showDialog(
    barrierColor: Colors.black.withOpacity(0.2),
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Center(
      child: Container(
        clipBehavior: Clip.hardEdge,
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: AppTokens.surface(ctx),
          borderRadius: BorderRadius.circular(AppTokens.r16),
          boxShadow: AppTokens.shadow2(ctx),
          border: Border.all(color: AppTokens.border(ctx)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Lottie.asset('assets/image/loading.json'),
        ),
      ),
    ),
  );
}
