// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';

/// Exit-confirmation dialog shown from the quiz exam flow when the
/// user taps back or the cancel button. Answering "Yes" cancels the
/// quiz timer, disposes the remaining-time notifier, and routes to
/// `Routes.quizScreen`; "No" just pops with `false`.
///
/// Preserved public contract:
///   • Three-positional-arg constructor
///     `CustomQuizTestCancelDialogBox(this.timer, this.remainingTimeNotifier, this.isPracticeMode)`
///     with the two optional nullable fields preserved.
///   • Cancel behaviour preserved: `widget.timer?.cancel()` +
///     `widget.remainingTimeNotifier?.dispose()` then
///     `Navigator.of(context).pushNamed(Routes.quizScreen)`.
///   • Navigator.pop(context, false) on "No" preserved.
///   • Prompt text preserved: `'Do you want to exit the exam? '`.
class CustomQuizTestCancelDialogBox extends StatefulWidget {
  final Timer timer;
  final ValueNotifier<Duration>? remainingTimeNotifier;
  final bool? isPracticeMode;
  const CustomQuizTestCancelDialogBox(
    this.timer,
    this.remainingTimeNotifier,
    this.isPracticeMode, {
    super.key,
  });

  @override
  State<CustomQuizTestCancelDialogBox> createState() =>
      _CustomQuizTestCancelDialogBoxState();
}

class _CustomQuizTestCancelDialogBoxState
    extends State<CustomQuizTestCancelDialogBox> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTokens.surface(context),
      surfaceTintColor: AppTokens.surface(context),
      contentPadding: const EdgeInsets.only(
        top: AppTokens.s24,
        left: AppTokens.s24,
        right: AppTokens.s24,
        bottom: AppTokens.s16,
      ),
      alignment: Alignment.center,
      actionsPadding: const EdgeInsets.only(
        left: AppTokens.s20,
        right: AppTokens.s20,
        bottom: AppTokens.s24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.r16),
      ),
      content: Text(
        'Do you want to exit the exam? ',
        style: AppTokens.titleSm(context).copyWith(
          fontWeight: FontWeight.w600,
          color: AppTokens.ink(context),
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => Navigator.pop(context, false),
                borderRadius: BorderRadius.circular(AppTokens.r12),
                child: Container(
                  height: AppTokens.s32 + AppTokens.s16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTokens.brand, AppTokens.brand2],
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                    boxShadow: AppTokens.shadow1(context),
                  ),
                  child: Text(
                    'No',
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: InkWell(
                onTap: () {
                  widget.timer.cancel();
                  widget.remainingTimeNotifier?.dispose();
                  Navigator.of(context).pushNamed(Routes.quizScreen);
                },
                borderRadius: BorderRadius.circular(AppTokens.r12),
                child: Container(
                  height: AppTokens.s32 + AppTokens.s16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                    border: Border.all(color: AppColors.primaryColor),
                    color: AppTokens.surface(context),
                  ),
                  child: Text(
                    'Yes',
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
