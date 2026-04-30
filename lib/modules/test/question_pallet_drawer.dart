// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, dead_code, unused_local_variable, unused_field, unnecessary_null_comparison, prefer_typing_uninitialized_variables, dead_null_aware_expression

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/models/question_pallete_model.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/test/test_exam_screen.dart';

/// Embeddable palette side-drawer variant — same legend + grid, but
/// tapping a tile invokes `callBack(TestExamScreen(...))` for regular
/// exams (parent hosts the exam screen in a side-by-side layout).
/// Practice exams still push `Routes.practiceTestExams`.
///
/// Preserved public contract:
///   • `QuestionPalletDrawer(testExamPaper, userExamId, remainingTime,
///     isPracticeExam, timer, {super.key, required callBack})` where
///     `callBack: Function(TestExamScreen)`.
///   • `store.getQuestionPallete(userExamId ?? "")` in initState.
///   • Regular tap → `callBack(TestExamScreen(queNo, testExamPaper,
///     userExamId, remainingTime, isPracticeExam, fromPallete: true))`.
///   • Practice tap → `Navigator.pushNamed(Routes.practiceTestExams,
///     arguments: {queNo, testData, userexamId, remainingTime,
///     isPracticeExam, fromPallete: true})`.
///   • Legend labels identical to `QuestionPallet`.
class QuestionPalletDrawer extends StatefulWidget {
  final TestExamPaperListModel? testExamPaper;
  final String? userExamId;
  final ValueNotifier<Duration>? remainingTime;
  final bool? isPracticeExam;
  final Timer? timer;
  final Function(TestExamScreen textExamData) callBack;
  const QuestionPalletDrawer(
    this.testExamPaper,
    this.userExamId,
    this.remainingTime,
    this.isPracticeExam,
    this.timer, {
    super.key,
    required this.callBack,
  });

  @override
  State<QuestionPalletDrawer> createState() => _QuestionPalletDrawerState();
}

class _QuestionPalletDrawerState extends State<QuestionPalletDrawer> {
  Color? statusColor;
  Color? txtColor;

  Future<void> _getQuesPallete() async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    debugPrint("widget.userExamId:${widget.userExamId}");
    await store.getQuestionPallete(widget.userExamId ?? "");

    setState(() {
      if (widget.testExamPaper?.test != null) {
        widget.testExamPaper?.test =
            widget.testExamPaper?.test?.map((question) {
          final questionIdToMatch = question.sId;
          if (store.testQuePallete.isEmpty) {
            question.statusColor = ThemeManager.defaultPalleteColor.value;
            question.txtColor = ThemeManager.defaultPalleteTxtColor.value;
          } else {
            QuestionPalleteModel? matchingQuestion;
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
    final question = widget.testExamPaper?.test?[currentIndex];
    if (widget.isPracticeExam == false) {
      widget.callBack(TestExamScreen(
        queNo: question?.questionNumber,
        testExamPaper: widget.testExamPaper,
        userExamId: widget.userExamId,
        remainingTime: widget.remainingTime,
        isPracticeExam: widget.isPracticeExam,
        fromPallete: true,
      ));
    } else {
      Navigator.of(context).pushNamed(
        Routes.practiceTestExams,
        arguments: {
          'queNo': question?.questionNumber,
          'testData': widget.testExamPaper,
          'userexamId': widget.userExamId,
          'remainingTime': widget.remainingTime,
          'isPracticeExam': widget.isPracticeExam,
          'fromPallete': true,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.testExamPaper?.test?.length ?? 0;

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: AppTokens.border(context)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s16,
                AppTokens.s16,
                AppTokens.s16,
                AppTokens.s8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.testExamPaper?.examName}",
                    style: AppTokens.titleSm(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTokens.ink(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTokens.s12),
                  Wrap(
                    spacing: AppTokens.s12,
                    runSpacing: AppTokens.s8,
                    children: const [
                      _LegendPill(color: Colors.green, label: "Attempted"),
                      _LegendPill(
                          color: Colors.blue, label: "Marked for Review"),
                      _LegendPill(
                        color: Colors.orangeAccent,
                        label: "Attempted and Marked for Review",
                      ),
                      _LegendPill(color: Colors.brown, label: "Guess"),
                      _LegendPill(color: Colors.red, label: "Skipped"),
                      _LegendPill(color: Colors.black87, label: "Not Visited"),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppTokens.border(context)),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(AppTokens.s16),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 6.0,
                  mainAxisSpacing: 6.0,
                ),
                itemCount: total,
                itemBuilder: (context, index) {
                  final sColor = Color(
                      widget.testExamPaper?.test?[index].statusColor ?? 0);
                  final tColor = Color(
                      widget.testExamPaper?.test?[index].txtColor ?? 0);
                  return InkWell(
                    onTap: () => _openQuestion(index),
                    borderRadius: BorderRadius.circular(AppTokens.r28),
                    child: CircleAvatar(
                      radius: (Platform.isWindows || Platform.isMacOS)
                          ? 25
                          : 22,
                      backgroundColor: sColor,
                      child: Text(
                        "${index + 1}",
                        textAlign: TextAlign.center,
                        style: AppTokens.body(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: tColor,
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
