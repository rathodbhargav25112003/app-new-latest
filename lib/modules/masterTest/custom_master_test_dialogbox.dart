// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/new_exam_component/store/exam_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';

/// Master-test cancel confirmation dialog — redesigned with AppTokens.
/// Preserves the 3-positional constructor (timer, remainingTimeNotifier,
/// isPracticeMode), the No → Navigator.pop(context, false) path, and
/// the Yes → timer.cancel() + remainingTimeNotifier.dispose() +
/// ExamStore.disposeStore() + pushNamed(Routes.allTestCategory) path.
class CustomMasterTestCancelDialogBox extends StatefulWidget {
  final Timer? timer;
  final ValueNotifier<Duration>? remainingTimeNotifier;
  final bool? isPracticeMode;
  const CustomMasterTestCancelDialogBox(
      this.timer, this.remainingTimeNotifier, this.isPracticeMode,
      {super.key});

  @override
  State<CustomMasterTestCancelDialogBox> createState() =>
      _CustomMasterTestCancelDialogBoxState();
}

class _CustomMasterTestCancelDialogBoxState
    extends State<CustomMasterTestCancelDialogBox> {
  @override
  Widget build(BuildContext context) {
    final bool isPractice = widget.isPracticeMode ?? false;
    return AlertDialog(
      backgroundColor: AppTokens.surface(context),
      surfaceTintColor: AppTokens.surface(context),
      contentPadding: const EdgeInsets.fromLTRB(
        AppTokens.s24,
        AppTokens.s24,
        AppTokens.s24,
        AppTokens.s16,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        0,
        AppTokens.s20,
        AppTokens.s20,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppTokens.radius20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTokens.dangerSoft(context),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.logout_rounded,
              color: AppTokens.danger(context),
              size: 30,
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Text(
            isPractice ? "End Practice?" : "Exit Exam?",
            textAlign: TextAlign.center,
            style: AppTokens.titleMd(context),
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            isPractice
                ? "Do you want to end the practice? Your progress for this session will be lost."
                : "Do you want to exit the exam? Your progress will not be saved.",
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
              child: _DialogButton(
                label: "No",
                onTap: () => Navigator.pop(context, false),
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: _DialogButton(
                label: "Yes, Exit",
                primary: false,
                onTap: () {
                  widget.timer?.cancel();
                  widget.remainingTimeNotifier?.dispose();
                  final examStore =
                      Provider.of<ExamStore>(context, listen: false);
                  examStore.disposeStore();
                  Navigator.of(context).pushNamed(Routes.allTestCategory);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
//                        Primitives
// ============================================================

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.onTap,
    this.primary = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return Material(
        borderRadius: AppTokens.radius12,
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppTokens.radius12,
              boxShadow: [
                BoxShadow(
                  color: AppTokens.brand.withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  label,
                  style: AppTokens.titleSm(context)
                      .copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Material(
      borderRadius: AppTokens.radius12,
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: AppTokens.radius12,
            border: Border.all(
              color: AppTokens.danger(context).withOpacity(0.6),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: AppTokens.titleSm(context).copyWith(
              color: AppTokens.danger(context),
            ),
          ),
        ),
      ),
    );
  }
}
