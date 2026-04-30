// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/models/exam_report.dart';
import 'package:shusruta_lms/models/trend_analysis_model.dart';

/// Answer-evolve analytics card shown on the exam report screen.
///
/// Preserved public contract:
///   • Constructor `AnswerAnalytics({super.key, required headerTitle,
///     required examReport})` — same fields and order.
///   • Still reads `examReport.correct_incorrect` and
///     `examReport.incorrect_incorres` verbatim so the existing data
///     pipeline flows through unchanged.
class AnswerAnalytics extends StatelessWidget {
  const AnswerAnalytics({
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
                      'Answer Evolve',
                      style: AppTokens.titleSm(context).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: buildDetail(
                        'Correct',
                        '${examReport.correct_incorrect}',
                        'assets/image/up_trend.svg',
                      ),
                    ),
                    const SizedBox(width: AppTokens.s16),
                    Expanded(
                      child: buildDetail(
                        'Incorrect',
                        '${examReport.incorrect_incorres}',
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

/// Public helper retained — used internally by `AnswerAnalytics` and
/// potentially by external callers that imported it directly.
Widget buildDetail(String label, String value, String path) {
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
              SvgPicture.asset(path),
            ],
          ),
        ),
      );
    },
  );
}

/// Public helper retained (variant of `buildDetail` used by
/// `AnswerAnalysisWidget`).
Widget buildDetail2(String label, String value, String path) {
  return Builder(
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTokens.border(context)),
          borderRadius: BorderRadius.circular(AppTokens.r8),
          color: AppTokens.surface2(context),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s8,
            vertical: AppTokens.s8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(path, height: 32, width: 32),
              const SizedBox(width: AppTokens.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: AppTokens.titleSm(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTokens.ink(context),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: AppTokens.overline(context).copyWith(
                        color: AppTokens.muted(context),
                        height: 1,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Per-exam "Answer Evolve" trend (correct↔incorrect counts).
///
/// Preserved contract:
///   • Constructor `AnswerAnalysisWidget({super.key, required
///     List&lt;TrendAnalysisModel&gt; trendAnalysisModel})`
///   • `NeverScrollableScrollPhysics` + `shrinkWrap: true` ListView
///   • "Not Attempted" fallback when `!isAttempt`, else two
///     `buildDetail2` columns (Correct→Incorrect and Incorrect→Correct)
class AnswerAnalysisWidget extends StatelessWidget {
  const AnswerAnalysisWidget({super.key, required this.trendAnalysisModel});

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
                  'Answer Evolve',
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
                                    horizontal: AppTokens.s16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: buildDetail2(
                                          'Correct to Incorrect',
                                          '${item.correctIncorrect}',
                                          'assets/image/up_trend.svg',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppTokens.s16),
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: buildDetail2(
                                          'Incorrect to Correct',
                                          '${item.incorrectIncorres}',
                                          'assets/image/down_trend.svg',
                                        ),
                                      ),
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
