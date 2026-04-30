import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../models/featured_list_model.dart';

/// FeaturedQuestionPallet — Apple-minimalistic question grid.
///
/// Layout:
///  • Two-column legend (Attempted, Marked for Review, etc.) on a
///    single soft-surface card.
///  • Hairline divider.
///  • Wrapping grid of square chips (40x40) with a 4px gap. The chip
///    fills with the question's [statusColor] and labels with
///    [txtColor]. Tap to deep-link back into [Routes.featuredTestExamPage].
class FeaturedQuestionPallet extends StatefulWidget {
  final TestsPaper? testExamPaper;
  final String? userExamId;
  final ValueNotifier<Duration>? remainingTime;
  const FeaturedQuestionPallet(
    this.testExamPaper,
    this.userExamId,
    this.remainingTime, {
    Key? key,
  }) : super(key: key);

  @override
  State<FeaturedQuestionPallet> createState() => _FeaturedQuestionPalletState();
}

class _FeaturedQuestionPalletState extends State<FeaturedQuestionPallet> {
  // Apple-friendly palette anchored on AppTokens.
  static const _attemptedColor = Color(0xFF33AD48);
  static const _markedColor = Color(0xFF1E88E5);
  static const _attemptedMarkedColor = Color(0xFFE89B20);
  static const _skippedColor = Color(0xFFE23B3B);
  static const _guessColor = Color(0xFF8E44AD);

  Future<void> _getQuesPallete() async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.getQuestionPallete(widget.userExamId ?? "");

    if (!mounted) return;
    setState(() {
      if (widget.testExamPaper?.questions != null && store.testQuePallete != null) {
        widget.testExamPaper?.questions = widget.testExamPaper?.questions?.map((question) {
          final questionIdToMatch = question.sId;
          if (store.testQuePallete.isEmpty) {
            question.statusColor = _notVisitedColor(context).value;
            question.txtColor = AppTokens.ink2(context).value;
          } else {
            dynamic matchingQuestion;
            try {
              matchingQuestion = store.testQuePallete.firstWhere(
                (item) => item?.questionId == questionIdToMatch,
              );
            } catch (_) {
              matchingQuestion = null;
            }

            if (matchingQuestion != null) {
              if (matchingQuestion.isAttempted == true) {
                question.statusColor = _attemptedColor.value;
                question.txtColor = Colors.white.value;
              } else if (matchingQuestion.isMarkedForReview == true) {
                question.statusColor = _markedColor.value;
                question.txtColor = Colors.white.value;
              } else if (matchingQuestion.isAttemptedMarkedForReview == true) {
                question.statusColor = _attemptedMarkedColor.value;
                question.txtColor = Colors.white.value;
              } else if (matchingQuestion.isSkipped == true) {
                question.statusColor = _skippedColor.value;
                question.txtColor = Colors.white.value;
              } else if (matchingQuestion.isGuess == true) {
                question.statusColor = _guessColor.value;
                question.txtColor = Colors.white.value;
              }
            } else {
              question.statusColor = _notVisitedColor(context).value;
              question.txtColor = AppTokens.ink2(context).value;
            }
          }
          return question;
        }).toList();
      }
    });
  }

  Color _notVisitedColor(BuildContext context) => AppTokens.surface3(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _getQuesPallete());
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.testExamPaper?.questions ?? [];
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppTokens.scaffold(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTokens.ink(context), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text("Question palette", style: AppTokens.titleLg(context)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppTokens.s24, AppTokens.s8, AppTokens.s24, AppTokens.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Legend grid — two columns, soft surface card.
              Container(
                padding: const EdgeInsets.all(AppTokens.s16),
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  borderRadius: AppTokens.radius16,
                  border: Border.all(color: AppTokens.border(context), width: 0.5),
                ),
                child: Wrap(
                  runSpacing: AppTokens.s12,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.42,
                      child: _LegendRow(color: _attemptedColor, label: "Attempted"),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.42,
                      child: _LegendRow(color: _markedColor, label: "Marked"),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.42,
                      child: _LegendRow(color: _attemptedMarkedColor, label: "Attempted + Marked"),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.42,
                      child: _LegendRow(color: _skippedColor, label: "Skipped"),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.42,
                      child: _LegendRow(color: _guessColor, label: "Guess"),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.42,
                      child: _LegendRow(color: AppTokens.surface3(context), label: "Not visited"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.s20),

              // Question grid.
              Expanded(
                child: Wrap(
                  spacing: AppTokens.s8,
                  runSpacing: AppTokens.s8,
                  children: List.generate(questions.length, (index) {
                    final q = questions[index];
                    final fillColor = Color(q.statusColor ?? AppTokens.surface3(context).value);
                    final textColor = Color(q.txtColor ?? AppTokens.ink2(context).value);
                    return InkWell(
                      borderRadius: AppTokens.radius12,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          Routes.featuredTestExamPage,
                          arguments: {
                            'queNo': q.questionNumber,
                            'featuredTestData': widget.testExamPaper,
                            'userexamId': widget.userExamId,
                            'remainingTime': widget.remainingTime,
                            'fromPallete': true,
                          },
                        );
                      },
                      child: Container(
                        height: 44,
                        width: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: AppTokens.radius12,
                          border: Border.all(
                            color: AppTokens.border(context),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          "${index + 1}",
                          style: AppTokens.titleSm(context).copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }),
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
  const _LegendRow({Key? key, required this.color, required this.label}) : super(key: key);
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
        const SizedBox(width: AppTokens.s8),
        Flexible(
          child: Text(
            label,
            style: AppTokens.caption(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
