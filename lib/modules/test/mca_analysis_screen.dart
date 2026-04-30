// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names, dead_code, unused_element

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/masterTest/master_test_report_details_screen.dart';
import 'package:shusruta_lms/modules/new_exam_component/answer_widget.dart';
import 'package:shusruta_lms/modules/new_exam_component/topic_wise_widget.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';

/// MCQ analysis screen — 3-tab breakdown (Edumetrics, Guess Analytics,
/// Answer Evolve) for a completed MCQ exam.
///
/// Preserved public contract:
///   • `McqAnalysisScreen({super.key, required testExamPaperListModel,
///     required id})`
///   • `store.mcqAnalysis(id)` in initState.
///   • Tabs: "Edumetrics", "Guess Analytics", "Answer Evolve" — order and
///     labels preserved verbatim.
///   • Uses `buildStatColumn(label, color)` (topic_wise_widget.dart) and
///     `formatTimeString(value)` (master_test_report_details_screen.dart).
///   • Edumetrics data: correctAnswers / skippedAnswers /
///     incorrectAnswers + totalQuestions + accuracyPercentage +
///     totalTime, with legend text "Correct (X)", "Skipped (X)",
///     "Incorrect (X)" and detail cards "Accuracy" / "Time Taken".
///   • Guess Analytics data: correctGuessCount / wrongGuessCount +
///     guessedAnswersCount, detail cards "Correct Answer" / "Incorrect
///     Answer".
///   • Answer Evolve data: incorrect_correct / correct_incorrect, detail
///     cards "Incorrect to Correct" / "Correct to Incorrect".
///   • Title text: "${examName}  Analysis" (preserves double-space).
///   • Top-level helpers retained: `_buildDetail`, `_getProgress`,
///     `_getColor`.
class McqAnalysisScreen extends StatefulWidget {
  const McqAnalysisScreen({
    super.key,
    required this.testExamPaperListModel,
    required this.id,
  });
  final TestExamPaperListModel testExamPaperListModel;
  final String id;

  @override
  State<McqAnalysisScreen> createState() => _McqAnalysisScreenState();
}

class _McqAnalysisScreenState extends State<McqAnalysisScreen>
    with TickerProviderStateMixin {
  bool isFinished = false;
  bool isRank1 = false;
  TabController? tabController;
  late TestCategoryStore store;

  @override
  void initState() {
    init();
    tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  void init() async {
    store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.mcqAnalysis(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Platform.isWindows || Platform.isMacOS;
    final store = Provider.of<TestCategoryStore>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                AppTokens.s8,
                AppTokens.s20,
                AppTokens.s20,
              ),
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: isDesktop
                    ? null
                    : const BorderRadius.only(
                        topLeft: Radius.circular(AppTokens.r28),
                        topRight: Radius.circular(AppTokens.r28),
                      ),
              ),
              child: Observer(builder: (context) {
                if (store.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTokens.accent(context),
                    ),
                  );
                }
                return Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      controller: tabController,
                      labelColor: AppTokens.accent(context),
                      unselectedLabelColor: AppTokens.muted(context),
                      indicatorColor: AppTokens.accent(context),
                      labelStyle: AppTokens.caption(context).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: AppTokens.caption(context).copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(text: "Edumetrics"),
                        Tab(text: "Guess Analytics"),
                        Tab(text: "Answer Evolve"),
                      ],
                    ),
                    const SizedBox(height: AppTokens.s12),
                    Expanded(
                      child: TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        controller: tabController,
                        children: [
                          _buildEdumetrics(context, store),
                          _buildGuessAnalytics(context, store),
                          _buildAnswerEvolve(context, store),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTokens.s8,
        (Platform.isWindows || Platform.isMacOS)
            ? AppTokens.s16
            : MediaQuery.of(context).padding.top + AppTokens.s8,
        AppTokens.s20,
        AppTokens.s20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(AppTokens.r8),
            child: Container(
              height: AppTokens.s32,
              width: AppTokens.s32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              "${widget.testExamPaperListModel.examName ?? ""}  Analysis",
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset("assets/image/badge.svg", height: 20, width: 20),
              const SizedBox(width: AppTokens.s12),
              Text(
                title,
                style: AppTokens.titleSm(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          ...children,
        ],
      ),
    );
  }

  Widget _segmentedBar(List<_BarSegment> segments) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          child: LinearProgressIndicator(
            value: 1.0,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.grey),
            backgroundColor: Colors.grey.shade300,
            minHeight: 6,
          ),
        ),
        Row(
          children: [
            for (int i = 0; i < segments.length; i++)
              Flexible(
                flex: segments[i].flex,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: segments[i].color,
                    borderRadius: BorderRadius.horizontal(
                      left: i == 0
                          ? const Radius.circular(AppTokens.r12)
                          : Radius.zero,
                      right: i == segments.length - 1
                          ? const Radius.circular(AppTokens.r12)
                          : Radius.zero,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEdumetrics(BuildContext context, TestCategoryStore store) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppTokens.s12),
          _sectionCard(
            context,
            title: "Edumetrics",
            children: [
              _segmentedBar([
                _BarSegment(
                  flex: store.mcqExamReport.value!.correctAnswers,
                  color: Colors.green,
                ),
                _BarSegment(
                  flex: store.mcqExamReport.value!.skippedAnswers,
                  color: Colors.orange,
                ),
                _BarSegment(
                  flex: store.mcqExamReport.value!.incorrectAnswers,
                  color: Colors.yellow,
                ),
              ]),
              const SizedBox(height: AppTokens.s12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Total Questions  ",
                      style: AppTokens.body(context).copyWith(
                        color: AppTokens.ink(context),
                      ),
                    ),
                    Text(
                      "${store.mcqExamReport.value!.totalQuestions}",
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTokens.ink(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.s16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  buildStatColumn(
                    'Correct (${store.mcqExamReport.value!.correctAnswers})',
                    Colors.green,
                  ),
                  buildStatColumn(
                    'Skipped (${store.mcqExamReport.value!.skippedAnswers})',
                    Colors.orange,
                  ),
                  buildStatColumn(
                    'Incorrect (${store.mcqExamReport.value!.incorrectAnswers})',
                    Colors.yellow,
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s20),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailCard(
                      context,
                      label: "Accuracy",
                      value:
                          "${store.mcqExamReport.value!.accuracyPercentage}%",
                      path: 'assets/image/accu_p.svg',
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: _buildDetailCard(
                      context,
                      label: "Time Taken",
                      value: formatTimeString(
                          store.mcqExamReport.value!.totalTime),
                      path: 'assets/image/clock.svg',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuessAnalytics(BuildContext context, TestCategoryStore store) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppTokens.s12),
          _sectionCard(
            context,
            title: "Guess Analytics",
            children: [
              _segmentedBar([
                _BarSegment(
                  flex: store.mcqExamReport.value!.correctGuessCount,
                  color: Colors.green,
                ),
                _BarSegment(
                  flex: store.mcqExamReport.value!.wrongGuessCount,
                  color: Colors.red,
                ),
              ]),
              const SizedBox(height: AppTokens.s12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Guessed Answers  ",
                      style: AppTokens.body(context).copyWith(
                        color: AppTokens.ink(context),
                      ),
                    ),
                    Text(
                      "${store.mcqExamReport.value!.guessedAnswersCount}",
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTokens.ink(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.s16),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailCard(
                      context,
                      label: "Correct Answer",
                      value:
                          "${store.mcqExamReport.value!.correctGuessCount}",
                      path: 'assets/image/up_trend.svg',
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: _buildDetailCard(
                      context,
                      label: "Incorrect Answer",
                      value: "${store.mcqExamReport.value!.wrongGuessCount}",
                      path: 'assets/image/down_trend.svg',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerEvolve(BuildContext context, TestCategoryStore store) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppTokens.s12),
          _sectionCard(
            context,
            title: "Answer Evolve",
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDetailCard(
                      context,
                      label: "Incorrect to Correct",
                      value:
                          "${store.mcqExamReport.value!.incorrect_correct}",
                      path: 'assets/image/down_trend.svg',
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: _buildDetailCard(
                      context,
                      label: "Correct to Incorrect",
                      value:
                          "${store.mcqExamReport.value!.correct_incorrect}",
                      path: 'assets/image/up_trend.svg',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarSegment {
  final int flex;
  final Color color;
  const _BarSegment({required this.flex, required this.color});
}

double _getProgress(String rankRange) {
  final startRank = int.parse(rankRange.split('-')[0].trim());
  if (startRank <= 50) {
    return 0.8;
  } else if (startRank > 50 && startRank <= 5000) {
    return 0.6;
  } else {
    return 0.3;
  }
}

Color _getColor(String rankRange) {
  final startRank = int.parse(rankRange.split('-')[0].trim());
  if (startRank <= 50) {
    return Colors.green;
  } else if (startRank > 50 && startRank <= 5000) {
    return Colors.orange;
  } else {
    return Colors.red;
  }
}

Widget _buildDetailCard(
  BuildContext context, {
  required String label,
  required String value,
  required String path,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppTokens.s12,
      vertical: AppTokens.s8,
    ),
    decoration: BoxDecoration(
      color: AppTokens.surface2(context),
      borderRadius: BorderRadius.circular(AppTokens.r12),
      border: Border.all(color: AppTokens.border(context)),
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
              style: AppTokens.caption(context).copyWith(
                fontWeight: FontWeight.w500,
                color: AppTokens.muted(context),
              ),
            ),
            const SizedBox(height: AppTokens.s4),
            Text(
              value,
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
            ),
          ],
        ),
        SvgPicture.asset(path, height: 20, width: 20),
      ],
    ),
  );
}

/// Kept for legacy external callers — delegates to `_buildDetailCard`.
Widget _buildDetail(String label, String value, String path) {
  return Builder(
    builder: (context) => _buildDetailCard(
      context,
      label: label,
      value: value,
      path: path,
    ),
  );
}
