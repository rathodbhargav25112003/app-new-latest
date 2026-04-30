// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, dead_null_aware_expression, prefer_typing_uninitialized_variables, unnecessary_null_comparison, unused_field

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/modules/quiztest/model/quiz_model.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';

/// Quiz question-pallet screen — colour-coded grid of question
/// numbers for the in-progress quiz, with a legend at the top
/// explaining each state (Attempted / Marked for Review / Attempted
/// and Marked for Review / Guess / Skipped / Not Visited).
///
/// Preserved public contract:
///   • 5-positional-arg constructor
///     `QuizQuestionPallet(this.testExamPaper, this.userExamId, this.remainingTime, this.isPracticeExam, this.timer, {Key? key})`
///   • `_getQuesPallete()` calls
///     `TestCategoryStore.getQuizQuestionPallete(widget.userExamId ?? "")`
///     and maps each `testExamPaper.test` entry's `statusColor` /
///     `txtColor` fields against `quizQuePallete` entries by
///     `questionId == sId`, applying the exact colour mapping
///     preserved byte-for-byte:
///       - isAttempted → greenSuccess / white
///       - isMarkedForReview → blue / white
///       - isAttemptedMarkedForReview → orangeAccent / white
///       - isSkipped → red / white
///       - isGuess → brown / white
///       - no match → defaultPalleteColor / defaultPalleteTxtColor
///   • Tap on a tile pushes `Routes.quizTestExamScreen` with a 6-key
///     arg map: `queNo`, `testData`, `userexamId`, `remainingTime`,
///     `isPracticeExam`, `fromPallete: true`.
///   • 5-per-row layout preserved (rows built at indices % 5 == 0).
class QuizQuestionPallet extends StatefulWidget {
  final QuizModel? testExamPaper;
  final String? userExamId;
  final ValueNotifier<Duration>? remainingTime;
  final bool? isPracticeExam;
  final Timer? timer;
  const QuizQuestionPallet(
    this.testExamPaper,
    this.userExamId,
    this.remainingTime,
    this.isPracticeExam,
    this.timer, {
    super.key,
  });

  @override
  State<QuizQuestionPallet> createState() => _QuizQuestionPalletState();
}

class _QuizQuestionPalletState extends State<QuizQuestionPallet> {
  Color? statusColor;
  Color? txtColor;

  Future<void> _getQuesPallete() async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    debugPrint("widget.userExamId:${widget.userExamId}");
    await store.getQuizQuestionPallete(widget.userExamId ?? "");

    if (!mounted) return;
    setState(() {
      if (widget.testExamPaper?.test != null &&
          store.quizQuePallete != null) {
        widget.testExamPaper?.test =
            widget.testExamPaper?.test?.map((question) {
          final questionIdToMatch = question.sId;
          if (store.quizQuePallete.isEmpty) {
            question.statusColor = ThemeManager.defaultPalleteColor.value;
            question.txtColor = ThemeManager.defaultPalleteTxtColor.value;
          } else {
            var matchingQuestion;
            try {
              matchingQuestion = store.quizQuePallete.firstWhere(
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
              } else if (matchingQuestion.isAttemptedMarkedForReview ==
                  true) {
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
              question.txtColor =
                  ThemeManager.defaultPalleteTxtColor.value;
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

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: SafeArea(
        child: SizedBox(
          width: mq.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(
                  top: AppTokens.s24,
                  left: AppTokens.s20,
                  right: AppTokens.s20,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "${widget.testExamPaper?.quizName}",
                            style: AppTokens.titleSm(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTokens.ink(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.s8),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius:
                              BorderRadius.circular(AppTokens.r8),
                          child: Container(
                            height: AppTokens.s32,
                            width: AppTokens.s32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTokens.surface2(context),
                              borderRadius:
                                  BorderRadius.circular(AppTokens.r8),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: AppTokens.ink(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.s16),
                    _LegendRow(
                        color: Colors.green, label: "Attempted"),
                    _LegendRow(
                        color: Colors.blue, label: "Marked for Review"),
                    _LegendRow(
                        color: Colors.orange,
                        label: "Attempted and Marked for Review"),
                    _LegendRow(color: Colors.brown, label: "Guess"),
                    _LegendRow(color: Colors.red, label: "Skipped"),
                    _LegendRow(
                        color: AppTokens.ink(context), label: "Not Visited"),
                    const SizedBox(height: AppTokens.s16),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: AppTokens.border(context),
              ),
              const SizedBox(height: AppTokens.s16),
              Padding(
                padding: const EdgeInsets.only(left: AppTokens.s20),
                child: SizedBox(
                  height: mq.height * 0.64,
                  width: mq.width,
                  child: ListView.builder(
                    itemCount: widget.testExamPaper?.test?.length,
                    padding: EdgeInsets.zero,
                    scrollDirection: Axis.vertical,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      if (index % 5 == 0) {
                        int itemCount =
                            index + 5 <= (widget.testExamPaper?.test?.length ?? 0)
                                ? 5
                                : (widget.testExamPaper?.test?.length ?? 0) -
                                    index;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(itemCount, (rowIndex) {
                            int currentIndex = index + rowIndex;
                            return Padding(
                              padding: const EdgeInsets.all(AppTokens.s4),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    Routes.quizTestExamScreen,
                                    arguments: {
                                      'queNo': widget.testExamPaper
                                          ?.test?[currentIndex].questionNumber,
                                      'testData': widget.testExamPaper,
                                      'userexamId': widget.userExamId,
                                      'remainingTime': widget.remainingTime,
                                      'isPracticeExam':
                                          widget.isPracticeExam,
                                      'fromPallete': true,
                                    },
                                  );
                                },
                                borderRadius:
                                    BorderRadius.circular(AppTokens.r12),
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    right: AppTokens.s4,
                                    bottom: AppTokens.s4,
                                  ),
                                  height: 42,
                                  width: 42,
                                  decoration: BoxDecoration(
                                    color: Color(widget.testExamPaper
                                            ?.test?[currentIndex]
                                            .statusColor ??
                                        0),
                                    borderRadius: BorderRadius.circular(
                                        AppTokens.r12),
                                    border: Border.all(
                                      color: AppTokens.border(context),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      // widget.testExamPaper?.test?[currentIndex].questionNumber.toString()??"",
                                      " ${currentIndex + 1}" ?? "",
                                      style: AppTokens.body(context).copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Color(widget.testExamPaper
                                                ?.test?[currentIndex]
                                                .txtColor ??
                                            0),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
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
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Row(
        children: [
          Container(
            height: 10,
            width: 10,
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
            ),
          ),
        ],
      ),
    );
  }
}
