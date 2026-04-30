import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';

// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import, unnecessary_import
import 'package:flutter/cupertino.dart';
// ignore: unused_import
import 'package:shusruta_lms/helpers/colors.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import
import '../../helpers/styles.dart';

/// CustomUserTestCancelDialogBox — confirmation shown when a learner tries
/// to leave a custom test / practice session mid-flight. Public surface
/// preserved exactly:
///   • const constructor with positional args
///     `(Timer? timer, ValueNotifier of Duration remainingTimeNotifier,
///       bool? isPracticeMode, {Key? key})`
///   • `No` → `Navigator.pop(context, false)`
///   • `Yes` → cancels timer, disposes remainingTimeNotifier, routes to
///     [Routes.testCategory]
///
/// Copy switches between "Do you want to end the practice?" and
/// "Do you want to exit the exam?" based on [isPracticeMode].
class CustomUserTestCancelDialogBox extends StatefulWidget {
  final Timer? timer;
  final ValueNotifier<Duration>? remainingTimeNotifier;
  final bool? isPracticeMode;
  // ignore: use_super_parameters
  const CustomUserTestCancelDialogBox(
      this.timer, this.remainingTimeNotifier, this.isPracticeMode,
      {Key? key})
      : super(key: key);

  @override
  State<CustomUserTestCancelDialogBox> createState() =>
      _CustomUserTestCancelDialogBoxState();
}

class _CustomUserTestCancelDialogBoxState
    extends State<CustomUserTestCancelDialogBox> {
  @override
  Widget build(BuildContext context) {
    final isPractice = widget.isPracticeMode ?? false;
    return AlertDialog(
      backgroundColor: AppTokens.surface(context),
      surfaceTintColor: AppTokens.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.r20),
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        AppTokens.s24,
        AppTokens.s20,
        AppTokens.s12,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        AppTokens.s8,
        AppTokens.s20,
        AppTokens.s20,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTokens.warningSoft(context),
              borderRadius: BorderRadius.circular(AppTokens.r16),
            ),
            child: Icon(
              isPractice
                  ? Icons.pan_tool_alt_outlined
                  : Icons.logout_rounded,
              color: AppTokens.warning(context),
              size: 28,
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Text(
            isPractice ? 'End Practice?' : 'Exit Exam?',
            textAlign: TextAlign.center,
            style: AppTokens.titleMd(context)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            isPractice
                ? 'Your progress will be saved, but you will leave the practice session.'
                : 'You won\'t be able to return to this attempt once you exit the exam.',
            textAlign: TextAlign.center,
            style: AppTokens.body(context).copyWith(
              color: AppTokens.ink2(context),
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppTokens.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTokens.r12),
                    ),
                  ),
                  child: Text(
                    'No',
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    widget.timer?.cancel();
                    widget.remainingTimeNotifier?.dispose();
                    Navigator.of(context).pushNamed(Routes.testCategory);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTokens.accent(context),
                    side: BorderSide(
                      color: AppTokens.accent(context),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTokens.r12),
                    ),
                  ),
                  child: Text(
                    'Yes',
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTokens.accent(context),
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
