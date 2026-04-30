// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, dead_code, unused_local_variable, unused_field, unnecessary_null_comparison, prefer_typing_uninitialized_variables

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/models/question_pallete_model.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';

/// Question palette for a running test — colour-coded grid of every
/// question plus a legend. Tapping a tile navigates back to the exam
/// screen at that question number.
///
/// Preserved public contract:
///   • `QuestionPallet(testExamPaper, userExamId, remainingTime,
///     isPracticeExam, timer, {Key? key})` — five positional params.
///   • `store.getQuestionPallete(widget.userExamId ?? "")` in initState
///     (via `_getQuesPallete`).
///   • Per-question status colours:
///       - attempted → green
///       - markedForReview → blue
///       - attemptedMarkedForReview → orange
///       - skipped → red
///       - guess → brown
///       - default → ThemeManager.defaultPalleteColor /
///         defaultPalleteTxtColor
///   • Tile tap → `Routes.testExams` (regular) or
///     `Routes.practiceTestExams` (practice) with arguments
///     `{queNo, testData, userexamId, remainingTime, isPracticeExam,
///     fromPallete: true}`.
///   • Legend labels verbatim: "Attempted", "Marked for Review",
///     "Attempted and Marked for Review", "Guess", "Skipped",
///     "Not Visited".
class QuestionPallet extends StatefulWidget {
  final TestExamPaperListModel? testExamPaper;
  final String? userExamId;
  final ValueNotifier<Duration>? remainingTime;
  final bool? isPracticeExam;
  final Timer? timer;
  const QuestionPallet(
    this.testExamPaper,
    this.userExamId,
    this.remainingTime,
    this.isPracticeExam,
    this.timer, {
    Key? key,
  }) : super(key: key);

  @override
  State<QuestionPallet> createState() => _QuestionPalletState();
}

class _QuestionPalletState extends State<QuestionPallet> {
  Color? statusColor;
  Color? txtColor;

  Future<void> _getQuesPallete() async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    debugPrint("widget.userExamId:${widget.userExamId}");
    await store.getQuestionPallete(widget.userExamId ?? "");

    setState(() {
      if (widget.testExamPaper?.test != null && store.testQuePallete != null) {
        widget.testExamPaper?.test =
            widget.testExamPaper?.test?.map((question) {
          final questionIdToMatch = question.sId;
          if (store.testQuePallete.isEmpty) {
            question.statusColor = ThemeManager.defaultPalleteColor.value;
            question.txtColor = ThemeManager.defaultPalleteTxtColor.value;
          } else {
            var matchingQuestion;
            try {
              matchingQuestion = store.testQuePallete.firstWhere(
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
    _getQuesPallete();
    debugPrint('ispracticein pallet${widget.isPracticeExam}');
  }

  void _openQuestion(int currentIndex) {
    final args = {
      'queNo': widget.testExamPaper?.test?[currentIndex].questionNumber,
      'testData': widget.testExamPaper,
      'userexamId': widget.userExamId,
      'remainingTime': widget.remainingTime,
      'isPracticeExam': widget.isPracticeExam,
      'fromPallete': true,
    };
    if (widget.isPracticeExam == false) {
      Navigator.of(context).pushNamed(Routes.testExams, arguments: args);
    } else {
      Navigator.of(context).pushNamed(Routes.practiceTestExams, arguments: args);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.testExamPaper?.test?.length ?? 0;

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                AppTokens.s12,
                AppTokens.s20,
                AppTokens.s12,
              ),
              child: Wrap(
                spacing: AppTokens.s12,
                runSpacing: AppTokens.s8,
                children: const [
                  _LegendPill(color: Colors.green, label: "Attempted"),
                  _LegendPill(color: Colors.blue, label: "Marked for Review"),
                  _LegendPill(
                    color: Colors.orangeAccent,
                    label: "Attempted and Marked for Review",
                  ),
                  _LegendPill(color: Colors.brown, label: "Guess"),
                  _LegendPill(color: Colors.red, label: "Skipped"),
                  _LegendPill(color: Colors.black87, label: "Not Visited"),
                ],
              ),
            ),
            Divider(height: 1, color: AppTokens.border(context)),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s20,
                  AppTokens.s16,
                  AppTokens.s20,
                  AppTokens.s24,
                ),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: AppTokens.s8,
                  mainAxisSpacing: AppTokens.s8,
                ),
                itemCount: total,
                itemBuilder: (context, index) {
                  final statusColor = Color(
                    widget.testExamPaper?.test?[index].statusColor ?? 0,
                  );
                  final txtColor = Color(
                    widget.testExamPaper?.test?[index].txtColor ?? 0,
                  );
                  return InkWell(
                    onTap: () => _openQuestion(index),
                    borderRadius: BorderRadius.circular(AppTokens.r20),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(AppTokens.r20),
                      ),
                      child: Text(
                        " ${index + 1}",
                        style: AppTokens.body(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: txtColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        AppTokens.s16,
        AppTokens.s8,
        AppTokens.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "${widget.testExamPaper?.examName}",
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(AppTokens.r8),
            child: Container(
              height: AppTokens.s32,
              width: AppTokens.s32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTokens.surface2(context),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: Icon(
                Icons.close,
                size: 20,
                color: AppTokens.ink(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendPill({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 5.0, backgroundColor: color),
        const SizedBox(width: AppTokens.s8),
        Text(
          label,
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.ink(context),
          ),
        ),
      ],
    );
  }
}
