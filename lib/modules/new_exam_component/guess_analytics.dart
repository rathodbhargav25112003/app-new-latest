// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/models/exam_report.dart';
import 'package:shusruta_lms/models/trend_analysis_model.dart';
import 'package:shusruta_lms/modules/new_exam_component/custome_progress.dart';

/// Guess Analytics card shown on the exam report screen.
///
/// Preserved public contract:
///   • Constructor `GuessAnalytics({super.key, required String
///     headerTitle, required ExamReport examReport})` — same fields
///     and order.
///   • Reads `examReport.correctGuessCount ?? 0`,
///     `examReport.wrongGuessCount ?? 0`, and `examReport.question`
///     verbatim so the existing data pipeline flows through unchanged.
///   • Segment palette preserved: Correct = green, Incorrect = red.
class GuessAnalytics extends StatelessWidget {
  const GuessAnalytics({
    super.key,
    required this.headerTitle,
    required this.examReport,
  });

  final String headerTitle;
  final ExamReport examReport;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppTokens.s16),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppTokens.s8,
              horizontal: AppTokens.s24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTokens.brand, AppTokens.brand2],
              ),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(AppTokens.r8),
                topLeft: Radius.circular(AppTokens.r8),
              ),
            ),
            child: Text(
              headerTitle,
              style: AppTokens.caption(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppTokens.s16),
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              border: Border.all(color: AppTokens.border(context)),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppTokens.r12),
                bottomLeft: Radius.circular(AppTokens.r12),
                bottomRight: Radius.circular(AppTokens.r12),
              ),
              boxShadow: AppTokens.shadow2(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTokens.s4),
                Row(
                  children: [
                    SvgPicture.asset('assets/image/badge.svg'),
                    const SizedBox(width: AppTokens.s16),
                    Text(
                      'Guess Analytics',
                      style: AppTokens.titleSm(context).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s16),
                DynamicProgressBar(
                  progressItems: [
                    ProgressItem(
                      color: Colors.green,
                      label: 'Correct',
                      value: examReport.correctGuessCount ?? 0,
                    ),
                    ProgressItem(
                      color: Colors.red,
                      label: 'Incorrect',
                      value: examReport.wrongGuessCount ?? 0,
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Total Questions  ',
                      style: AppTokens.body(context).copyWith(
                        color: AppTokens.muted(context),
                      ),
                    ),
                    Text(
                      '${examReport.question}',
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTokens.ink(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildDetail(
                        'Correct',
                        '${examReport.correctGuessCount}',
                        'assets/image/up_trend.svg',
                      ),
                    ),
                    const SizedBox(width: AppTokens.s16),
                    Expanded(
                      child: _buildDetail(
                        'Incorrect',
                        '${examReport.wrongGuessCount}',
                        'assets/image/down_trend.svg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// File-private helper (underscore prefix preserved). Wrapped in a
/// `Builder` so it can still reach `BuildContext` for theme tokens
/// without changing its positional call-site signature.
Widget _buildDetail(String label, String value, String path) {
  return Builder(
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTokens.border(context)),
          borderRadius: BorderRadius.circular(AppTokens.r12),
          color: AppTokens.surface2(context),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s12,
            vertical: AppTokens.s8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTokens.overline(context).copyWith(
                      color: AppTokens.muted(context),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTokens.titleSm(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTokens.ink(context),
                      height: 1,
                    ),
                  ),
                ],
              ),
              SvgPicture.asset(path, height: 32, width: 32),
            ],
          ),
        ),
      );
    },
  );
}

/// Per-exam "Guess Analytics" trend (correct/incorrect guess counts +
/// total guessed answers).
///
/// Preserved contract:
///   • Constructor `TrendGuessWidget({super.key, required
///     List&lt;TrendAnalysisModel&gt; trendAnalysisModel})`
///   • `NeverScrollableScrollPhysics` + `shrinkWrap: true` ListView
///     with `EdgeInsets.zero` padding.
///   • "Not Attempted" fallback when `!trendAnalysisModel[i].isAttempt`,
///     otherwise a `DynamicProgressBar` (Correct=green / Incorrect=red)
///     above a "Guessed Answers" counter that reads
///     `trendAnalysisModel[i].guessedAnswersCount`.
class TrendGuessWidget extends StatelessWidget {
  const TrendGuessWidget({super.key, required this.trendAnalysisModel});

  final List<TrendAnalysisModel> trendAnalysisModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTokens.s20),
          Container(
            padding: const EdgeInsets.all(AppTokens.s16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTokens.border(context)),
              color: AppTokens.surface(context),
              borderRadius: BorderRadius.circular(AppTokens.r12),
              boxShadow: AppTokens.shadow1(context),
            ),
            child: Row(
              children: [
                SvgPicture.asset('assets/image/badge.svg'),
                const SizedBox(width: AppTokens.s8),
                Text(
                  'Guess Analytics',
                  style: AppTokens.titleSm(context).copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          ListView.builder(
            itemCount: trendAnalysisModel.length,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final item = trendAnalysisModel[index];
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppTokens.s16),
                child: Row(
                  children: [
                    Container(
                      height: 96,
                      width: 32,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppTokens.brand, AppTokens.brand2],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppTokens.r12),
                          bottomLeft: Radius.circular(AppTokens.r12),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'Exam ${index + 1}',
                          style: AppTokens.caption(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppTokens.surface(context),
                          border: Border.all(color: AppTokens.border(context)),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(AppTokens.r12),
                            bottomRight: Radius.circular(AppTokens.r12),
                          ),
                          boxShadow: AppTokens.shadow1(context),
                        ),
                        child: !item.isAttempt
                            ? Center(
                                child: Text(
                                  'Not Attempted',
                                  style:
                                      AppTokens.caption(context).copyWith(
                                    color: AppTokens.muted(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppTokens.s12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: AppTokens.s4),
                                    DynamicProgressBar(
                                      progressItems: [
                                        ProgressItem(
                                          color: Colors.green,
                                          label: 'Correct',
                                          value: item.correctGuessCount,
                                        ),
                                        ProgressItem(
                                          color: Colors.red,
                                          label: 'Incorrect',
                                          value: item.wrongGuessCount,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppTokens.s8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Guessed Answers ',
                                          style: AppTokens.body(context)
                                              .copyWith(
                                            color: AppTokens.muted(context),
                                          ),
                                        ),
                                        Text(
                                          item.guessedAnswersCount.toString(),
                                          style: AppTokens.body(context)
                                              .copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppTokens.ink(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
