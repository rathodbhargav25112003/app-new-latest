// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names, dead_null_aware_expression

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/models/question_pallete_model.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/masterTest/test_master_exam_screen.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import 'custom_master_test_dialogbox.dart';

/// Side-drawer question pallet for the master exam runner (non-practice view).
/// Preserves:
///   • Constructor `QuestionMasterPalletDrawer(testExamPaper, userExamId,
///     remainingTime, isPracticeExam, {super.key, timer, required callBack})`
///   • `callBack: Function(TestMasterExamScreen)` signature
///   • State fields `statusColor`, `txtColor`
///   • `_getMasterQuesPallete()` — calls
///     `store.getMasterQuestionPallete(userExamId)` and re-colours every
///     `testExamPaper.test` entry using the same status precedence:
///         isAttempted → green / Colors.white
///         isMarkedForReview → Colors.blue / Colors.white
///         isAttemptedMarkedForReview → Colors.orangeAccent / Colors.white
///         isSkipped → Colors.red / Colors.white
///         isGuess → Colors.brown / Colors.white
///         default → ThemeManager.defaultPalleteColor / defaultPalleteTxtColor
///   • initState runs `_getMasterQuesPallete()` then debugPrints
///     `'ispracticein pallet${widget.isPracticeExam}'`
///   • Tap behaviour branches on `isPracticeExam`:
///       false → `callBack(TestMasterExamScreen(...))` with queNo,
///       true  → `pushNamed(Routes.practiceMasterTestExams)` with map
///     Both preserve the `fromPallete: true` flag
///   • 6-column `CustomDynamicHeightGridView` with BouncingScrollPhysics
///   • 7 legend dots (Attempted / Marked / Attempted & Marked / Guess /
///     Skipped / Not Visited — order preserved)
class QuestionMasterPalletDrawer extends StatefulWidget {
  final TestExamPaperListModel? testExamPaper;
  final String? userExamId;
  final ValueNotifier<Duration>? remainingTime;
  final bool? isPracticeExam;
  final Timer? timer;
  final Function(TestMasterExamScreen testMasterExamData) callBack;
  const QuestionMasterPalletDrawer(this.testExamPaper, this.userExamId,
      this.remainingTime, this.isPracticeExam,
      {super.key, this.timer, required this.callBack});

  @override
  State<QuestionMasterPalletDrawer> createState() =>
      _QuestionMasterPalletDrawerState();
}

class _QuestionMasterPalletDrawerState
    extends State<QuestionMasterPalletDrawer> {
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
    final bool isDesktop = Platform.isWindows || Platform.isMacOS;
    final int length = widget.testExamPaper?.test?.length ?? 0;

    return Scaffold(
      backgroundColor: AppTokens.surface(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------------------------------------------
            // Header
            // ---------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s16,
                AppTokens.s12,
                AppTokens.s16,
                AppTokens.s8,
              ),
              child: Text(
                widget.testExamPaper?.examName ?? "",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTokens.titleMd(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s16,
                0,
                AppTokens.s16,
                AppTokens.s12,
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
            // Grid
            // ---------------------------------------------------
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s12,
                  AppTokens.s16,
                  AppTokens.s12,
                  AppTokens.s12,
                ),
                child: length == 0
                    ? Center(
                        child: Text(
                          "No questions",
                          style: AppTokens.body(context),
                        ),
                      )
                    : CustomDynamicHeightGridView(
                        crossAxisSpacing: 6,
                        crossAxisCount: 6,
                        mainAxisSpacing: 10,
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: length,
                        builder: (context, index) {
                          final int currentIndex = index;
                          final q =
                              widget.testExamPaper?.test?[currentIndex];
                          return Center(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () {
                                if (widget.isPracticeExam == false) {
                                  widget.callBack(TestMasterExamScreen(
                                      queNo: q?.questionNumber,
                                      testExamPaper: widget.testExamPaper,
                                      userExamId: widget.userExamId,
                                      remainingTime: widget.remainingTime,
                                      isPracticeExam: widget.isPracticeExam,
                                      fromPallete: true));
                                } else {
                                  Navigator.of(context).pushNamed(
                                      Routes.practiceMasterTestExams,
                                      arguments: {
                                        'queNo': q?.questionNumber,
                                        'testData': widget.testExamPaper,
                                        'userexamId': widget.userExamId,
                                        'remainingTime': widget.remainingTime,
                                        'isPracticeExam':
                                            widget.isPracticeExam,
                                        'fromPallete': true
                                      });
                                }
                              },
                              child: CircleAvatar(
                                radius: isDesktop ? 25 : 22,
                                backgroundColor:
                                    Color(q?.statusColor ?? 0),
                                child: Text(
                                  "${currentIndex + 1}" ?? "",
                                  textAlign: TextAlign.center,
                                  style: AppTokens.titleSm(context).copyWith(
                                    color: Color(q?.txtColor ?? 0),
                                  ),
                                ),
                              ),
                            ),
                          );
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
