// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/models/exam_attempts_model.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/masterTest/custom_master_test_bottom_sheet_window.dart';
import 'package:shusruta_lms/modules/new_exam_component/exam_report_screen.dart';
import 'package:shusruta_lms/modules/new_exam_component/instruction_page.dart';
import 'package:shusruta_lms/modules/new_exam_component/widget/loading_box.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/modules/reports/trend_analysis_list.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/widgets/no_access_alert_dialog.dart';
import 'package:shusruta_lms/modules/widgets/no_access_bottom_sheet.dart';

/// Post-attempt status card — redesigned with AppTokens. Preserves the
/// full constructor surface (testExamPaperListModel, examAttemptsModel,
/// type, id, count, showPredictive, isTrend), TickerProviderStateMixin
/// + internal TabController tied to attemptList, the hasRemainingAttempts
/// / isAlwaysLive / isWithinTimeWindow gating for "Attempt Now", and
/// every navigation target:
///   • ExamReportScreen via CupertinoPageRoute
///   • Routes.solutionMasterReport via pushNamed (with ReportsCategoryStore.onMasterSolutionReportApiCall)
///   • GetTrendAnalysisList via CupertinoPageRoute when isTrend
///   • Routes.startSectionInstructionScreen for sectioned exams
///   • CustomMasterTestBottomSheetWindow wrapped in AlertDialog on desktop
///   • InstructionScreen via CupertinoPageRoute on mobile
///   • NoAccessAlertDialog / NoAccessBottomSheet for locked exams
///   • _generateReport helper kept verbatim (unused but preserved)
class ExamStatusCard extends StatefulWidget {
  const ExamStatusCard({
    super.key,
    required this.testExamPaperListModel,
    required this.examAttemptsModel,
    required this.type,
    required this.id,
    this.count,
    required this.showPredictive,
    required this.isTrend,
  });
  final TestExamPaperListModel testExamPaperListModel;
  final ExamAttemptsModel examAttemptsModel;
  final String type;
  final String id;
  final int? count;
  final bool showPredictive;
  final bool isTrend;

  @override
  State<ExamStatusCard> createState() => _ExamStatusCardState();
}

class _ExamStatusCardState extends State<ExamStatusCard>
    with TickerProviderStateMixin {
  TabController? tabController;

  @override
  void initState() {
    tabController = TabController(
      length: widget.examAttemptsModel.attemptList.length,
      vsync: this,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasRemainingAttempts = (widget.count ??
            widget.testExamPaperListModel.remainingAttempts ??
            0) >
        0;
    final bool isAlwaysLive = widget.examAttemptsModel.fromtime == '';
    bool isWithinTimeWindow = false;

    if (!isAlwaysLive &&
        widget.examAttemptsModel.fromtime != '' &&
        widget.examAttemptsModel.totime != '') {
      final DateTime now = DateTime.now();
      final DateTime fromTime =
          DateTime.parse(widget.examAttemptsModel.fromtime);
      final DateTime toTime = DateTime.parse(widget.examAttemptsModel.totime);
      isWithinTimeWindow =
          now.isAfter(fromTime.subtract(const Duration(seconds: 1))) &&
              now.isBefore(toTime.add(const Duration(seconds: 1)));
    }

    final int attemptCount = widget.examAttemptsModel.attemptList.length;

    return DefaultTabController(
      length: attemptCount,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          borderRadius: AppTokens.radius16,
          border: Border.all(color: AppTokens.border(context)),
          boxShadow: AppTokens.shadow1(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + last attempt
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
                    widget.testExamPaperListModel.examName ?? "",
                    style: AppTokens.titleSm(context),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Last Test Mode Attempt : ${widget.examAttemptsModel.lastTime}",
                    style: AppTokens.caption(context),
                  ),
                ],
              ),
            ),
            // Attempts card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTokens.surface2(context),
                  borderRadius: AppTokens.radius12,
                  border: Border.all(color: AppTokens.border(context)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      controller: tabController,
                      labelColor: AppTokens.accent(context),
                      unselectedLabelColor: AppTokens.muted(context),
                      indicatorColor: AppTokens.accent(context),
                      dividerColor: AppTokens.border(context),
                      labelStyle: AppTokens.caption(context).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: AppTokens.caption(context),
                      tabs: widget.examAttemptsModel.attemptList
                          .map((e) => Tab(text: "Attempt ${e.isAttemptcount}"))
                          .toList(),
                    ),
                    SizedBox(
                      height: widget.testExamPaperListModel.isDeclaration!
                          ? 330
                          : 270,
                      child: TabBarView(
                        controller: tabController,
                        children: widget.examAttemptsModel.attemptList
                            .map((e) => _buildTabContent(e))
                            .toList(),
                      ),
                    ),
                    if (widget.testExamPaperListModel.isAttempt!) ...[
                      Divider(
                        color: AppTokens.border(context),
                        height: 1,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTokens.s12,
                          horizontal: AppTokens.s8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ActionChip(
                              icon: Icons.insights_rounded,
                              label: "Analysis",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => ExamReportScreen(
                                      testExamPaperListModel:
                                          widget.testExamPaperListModel,
                                      id: widget
                                          .examAttemptsModel
                                          .attemptList[tabController!.index]
                                          .userExamId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: AppTokens.s8),
                            _ActionChip(
                              icon: Icons.menu_book_rounded,
                              label: "Review",
                              onTap: () async {
                                showLoadingDialog(context);
                                final store = Provider.of<ReportsCategoryStore>(
                                  context,
                                  listen: false,
                                );
                                await store
                                    .onMasterSolutionReportApiCall(
                                  widget
                                      .examAttemptsModel
                                      .attemptList[tabController!.index]
                                      .userExamId,
                                )
                                    .then((_) {
                                  Navigator.pop(context);
                                  Navigator.of(context).pushNamed(
                                    Routes.solutionMasterReport,
                                    arguments: {
                                      'solutionReport':
                                          store.masterSolutionReportCategory,
                                      'filterVal': "View all",
                                      'userExamId': widget
                                          .examAttemptsModel
                                          .attemptList[tabController!.index]
                                          .userExamId,
                                    },
                                  );
                                });
                              },
                            ),
                            if (widget.isTrend) ...[
                              const SizedBox(width: AppTokens.s8),
                              _ActionChip(
                                icon: Icons.trending_up_rounded,
                                label: "Series Analytics",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          GetTrendAnalysisList(
                                        id: widget
                                            .testExamPaperListModel.categoryId!,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Attempt Now CTA
            if (hasRemainingAttempts &&
                (isAlwaysLive || isWithinTimeWindow)) ...[
              const SizedBox(height: AppTokens.s12),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s16,
                  0,
                  AppTokens.s16,
                  AppTokens.s16,
                ),
                child: _AttemptNowCta(
                  label: widget.examAttemptsModel.fromtime == ''
                      ? "Attempt Now"
                      : "Attempt Now (${widget.count ?? widget.testExamPaperListModel.remainingAttempts} Remaining)",
                  onTap: () => _onAttemptNowTap(context),
                ),
              ),
            ] else
              const SizedBox(height: AppTokens.s16),
          ],
        ),
      ),
    );
  }

  void _onAttemptNowTap(BuildContext context) {
    if (widget.testExamPaperListModel.isAccess == true) {
      if (widget.testExamPaperListModel.isSection == true) {
        Navigator.of(context).pushNamed(
          Routes.startSectionInstructionScreen,
          arguments: {
            'testExamPaper': widget.testExamPaperListModel,
            'id': widget.testExamPaperListModel.examId,
            'type': widget.type,
            'isPractice': false,
            'showPredictive': widget.showPredictive,
          },
        );
      } else {
        if (Platform.isWindows || Platform.isMacOS) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: AppTokens.scaffold(context),
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 100),
                actionsPadding: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppTokens.radius20,
                ),
                actions: [
                  CustomMasterTestBottomSheetWindow(
                    context,
                    widget.testExamPaperListModel,
                    widget.testExamPaperListModel.examId,
                    widget.type,
                    false,
                    isWindow: true,
                    widget.showPredictive,
                  ),
                ],
              );
            },
          );
        } else {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => InstructionScreen(
                isTrend: widget.isTrend,
                showPredictive: widget.showPredictive,
                testExamPaperListModel: widget.testExamPaperListModel,
                type: widget.type,
              ),
            ),
          );
        }
      }
    } else {
      if (Platform.isWindows || Platform.isMacOS) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppTokens.scaffold(context),
              actionsPadding: EdgeInsets.zero,
              insetPadding: const EdgeInsets.symmetric(horizontal: 100),
              shape: const RoundedRectangleBorder(
                borderRadius: AppTokens.radius20,
              ),
              actions: [
                NoAccessAlertDialog(
                  planId: widget.testExamPaperListModel.plan_id ?? "",
                  day: int.parse(widget.testExamPaperListModel.day ?? "0"),
                  isFree: widget.testExamPaperListModel.isfreeTrail!,
                ),
              ],
            );
          },
        );
      } else {
        showModalBottomSheet<void>(
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          context: context,
          builder: (BuildContext context) {
            return NoAccessBottomSheet(
              planId: widget.testExamPaperListModel.plan_id ?? "",
              day: int.parse(widget.testExamPaperListModel.day ?? "0"),
              isFree: widget.testExamPaperListModel.isfreeTrail!,
            );
          },
        );
      }
    }
  }

  Widget _buildTabContent(Attempt attempt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat(
                  "Rank",
                  !widget.testExamPaperListModel.isDeclaration!
                      ? attempt.userRank.toString()
                      : "--",
                  'assets/image/rank.svg'),
              _buildStat("Marks", "${attempt.mymark} / ${attempt.totalMarks}",
                  'assets/image/win.svg'),
              _buildStat("Accuracy", "${attempt.accuracyPercentage}%",
                  'assets/image/accuracy1.svg'),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          Container(
            padding: const EdgeInsets.all(AppTokens.s8),
            decoration: BoxDecoration(
              color: AppTokens.accentSoft(context),
              borderRadius: AppTokens.radius8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  "assets/image/pre.svg",
                  height: 21,
                  width: 21,
                ),
                const SizedBox(width: AppTokens.s8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Predicted NEET SS Rank",
                      style: AppTokens.caption(context),
                    ),
                    Text(
                      !widget.testExamPaperListModel.isDeclaration!
                          ? attempt.predictedrank2024.toString()
                          : "--",
                      style: AppTokens.titleSm(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.testExamPaperListModel.isDeclaration!) ...[
            const SizedBox(height: AppTokens.s12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s12,
                vertical: AppTokens.s8,
              ),
              decoration: BoxDecoration(
                borderRadius: AppTokens.radius8,
                color: AppTokens.dangerSoft(context),
                border: Border.all(
                  color: AppTokens.danger(context).withOpacity(0.3),
                ),
              ),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:
                          "Rank will be displayed after Result Declaration\non ",
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.ink2(context),
                      ),
                    ),
                    TextSpan(
                      text: DateFormat('dd MMM | hh:mm').format(DateTime.parse(
                          widget.testExamPaperListModel.declarationTime!)),
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.ink(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppTokens.s16),
          Row(
            children: [
              Expanded(
                child: _buildDetail(
                  "Attempted",
                  "${attempt.isAttemptcount}",
                  'assets/image/attempted.svg',
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: _buildDetail(
                  "Skipped",
                  "${attempt.skippedAnswers}",
                  'assets/image/skipped.svg',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Row(
            children: [
              Expanded(
                child: _buildDetail(
                  "Correct",
                  "${attempt.correctAnswers}",
                  'assets/image/correct.svg',
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: _buildDetail(
                  "Incorrect",
                  "${attempt.incorrectAnswers}",
                  'assets/image/incorrect.svg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, String path) {
    return Row(
      children: [
        SvgPicture.asset(
          path,
          height: 26,
          width: 26,
        ),
        const SizedBox(width: AppTokens.s8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTokens.caption(context),
            ),
            Text(
              value,
              style: AppTokens.titleSm(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetail(String label, String value, String path) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius8,
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            path,
            height: 28,
            width: 28,
          ),
          const SizedBox(width: AppTokens.s8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTokens.titleSm(context),
              ),
              Text(
                label,
                style: AppTokens.caption(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport(String? userExamId) async {
    showLoadingDialog(context);
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onReportMasterExamApiCall(userExamId ?? "").then((_) {
      Navigator.pop(context);
      Navigator.of(context)
          .pushNamed(Routes.masterTestReportScreen, arguments: {
        'report': store.reportsMasterExam.value,
        'title': widget.testExamPaperListModel.examName,
        'userexamId': userExamId,
        'examId': widget.testExamPaperListModel.examId,
        'isTrend': widget.isTrend,
        'category_id': widget.testExamPaperListModel.categoryId,
        'showPredictive': widget.showPredictive,
      });
    });
  }
}

// ============================================================
//                        Primitives
// ============================================================

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(64),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s12,
            vertical: AppTokens.s8,
          ),
          decoration: BoxDecoration(
            color: AppTokens.accentSoft(context),
            borderRadius: BorderRadius.circular(64),
            border: Border.all(
              color: AppTokens.accent(context).withOpacity(0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppTokens.accent(context)),
              const SizedBox(width: AppTokens.s4),
              Text(
                label,
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.accent(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttemptNowCta extends StatelessWidget {
  const _AttemptNowCta({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: AppTokens.radius12,
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppTokens.radius12,
            boxShadow: [
              BoxShadow(
                color: AppTokens.brand.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: 46,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Text(
                    label,
                    style: AppTokens.titleSm(context).copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
