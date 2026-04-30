import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';

// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import, unnecessary_import
import 'package:flutter/cupertino.dart';
// ignore: unused_import
import 'package:flutter_mobx/flutter_mobx.dart';
// ignore: unused_import, depend_on_referenced_packages
import 'package:collection/collection.dart';
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import
import '../../helpers/styles.dart';
// ignore: unused_import
import '../../models/get_all_my_custom_test_model.dart';
// ignore: unused_import
import '../../models/question_pallete_model.dart';
// ignore: unused_import
import '../widgets/custom_button.dart';
// ignore: unused_import
import '../widgets/custom_test_bottom_sheet.dart';
// ignore: unused_import
import '../widgets/custom_test_cancel_dialogbox.dart';

/// CustomTestQuestionPallet — full-screen overlay that surfaces the status
/// of every question in the current custom test. Public surface preserved
/// exactly:
///   • const positional constructor
///     `(Data? testExamPaper, String? userExamId,
///       ValueNotifier remainingTime, bool? isPracticeExam, Timer? timer,
///       {Key? key})`
///   • `_getQuesPallete()` dispatches to
///     `TestCategoryStore.getCustomTestQuestionPallete(userExamId)` and
///     repopulates `testExamPaper.test` items with
///     `statusColor` / `txtColor` ints per match
///   • Tapping a number pushes either [Routes.customTestExams] (exam mode)
///     or [Routes.practiceCustomTestExamScreen] (practice mode) with the
///     complete legacy argument map (`queNo`, `testData`, `userexamId`,
///     `remainingTime`, `isPracticeExam`, `fromPallete`).
///
/// The 5-per-row layout is preserved verbatim — rows fire on `index % 5`.
class CustomTestQuestionPallet extends StatefulWidget {
  final Data? testExamPaper;
  final String? userExamId;
  final ValueNotifier<Duration>? remainingTime;
  final bool? isPracticeExam;
  final Timer? timer;
  // ignore: use_super_parameters
  const CustomTestQuestionPallet(this.testExamPaper, this.userExamId,
      this.remainingTime, this.isPracticeExam, this.timer,
      {Key? key})
      : super(key: key);

  @override
  State<CustomTestQuestionPallet> createState() =>
      _CustomTestQuestionPalletState();
}

class _CustomTestQuestionPalletState extends State<CustomTestQuestionPallet> {
  // ignore: unused_field
  Color? statusColor;
  // ignore: unused_field
  Color? txtColor;

  Future<void> _getQuesPallete() async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    debugPrint("widget.userExamId:${widget.userExamId}");
    await store.getCustomTestQuestionPallete(widget.userExamId ?? "");
    if (!mounted) return;

    setState(() {
      final palette = store.customTestQuePallete;
      // ignore: unnecessary_null_comparison
      final hasPalette = palette != null;
      if (widget.testExamPaper?.test != null && hasPalette) {
        widget.testExamPaper?.test =
            widget.testExamPaper?.test?.map((question) {
          final questionIdToMatch = question.sId;
          if (store.customTestQuePallete.isEmpty) {
            // ignore: deprecated_member_use
            question.statusColor = ThemeManager.defaultPalleteColor.value;
            // ignore: deprecated_member_use
            question.txtColor = ThemeManager.defaultPalleteTxtColor.value;
          } else {
            dynamic matchingQuestion;
            try {
              matchingQuestion = store.customTestQuePallete.firstWhere(
                (item) => item?.questionId == questionIdToMatch,
              );
            } catch (e) {
              matchingQuestion = null;
            }

            if (matchingQuestion != null) {
              if (matchingQuestion.isAttempted == true) {
                // ignore: deprecated_member_use
                question.statusColor = ThemeManager.greenSuccess.value;
                // ignore: deprecated_member_use
                question.txtColor = Colors.white.value;
              } else if (matchingQuestion.isMarkedForReview == true) {
                // ignore: deprecated_member_use
                question.statusColor = Colors.blue.value;
                // ignore: deprecated_member_use
                question.txtColor = Colors.white.value;
              } else if (matchingQuestion.isAttemptedMarkedForReview == true) {
                // ignore: deprecated_member_use
                question.statusColor = Colors.orangeAccent.value;
                // ignore: deprecated_member_use
                question.txtColor = Colors.white.value;
              } else if (matchingQuestion.isSkipped == true) {
                // ignore: deprecated_member_use
                question.statusColor = Colors.red.value;
                // ignore: deprecated_member_use
                question.txtColor = Colors.white.value;
              } else if (matchingQuestion.isGuess == true) {
                // ignore: deprecated_member_use
                question.statusColor = Colors.brown.value;
                // ignore: deprecated_member_use
                question.txtColor = Colors.white.value;
              }
            } else {
              // ignore: deprecated_member_use
              question.statusColor = ThemeManager.defaultPalleteColor.value;
              // ignore: deprecated_member_use
              question.txtColor = ThemeManager.defaultPalleteTxtColor.value;
            }
          }
          statusColor = Color(question.statusColor ?? 0);
          txtColor = Color(question.txtColor ?? 0);
          return question;
        }).toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getQuesPallete();
    debugPrint('ispracticein pallet${widget.isPracticeExam}');
  }

  void _navigateToQuestion(int currentIndex) {
    final qNum =
        widget.testExamPaper?.test?[currentIndex].questionNumber;
    if (widget.isPracticeExam == false) {
      Navigator.of(context).pushNamed(Routes.customTestExams, arguments: {
        'queNo': qNum,
        'testData': widget.testExamPaper,
        'userexamId': widget.userExamId,
        'remainingTime': widget.remainingTime,
        'isPracticeExam': widget.isPracticeExam,
        'fromPallete': true,
      });
    } else {
      Navigator.of(context)
          .pushNamed(Routes.practiceCustomTestExamScreen, arguments: {
        'queNo': qNum,
        'testData': widget.testExamPaper,
        'userexamId': widget.userExamId,
        'remainingTime': widget.remainingTime,
        'isPracticeExam': widget.isPracticeExam,
        'fromPallete': true,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.testExamPaper?.test?.length ?? 0;
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                AppTokens.s12,
                AppTokens.s16,
                AppTokens.s8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question Palette',
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.ink2(context),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: AppTokens.s4),
                        Text(
                          widget.testExamPaper?.testName ?? '',
                          style: AppTokens.titleMd(context)
                              .copyWith(fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Material(
                    color: AppTokens.surface2(context),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppTokens.ink(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                AppTokens.s8,
                AppTokens.s16,
                AppTokens.s12,
              ),
              child: Wrap(
                spacing: AppTokens.s8,
                runSpacing: AppTokens.s8,
                children: const [
                  _LegendPill(color: Colors.green, label: 'Attempted'),
                  _LegendPill(color: Colors.blue, label: 'Marked'),
                  _LegendPill(
                      color: Colors.orange,
                      label: 'Attempted + Marked'),
                  _LegendPill(color: Colors.brown, label: 'Guess'),
                  _LegendPill(color: Colors.red, label: 'Skipped'),
                  _LegendPill(color: Colors.black54, label: 'Not Visited'),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: AppTokens.border(context),
            ),
            const SizedBox(height: AppTokens.s16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s16,
                ),
                child: ListView.builder(
                  itemCount: total,
                  padding: const EdgeInsets.only(bottom: AppTokens.s16),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    if (index % 5 == 0) {
                      int itemCount =
                          index + 5 <= total ? 5 : total - index;
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppTokens.s8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(itemCount, (rowIndex) {
                            int currentIndex = index + rowIndex;
                            final cellBg = Color(widget.testExamPaper
                                    ?.test?[currentIndex].statusColor ??
                                0);
                            final cellFg = Color(widget.testExamPaper
                                    ?.test?[currentIndex].txtColor ??
                                0);
                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () =>
                                      _navigateToQuestion(currentIndex),
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.r12),
                                  child: Container(
                                    height: 44,
                                    width: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: cellBg,
                                      borderRadius: BorderRadius.circular(
                                          AppTokens.r12),
                                      boxShadow: [
                                        BoxShadow(
                                          // ignore: deprecated_member_use
                                          color: cellBg.withOpacity(0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${currentIndex + 1}',
                                      style: AppTokens.body(context)
                                          .copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: cellFg,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.ink(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
