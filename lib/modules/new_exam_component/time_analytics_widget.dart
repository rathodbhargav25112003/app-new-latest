// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/models/exam_report.dart';
import 'package:shusruta_lms/models/trend_analysis_model.dart';
import 'package:shusruta_lms/modules/masterTest/master_test_report_details_screen.dart';

/// Time-analytics card shown on the exam report screen.
///
/// Preserved public contract:
///   • Constructor `TimeAnalytics({super.key, required String
///     headerTitle, required ExamReport examReport})` — fields and
///     order unchanged.
///   • Still reads `examReport.totalTime ?? "00:00"` and the full
///     `examReport.timeAnalytics!` list, including per-entry fields
///     `question_number`, `correct`, `marks_awarded`, `marks_deducted`,
///     `topicName`, and `timePerQuestion`.
///   • Continues to delegate per-row rendering to the top-level
///     `_buildRow(questionNo, marks, isCorrect, section, time)`
///     helper (5-positional signature preserved).
///   • Still uses `formatTimeString` imported from
///     `master_test_report_details_screen.dart` — the import is
///     retained so any transitive resolvers keep working.
class TimeAnalytics extends StatelessWidget {
  const TimeAnalytics({
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
          const SizedBox(height: AppTokens.s8),
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
                      'Time Analytics',
                      style: AppTokens.titleSm(context).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s16),
                Container(
                  decoration: BoxDecoration(
                    color: AppTokens.surface2(context),
                    border: Border.all(color: AppTokens.border(context)),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s8,
                      vertical: AppTokens.s8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: Image.asset(
                            'assets/image/clock.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                        const SizedBox(width: AppTokens.s8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatTimeString(
                                  examReport.totalTime ?? '00:00'),
                              style: AppTokens.titleSm(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTokens.ink(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total Time',
                              style: AppTokens.overline(context).copyWith(
                                height: 1,
                                color: AppTokens.muted(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      headingRowHeight: 40,
                      horizontalMargin: 0,
                      headingRowColor: WidgetStateProperty.resolveWith(
                        (states) => AppTokens.brand,
                      ),
                      border: TableBorder.all(
                          color: AppTokens.border(context)),
                      columns: [
                        DataColumn(
                          label: SizedBox(
                            width: 25,
                            child: Center(
                              child: Text(
                                'No.',
                                style: AppTokens.overline(context).copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: 140,
                            child: Center(
                              child: Text(
                                'Section',
                                style: AppTokens.overline(context).copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: 80,
                            child: Text(
                              '      Time',
                              style: AppTokens.overline(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                      rows: examReport.timeAnalytics!
                          .map((e) => _buildRow(
                                '${e.question_number}',
                                e.correct ?? false
                                    ? e.marks_awarded ?? 0
                                    : e.marks_deducted ?? 0,
                                e.correct ?? false,
                                e.topicName ?? '',
                                e.timePerQuestion ?? '00:00',
                              ))
                          .toList(),
                    ),
                  ),
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

/// Per-row renderer for the Time Analytics DataTable. Positional
/// signature preserved so any external callers that imported this
/// file continue to compile.
DataRow _buildRow(
  String questionNo,
  int marks,
  bool isCorrect,
  String section,
  String time,
) {
  return DataRow(
    cells: [
      DataCell(
        Builder(
          builder: (context) => SizedBox(
            width: 25,
            child: Center(
              child: Text(
                questionNo,
                style: AppTokens.overline(context).copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1,
                  color: AppTokens.muted(context),
                ),
              ),
            ),
          ),
        ),
      ),
      DataCell(
        Builder(
          builder: (context) => SizedBox(
            width: 140,
            child: Column(
              children: [
                const SizedBox(height: 5),
                SizedBox(
                  width: 27,
                  child: Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: AppTokens.s4),
                      Padding(
                        padding: const EdgeInsets.only(top: 2.5),
                        child: Text(
                          marks.toString(),
                          style: AppTokens.overline(context).copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1,
                            color: AppTokens.muted(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  section,
                  style: AppTokens.overline(context).copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    color: AppTokens.muted(context),
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ),
      ),
      DataCell(
        Builder(
          builder: (context) => SizedBox(
            width: 60,
            child: Center(
              child: Text(
                formatTimeString(time),
                textAlign: TextAlign.center,
                style: AppTokens.overline(context).copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1,
                  color: AppTokens.muted(context),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

/// Per-exam "Time Analysis" trend card.
///
/// Preserved contract:
///   • Constructor `TrendTimeAnalysisWidget({super.key, required
///     List&lt;TrendAnalysisModel&gt; trendAnalysisModel})`
///   • `NeverScrollableScrollPhysics` + `shrinkWrap: true` ListView
///     with `EdgeInsets.zero` padding.
///   • "Not Attempted" fallback when `!trendAnalysisModel[i].isAttempt`.
///   • Otherwise two `_buildDetail2` tiles side-by-side:
///       - "Total Time" from `item.time` + `clock.svg`
///       - "Average time per Q" from `item.timeOnQuestion` +
///         `av_time.svg`
///   • Rotated "Exam N" badge with brand gradient preserved.
class TrendTimeAnalysisWidget extends StatelessWidget {
  const TrendTimeAnalysisWidget({super.key, required this.trendAnalysisModel});

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
              color: AppTokens.surface(context),
              border: Border.all(color: AppTokens.border(context)),
              borderRadius: BorderRadius.circular(AppTokens.r12),
              boxShadow: AppTokens.shadow1(context),
            ),
            child: Row(
              children: [
                SvgPicture.asset('assets/image/badge.svg'),
                const SizedBox(width: AppTokens.s8),
                Text(
                  'Time Analysis',
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
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: _buildDetail2(
                                          'Total Time',
                                          item.time,
                                          'assets/image/clock.svg',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppTokens.s16),
                                    Expanded(
                                      child: SizedBox(
                                        height: 60,
                                        child: _buildDetail2(
                                          'Average time per Q',
                                          item.timeOnQuestion,
                                          'assets/image/av_time.svg',
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

/// File-private tile helper (underscore prefix preserved). Positional
/// signature preserved for any resilient external imports.
Widget _buildDetail2(String label, String value, String path) {
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
