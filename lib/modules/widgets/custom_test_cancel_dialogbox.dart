import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../new_exam_component/store/exam_store.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import
import '../../helpers/styles.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import, unnecessary_import
import 'package:flutter/cupertino.dart';
// ignore: unused_import
import 'package:shusruta_lms/helpers/colors.dart';

/// CustomTestCancelDialogBox — exit-exam confirmation dialog. Public surface
/// preserved exactly:
///   • const constructor
///     `(Timer? timer, ValueNotifier remainingTimeNotifier (of Duration),
///       bool? isPracticeMode, {Key? key})`
///   • On "Yes": cancels timer, disposes notifier, calls
///     `ExamStore.disposeStore()`, navigates to `Routes.testCategory`
///   • On "No": pops the dialog with `false`
class CustomTestCancelDialogBox extends StatefulWidget {
  final Timer? timer;
  final ValueNotifier<Duration>? remainingTimeNotifier;
  final bool? isPracticeMode;
  // ignore: use_super_parameters
  const CustomTestCancelDialogBox(
    this.timer,
    this.remainingTimeNotifier,
    this.isPracticeMode, {
    Key? key,
  }) : super(key: key);

  @override
  State<CustomTestCancelDialogBox> createState() =>
      _CustomTestCancelDialogBoxState();
}

class _CustomTestCancelDialogBoxState extends State<CustomTestCancelDialogBox> {
  @override
  Widget build(BuildContext context) {
    final bool isPractice = widget.isPracticeMode ?? false;
    return Dialog(
      backgroundColor: AppTokens.surface(context),
      surfaceTintColor: AppTokens.surface(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.r20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s24,
            AppTokens.s24,
            AppTokens.s24,
            AppTokens.s20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTokens.warningSoft(context),
                    borderRadius: BorderRadius.circular(AppTokens.r20),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppTokens.warning(context),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s16),
              Text(
                isPractice
                    ? 'Do you want to end the practice?'
                    : 'Do you want to exit the exam?',
                textAlign: TextAlign.center,
                style: AppTokens.titleLg(context)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppTokens.s8),
              Text(
                'Your progress will be saved, but the session will end.',
                textAlign: TextAlign.center,
                style: AppTokens.body(context).copyWith(
                  color: AppTokens.ink2(context),
                ),
              ),
              const SizedBox(height: AppTokens.s20),
              Row(
                children: [
                  Expanded(
                    child: _PrimaryCta(
                      label: 'No',
                      onTap: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: _OutlineCta(
                      label: 'Yes',
                      onTap: () {
                        widget.timer?.cancel();
                        widget.remainingTimeNotifier?.dispose();
                        final examStore =
                            Provider.of<ExamStore>(context, listen: false);
                        examStore.disposeStore();
                        Navigator.of(context)
                            .pushNamed(Routes.testCategory);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
          child: Text(
            label,
            style: AppTokens.body(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineCta extends StatelessWidget {
  const _OutlineCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.surface2(context),
            border: Border.all(color: AppTokens.accent(context)),
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
          child: Text(
            label,
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.accent(context),
            ),
          ),
        ),
      ),
    );
  }
}
