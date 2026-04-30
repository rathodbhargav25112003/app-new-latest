// ignore_for_file: deprecated_member_use, avoid_print, library_private_types_in_public_api

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/new_exam_component/model/exam_ans_model.dart';
import 'package:shusruta_lms/modules/new_exam_component/store/exam_store.dart';

/// Question pallet sheet for the (non-section) exam flow. Redesigned
/// with AppTokens while preserving every contract:
///   • Constructor `ExamPallet({super.key, required userExamId,
///     required examName, required isDesktop})`
///   • Private state class retains fields `statusColor`, `txtColor`,
///     `count`, `questionList`, and `store` and preserves
///     `_getMasterQuesPallete()`'s exact color precedence:
///       attempted → greenSuccess, markedForReview → orange,
///       attemptedMarkedForReview → 0xff74367E, skipped → red,
///       guess.isNotEmpty → 0xff2E6FEE, else → black (default when
///       the ans list is empty or no match)
///   • Tap behaviour: `store.changeIndex(index)` + `Navigator.pop`
///     on mobile (isDesktop:false)
///   • Wide vs mobile legend layout split using width>1160 &&
///     height>670 preserved
///   • `Observer` wraps the entire Scaffold so MobX reactivity still
///     drives updates when ansList changes
class ExamPallet extends StatefulWidget {
  const ExamPallet({
    super.key,
    required this.userExamId,
    required this.examName,
    required this.isDesktop,
  });

  final String userExamId;
  final String examName;
  final bool isDesktop;

  @override
  State<ExamPallet> createState() => _ExamPalletState();
}

class _ExamPalletState extends State<ExamPallet> {
  Color? statusColor;
  Color? txtColor;
  Map<String, dynamic> count = {};
  List<TestData> questionList = [];
  late ExamStore store;

  Future<void> _getMasterQuesPallete() async {
    debugPrint('widget.userExamId:${widget.userExamId}');
    final store = Provider.of<ExamStore>(context, listen: false);
    log(analyzeQuestionStatus(
            store.ansList.value, store.questionList.value.length)
        .toString());
    count = analyzeQuestionStatus(
        store.ansList.value, store.questionList.value.length);
    setState(() {});
    setState(() {
      questionList = store.questionList.value.map((question) {
        final questionIdToMatch = question.sId;
        if (store.ansList.value.isEmpty) {
          question.statusColor = ThemeManager.defaultPalleteColor.value;
          question.txtColor = ThemeManager.defaultPalleteTxtColor.value;
        } else {
          ExamAnsModel? matchingQuestion;
          try {
            matchingQuestion = store.ansList.value.firstWhere(
              (item) => item.questionId == questionIdToMatch,
            );
          } catch (e) {
            matchingQuestion = null;
          }
          if (matchingQuestion != null) {
            if (matchingQuestion.attempted == true) {
              question.statusColor = ThemeManager.greenSuccess.value;
            } else if (matchingQuestion.markedForReview == true) {
              question.statusColor = Colors.orange.value;
            } else if (matchingQuestion.attemptedMarkedForReview == true) {
              question.statusColor = const Color(0xff74367E).value;
            } else if (matchingQuestion.skipped == true) {
              question.statusColor = Colors.red.value;
            } else if (matchingQuestion.guess.isNotEmpty) {
              question.statusColor = const Color(0xff2E6FEE).value;
            } else {
              question.statusColor = ThemeManager.black.value;
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
    });
  }

  bool _isWide(BuildContext context) =>
      MediaQuery.of(context).size.width > 1160 &&
      MediaQuery.of(context).size.height > 670;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    store = Provider.of<ExamStore>(context, listen: false);
    _getMasterQuesPallete();
    return Observer(
      builder: (context) {
        return Scaffold(
          backgroundColor: AppTokens.scaffold(context),
          body: SizedBox(
            height: double.infinity,
            width: MediaQuery.of(context).size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(
                    top: widget.isDesktop ? 12 : AppTokens.s32 + AppTokens.s16,
                    left: AppTokens.s20,
                    right: AppTokens.s12,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppTokens.s8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.examName,
                              style: AppTokens.titleMd(context).copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: AppTokens.ink(context),
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                          if (!widget.isDesktop) ...[
                            const SizedBox(width: AppTokens.s8),
                            _CloseBtn(
                              onTap: () => Navigator.pop(context),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppTokens.s16),
                      if (!_isWide(context)) ...[
                        Row(
                          children: [
                            _buildLegendItem(
                              Colors.green,
                              'Attempted',
                              count['isAttempted'].toString(),
                            ),
                            const SizedBox(width: AppTokens.s20),
                            _buildLegendItem(
                              ThemeManager.evolveYellow,
                              'Not Visited',
                              count['notVisited'].toString(),
                            ),
                            const SizedBox(width: AppTokens.s20),
                            _buildLegendItem(
                              Colors.orange,
                              'Marked for Review',
                              count['isMarkedForReview'].toString(),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.s16),
                        Row(
                          children: [
                            _buildLegendItem(
                              Colors.red,
                              'Skipped',
                              count['isSkipped'].toString(),
                            ),
                            const SizedBox(width: 37),
                            _buildLegendItem(
                              const Color(0xff2E6FEE),
                              'Guess',
                              count['isGuess'].toString(),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.s16),
                        Row(
                          children: [
                            _buildLegendItem(
                              const Color(0xff74367E),
                              'Attempted and Marked for Review',
                              count['isAttemptedMarkedForReview'].toString(),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.s16),
                      ],
                      if (_isWide(context)) ...[
                        Wrap(
                          runSpacing: AppTokens.s16,
                          spacing: AppTokens.s20,
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          children: [
                            _buildLegendItem(
                              Colors.green,
                              'Attempted',
                              count['isAttempted'].toString(),
                            ),
                            _buildLegendItem(
                              ThemeManager.evolveYellow,
                              'Not Visited',
                              count['notVisited'].toString(),
                            ),
                            _buildLegendItem(
                              Colors.orange,
                              'Marked for Review',
                              count['isMarkedForReview'].toString(),
                            ),
                            _buildLegendItem(
                              Colors.red,
                              'Skipped',
                              count['isSkipped'].toString(),
                            ),
                            _buildLegendItem(
                              const Color(0xff2E6FEE),
                              'Guess',
                              count['isGuess'].toString(),
                            ),
                            _buildLegendItem(
                              const Color(0xff74367E),
                              'Attempted and Marked for Review',
                              count['isAttemptedMarkedForReview'].toString(),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppTokens.s16,
                      right: AppTokens.s16,
                      bottom: AppTokens.s24,
                    ),
                    child: CustomDynamicHeightGridView(
                      itemCount: questionList.length,
                      physics: const BouncingScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisCount: 4,
                      builder: (context, index) {
                        return Observer(
                          builder: (context) {
                            final cellColor =
                                Color(questionList[index].statusColor ?? 0);
                            return _QuestionCell(
                              label: '${index + 1}',
                              borderColor: cellColor,
                              onTap: () {
                                print(index);
                                store.changeIndex(index);
                                if (!widget.isDesktop) {
                                  Navigator.pop(context);
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          height: 28,
          width: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTokens.bodyLg(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
            ),
            Text(
              label,
              style: AppTokens.caption(context).copyWith(
                fontWeight: FontWeight.w500,
                height: 1.1,
                color: AppTokens.muted(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CloseBtn extends StatelessWidget {
  const _CloseBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.r12),
      onTap: onTap,
      child: Container(
        height: 36,
        width: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          border: Border.all(color: AppTokens.border(context)),
          borderRadius: BorderRadius.circular(AppTokens.r12),
          boxShadow: AppTokens.shadow1(context),
        ),
        child: Icon(Icons.close, size: 20, color: AppTokens.ink(context)),
      ),
    );
  }
}

class _QuestionCell extends StatelessWidget {
  const _QuestionCell({
    required this.label,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.r8),
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(AppTokens.r8),
        ),
        child: Text(
          label,
          style: AppTokens.bodyLg(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppTokens.ink(context),
          ),
        ),
      ),
    );
  }
}
