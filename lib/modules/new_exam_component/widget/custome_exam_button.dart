// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';

/// Shared CTA box used throughout the exam flows. Redesigned with
/// AppTokens while preserving every public contract:
///   • Constructor `CustomPreviewBox({super.key, required text,
///     required onTap, textColor, borderColor = Colors.grey, bgColor})`
///   • The four parameters retain their original types and default
///     values — callers that pass named args unchanged will compile
///     verbatim.
///   • `onTap` retains `void Function()?` signature (nullable).
///
/// The redesign swaps harsh ThemeManager/Dimensions defaults for
/// AppTokens equivalents, introduces an InkWell ripple (instead of
/// bare GestureDetector) for better feedback on taps, and respects
/// any bgColor/borderColor/textColor the caller forces while still
/// providing tokenised fallbacks.
class CustomPreviewBox extends StatelessWidget {
  const CustomPreviewBox({
    super.key,
    required this.text,
    required this.onTap,
    this.textColor,
    this.borderColor = Colors.grey,
    this.bgColor,
  });

  final String text;
  final Color borderColor;
  final Color? textColor;
  final Color? bgColor;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = bgColor ?? AppTokens.surface(context);
    // Preserve the legacy default: when the caller did not override
    // `borderColor` it arrives as Colors.grey; promote that sentinel
    // to the tokenised border so themed surfaces render cleanly.
    final effectiveBorder =
        borderColor == Colors.grey ? AppTokens.border(context) : borderColor;
    final effectiveText = textColor ?? AppTokens.ink(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: effectiveBg,
            border: Border.all(color: effectiveBorder),
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
          child: Center(
            child: Text(
              text,
              style: AppTokens.bodyLg(context).copyWith(
                fontWeight: FontWeight.w700,
                color: effectiveText,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
