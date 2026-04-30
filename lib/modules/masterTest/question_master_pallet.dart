// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names, dead_null_aware_expression

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/models/question_pallete_model.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import 'custom_master_test_dialogbox.dart';

/// Full-screen question pallet for the master exam runner. Redesigned with
/// AppTokens. Preserves:
///   • Constructor `QuestionMasterPallet(testExamPaper, userExamId,
///     remainingTime, isPracticeExam, {super.key, timer, showPredictive})`
///   • State fields `statusColor`, `txtColor`
///   • `_getMasterQuesPallete()` — precisely the same colour precedence as
///     the drawer variant (attempted → green / marked → blue /
///     attemptedMarked → orangeAccent / skipped → red / guess → brown /
///     default → ThemeManager.defaultPalleteColor, with white text on
///     coloured states and defaultPalleteTxtColor fallback)
///   • initState → `_getMasterQuesPallete()` + debugPrint
///   • Close icon → `Navigator.pop(context)`
///   • Tile tap branches on `isPracticeExam`:
///       false → `pushReplacementNamed(Routes.testMasterExams, args)`
///       true  → `pushReplacementNamed(Routes.practiceMasterTestExams, args)`
///     Both preserve the args map keys: queNo, testData, userexamId,
///     remainingTime, isPracticeExam, fromPallete: true, showPredictive
///   • `ListView.builder(physics: BouncingScrollPhysics)` with the
///     `index % 5 == 0` row-builder pattern (5-column rows)
///   • 7 legend dots: Attempted / Marked / Attempted+Marked / Guess /
///     Skipped / Not Visited — order preserved
class QuestionMasterPallet extends StatefulWidget {
  final TestExamPaperListModel? testExamPaper;
  final String? userExamId;
  final ValueNotifier<Duration>? remainingTime;
  final bool? isPracticeExam;
  final bool? showPredictive;
  final Timer? timer;
  const QuestionMasterPallet(this.testExamPaper, this.userExamId,
      this.remainingTime, this.isPracticeExam,
      {super.key, this.timer, this.showPredictive});

  @override
  State<QuestionMasterPallet> createState() => _QuestionMasterPalletState();
}

class _QuestionMasterPalletState extends State<QuestionMasterPallet> {
  Color? statusColor;
  Color? txtColor;

  Future<void> _getMasterQuesPallete() async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    debugPrint("widget.userExamId:${widget.userExamId}");
    await store.getMasterQuestionPallete(widget.userExamId ?? "");

    setState(() {
      if (widget.testExamPaper?.test != null) {
        widget.testExamPaper?.test =
            widget.testExamPaper?.test?.map((question) {
          final questionIdToMatch = question.sId;
          if (store.masterTestQuePallete.isEmpty) {
            question.statusColor = ThemeManager.defaultPalleteColor.value;
            question.txtColor = ThemeManager.defaultPalleteTxtColor.value;
          } else {
            QuestionPalleteModel? matchingQuestion;
            try {
              matchingQuestion = store.masterTestQuePallete.firstWhere(
                (item) => item?.questionId == questionIdToMatch,
              );
            } catch (e) {
              matchingQuestion = null;
            }

            if (matchingQuestion != null) {
              if (matchingQuestion.isAttempted == true) {
                question.statusColor = ThemeManager.greenSuccess.value;
                question.txtColor = Colors.white.value;
              } else if (matchingQuestion.isMarkedForReview == true) {
                question.statusColor = Colors.blue.value;
                question.txtColor = Colors.white.value;
              } else if (matchingQuestion.isAttemptedMarkedForReview == true) {
                question.statusColor = Colors.orangeAccent.value;
                question.txtColor = Colors.white.value;
              } else if (matchingQuestion.isSkipped == true) {
                question.statusColor = Colors.red.value;
                question.txtColor = Colors.white.value;
              } else if (matchingQuestion.isGuess == true) {
                question.statusColor = Colors.brown.value;
                question.txtColor = Colors.white.value;
              }
            } else {
              question.statusColor = ThemeManager.defaultPalleteColor.value;
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
    _getMasterQuesPallete();
    debugPrint('ispracticein pallet${widget.isPracticeExam}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------------------------------------------
            // Header row
            // ---------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s16,
                AppTokens.s12,
                AppTokens.s16,
                AppTokens.s8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "${widget.testExamPaper?.examName}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTokens.titleMd(context),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  _CloseBtn(onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            // ---------------------------------------------------
            // Legend
            // ---------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s16,
                AppTokens.s4,
                AppTokens.s16,
                AppTokens.s16,
              ),
              child: Wrap(
                spacing: AppTokens.s12,
                runSpacing: AppTokens.s8,
                children: const [
                  _LegendDot(color: Colors.green, label: "Attempted"),
                  _LegendDot(color: Colors.blue, label: "Marked for Review"),
                  _LegendDot(
                    color: Colors.orangeAccent,
                    label: "Attempted and Marked for Review",
                  ),
                  _LegendDot(color: Colors.brown, label: "Guess"),
                  _LegendDot(color: Colors.red, label: "Skipped"),
                  _LegendDot(color: Colors.black, label: "Not Visited"),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: AppTokens.border(context),
            ),
            // ---------------------------------------------------
            // Grid (5 per row, index % 5 == 0 preserved)
            // ---------------------------------------------------
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s16,
                  AppTokens.s16,
                  AppTokens.s16,
                  AppTokens.s16,
                ),
                child: ListView.builder(
                  itemCount: widget.testExamPaper?.test?.length,
                  padding: EdgeInsets.zero,
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    if (index % 5 == 0) {
                      int itemCount = index + 5 <=
                              (widget.testExamPaper?.test?.length ?? 0)
                          ? 5
                          : (widget.testExamPaper?.test?.length ?? 0) - index;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          itemCount,
                          (rowIndex) {
                            int currentIndex = index + rowIndex;
                            final q =
                                widget.testExamPaper?.test?[currentIndex];
                            return Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(999),
                                onTap: () {
                                  if (widget.isPracticeExam == false) {
                                    Navigator.of(context)
                                        .pushReplacementNamed(
                                            Routes.testMasterExams,
                                            arguments: {
                                          'queNo': q?.questionNumber,
                                          'testData': widget.testExamPaper,
                                          'userexamId': widget.userExamId,
                                          'remainingTime':
                                              widget.remainingTime,
                                          'isPracticeExam':
                                              widget.isPracticeExam,
                                          'fromPallete': true,
                                          'showPredictive':
                                              widget.showPredictive
                                        });
                                  } else {
                                    Navigator.of(context)
                                        .pushReplacementNamed(
                                            Routes.practiceMasterTestExams,
                                            arguments: {
                                          'queNo': q?.questionNumber,
                                          'testData': widget.testExamPaper,
                                          'userexamId': widget.userExamId,
                                          'remainingTime':
                                              widget.remainingTime,
                                          'isPracticeExam':
                                              widget.isPracticeExam,
                                          'fromPallete': true,
                                          'showPredictive':
                                              widget.showPredictive
                                        });
                                  }
                                },
                                child: Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color: Color(q?.statusColor ?? 0),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                  child: Center(
                                    child: Text(
                                      " ${currentIndex + 1}" ?? "",
                                      style: AppTokens.titleSm(context)
                                          .copyWith(
                                        color: Color(q?.txtColor ?? 0),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
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

// ============================================================
//                        Primitives
// ============================================================

class _CloseBtn extends StatelessWidget {
  const _CloseBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            shape: BoxShape.circle,
            border: Border.all(color: AppTokens.border(context)),
            boxShadow: AppTokens.shadow1(context),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: AppTokens.ink(context),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTokens.caption(context)
              .copyWith(color: AppTokens.ink2(context)),
        ),
      ],
    );
  }
}
