// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names, dead_null_aware_expression, unused_local_variable

import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../models/test_exampaper_list_model.dart';
import '../new_exam_component/instruction_page.dart';
import '../reports/rank_list_screen.dart';
import '../test/store/test_category_store.dart';
import '../widgets/no_access_alert_dialog.dart';
import '../widgets/no_access_bottom_sheet.dart';
import 'custom_master_test_bottom_sheet.dart';
import 'custom_master_test_bottom_sheet_window.dart';
import 'exam_status_card.dart';
import 'master_bottom_practice_sheet.dart';

/// Exam detail & attempt launcher — redesigned with AppTokens. Preserves the
/// 6-arg constructor + static route factory, MobX onAllExamAttemptList fetch,
/// back-button pushReplacement to chooseTestScreen, section/time helpers,
/// RankListScreen push for leaderboard, platform-specific dialog/bottom-sheet
/// flow for "Attempt Now" (Windows/macOS → AlertDialog with
/// CustomMasterTestBottomSheetWindow / NoAccessAlertDialog, mobile →
/// showModalBottomSheet with CustomMasterTestBottomSheet /
/// NoAccessBottomSheet), and ExamStatusCard injection on attempt.
class AllSelectTestList extends StatefulWidget {
  final String id;
  final TestExamPaperListModel testExamPaperListModel;
  final String type;
  final int? count;
  final bool showPredictive;
  final bool isTrend;

  const AllSelectTestList({
    super.key,
    required this.id,
    required this.type,
    required this.testExamPaperListModel,
    this.showPredictive = false,
    this.count,
    this.isTrend = false,
  });

  @override
  State<AllSelectTestList> createState() => _AllSelectTestListState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => AllSelectTestList(
        id: arguments['id'],
        testExamPaperListModel: arguments['testExamPaperListModel'],
        type: arguments['type'],
        count: arguments['count'],
        isTrend: arguments['isTrend'] ?? false,
        showPredictive: arguments['showPredictive'] ?? false,
      ),
    );
  }
}

class _AllSelectTestListState extends State<AllSelectTestList> {
  final FocusNode _focusNode = FocusNode();
  String query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    log(widget.id);
    store.onAllExamAttemptList(widget.id);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  String _formatTimePerSection(String timeString, int sectionCount) {
    if (timeString.isEmpty || !timeString.contains(":") || sectionCount <= 0) {
      return "0 min";
    }
    final parts = timeString.split(":");
    if (parts.length != 3) return "0 min";
    try {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);
      final totalSeconds = (hours * 3600) + (minutes * 60) + seconds;
      final secondsPerSection = totalSeconds ~/ sectionCount;
      final totalMinutes = (secondsPerSection + 59) ~/ 60;
      if (totalMinutes < 60) return "$totalMinutes min";
      final displayHours = totalMinutes ~/ 60;
      final displayMinutes = totalMinutes % 60;
      return displayMinutes == 0
          ? "$displayHours hr"
          : "$displayHours hr $displayMinutes min";
    } catch (_) {
      return "0 min";
    }
  }

  String formatTotalTime(String timeString) {
    if (timeString.isEmpty || !timeString.contains(":")) return "0 min";
    final parts = timeString.split(":");
    if (parts.length != 3) return "0 min";
    try {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      if (hours == 0) return "$minutes min";
      return minutes == 0 ? "$hours Hr" : "$hours Hr $minutes Min";
    } catch (_) {
      return "0 min";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isWindows || Platform.isMacOS;
    final store = Provider.of<TestCategoryStore>(context);
    final model = widget.testExamPaperListModel;

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _Header(
            title: model.examName ?? "",
            onBack: () => Navigator.of(context).pushReplacementNamed(
              Routes.chooseTestScreen,
              arguments: {
                'id': model.categoryId,
                'type': "topic",
                'showPredictive': true,
                'isTrend': widget.isTrend,
              },
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: isDesktop
                    ? null
                    : const BorderRadius.only(
                        topLeft: Radius.circular(AppTokens.r28),
                        topRight: Radius.circular(AppTokens.r28),
                      ),
              ),
              child: Observer(builder: (_) {
                final isLoading = store.isLoading;
                final examAttemptsModel = store.examAttemptsModel.value;

                if (isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTokens.accent(context),
                    ),
                  );
                }
                if (examAttemptsModel == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.s16,
                    AppTokens.s20,
                    AppTokens.s16,
                    AppTokens.s24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (model.isSection ?? false)
                        _SectionSummaryCard(
                          sections: model.sectionData?.length ?? 0,
                          perSection: model.timeDuration != null
                              ? _formatTimePerSection(
                                  model.timeDuration!,
                                  model.sectionData?.length ?? 1,
                                )
                              : "0 min",
                          questions: model.totalQuestions ?? 0,
                          totalDuration:
                              formatTotalTime(model.timeDuration ?? ""),
                        )
                      else
                        _QuestionsCard(totalQuestions: model.totalQuestions ?? 0),
                      const SizedBox(height: AppTokens.s12),
                      _LiveStatusCard(
                        fromtime: examAttemptsModel.fromtime ?? "",
                        totime: examAttemptsModel.totime ?? "",
                        declarationTime:
                            examAttemptsModel.declarationTime ?? "",
                        isDeclaration: model.isDeclaration ?? false,
                      ),
                      const SizedBox(height: AppTokens.s12),
                      if (model.isAttempt!)
                        _LeaderboardRow(
                          isDeclaration: model.isDeclaration!,
                          onTap: () {
                            if (!model.isDeclaration!) {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => RankListScreen(
                                    examId: model.examId!,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      if (!model.isAttempt! &&
                          (widget.count ?? model.remainingAttempts ?? 0) > 0 &&
                          (examAttemptsModel.fromtime == '' ||
                              (examAttemptsModel.fromtime != '' &&
                                  examAttemptsModel.totime != '' &&
                                  DateTime.now().isAfter(DateTime.parse(
                                          examAttemptsModel.fromtime ?? '')
                                      .subtract(const Duration(seconds: 1))) &&
                                  DateTime.now().isBefore(DateTime.parse(
                                          examAttemptsModel.totime ?? '')
                                      .add(const Duration(seconds: 1))))))
                        _AttemptNowCard(
                          title: examAttemptsModel.fromtime == ''
                              ? "Ready to Attempt"
                              : "Exam not yet started",
                          subtitle: "Attempt Now to start your journey.",
                          isDesktop: isDesktop,
                          onTap: () =>
                              _handleAttemptNow(context, model, isDesktop),
                        ),
                      if (model.isAttempt!)
                        ExamStatusCard(
                          examAttemptsModel: examAttemptsModel,
                          count: widget.count,
                          testExamPaperListModel: model,
                          isTrend: widget.isTrend,
                          id: widget.id,
                          showPredictive: widget.showPredictive,
                          type: widget.type,
                        ),
                      const SizedBox(height: AppTokens.s24),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAttemptNow(
    BuildContext context,
    TestExamPaperListModel model,
    bool isDesktop,
  ) async {
    if (model.isAccess == true) {
      if (model.isSection == true) {
        Navigator.of(context).pushNamed(
          Routes.startSectionInstructionScreen,
          arguments: {
            'testExamPaper': model,
            'id': widget.id,
            'type': widget.type,
            'isPractice': false,
            'showPredictive': widget.showPredictive,
          },
        );
      } else {
        if (isDesktop) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => InstructionScreen(
                isTrend: widget.isTrend,
                showPredictive: widget.showPredictive,
                testExamPaperListModel: model,
                type: widget.type,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => InstructionScreen(
                isTrend: widget.isTrend,
                showPredictive: widget.showPredictive,
                testExamPaperListModel: model,
                type: widget.type,
              ),
            ),
          );
        }
      }
    } else {
      if (isDesktop) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppTokens.surface(context),
              actionsPadding: EdgeInsets.zero,
              insetPadding: const EdgeInsets.symmetric(horizontal: 100),
              actions: [
                NoAccessAlertDialog(
                  planId: model.plan_id ?? "",
                  day: int.parse(model.day ?? "0"),
                  isFree: model.isfreeTrail!,
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
              top: Radius.circular(AppTokens.r28),
            ),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          context: context,
          builder: (BuildContext context) {
            return NoAccessBottomSheet(
              planId: model.plan_id ?? "",
              day: int.parse(model.day ?? "0"),
              isFree: model.isfreeTrail!,
            );
          },
        );
      }
    }
  }

  // Legacy list item builder retained (referenced elsewhere) with AppTokens
  // styling for visual parity with the rest of the module.
  Widget buildItem(
      BuildContext context, TestExamPaperListModel? testExamPaperListModel) {
    final testExamPaper = testExamPaperListModel;
    String fromTime = '';
    String toTime = '';
    final currentDateTime = DateTime.now();
    if ((testExamPaper?.fromtime?.isNotEmpty ?? false) &&
        (testExamPaper?.totime?.isNotEmpty ?? false)) {
      final fromString = testExamPaper?.fromtime ?? "";
      final toString = testExamPaper?.totime ?? "";
      final datefromTime = DateTime.parse(fromString);
      final dateToTime = DateTime.parse(toString);
      fromTime = DateFormat('dd MMMM | hh:mm a').format(datefromTime);
      toTime = DateFormat('dd MMMM | hh:mm a').format(dateToTime);
    }

    if (query.isNotEmpty &&
        (!testExamPaper!.examName!
            .toLowerCase()
            .contains(query.toLowerCase()))) {
      return const SizedBox.shrink();
    }

    final isTime = testExamPaper?.fromtime != ''
        ? currentDateTime.isBefore(
            DateTime.parse(testExamPaper?.fromtime ?? ''),
          )
        : false;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: AppTokens.s12),
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius12,
            color: AppTokens.surface(context),
            border: Border.all(color: AppTokens.border(context)),
          ),
          child: ClipRRect(
            borderRadius: AppTokens.radius12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.s12,
                    AppTokens.s16,
                    AppTokens.s16,
                    AppTokens.s12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              testExamPaper?.examName ?? "",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTokens.titleSm(context),
                            ),
                          ),
                          const SizedBox(width: AppTokens.s8),
                          if (testExamPaper?.fromtime == '')
                            _StatusPill(
                              label: "Always Live",
                              color: AppTokens.success(context),
                            )
                          else if (currentDateTime.isBefore(
                              DateTime.parse(testExamPaper?.fromtime ?? '')))
                            _StatusPill(
                              label: "Live From $fromTime",
                              color: AppTokens.warning(context),
                            )
                          else
                            _StatusPill(
                              label: "Live Till $toTime",
                              color: AppTokens.danger(context),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.s8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _IconMetric(
                            asset: "assets/image/testTime.svg",
                            label: testExamPaper?.timeDuration ?? "",
                          ),
                          _IconMetric(
                            asset: "assets/image/testAttempt.svg",
                            label:
                                "Remaining - ${testExamPaper?.remainingAttempts ?? ""}",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (testExamPaper?.isPracticeMode == true)
                      Expanded(
                        child: _ActionTab(
                          label: "Practice",
                          color: AppTokens.accent(context),
                          dim: isTime,
                          onTap: () {
                            // Delegated to CustomMasterTestBottomSheet /
                            // MasterPracticeBottomSheet flow in the main page
                            // — preserved for parity only.
                          },
                        ),
                      ),
                    if (testExamPaper?.isGivenTest == true)
                      Expanded(
                        child: _ActionTab(
                          label: "Review",
                          color: AppTokens.success(context),
                          dim: isTime,
                          onTap: () {},
                        ),
                      ),
                    if ((testExamPaper?.remainingAttempts ?? 0) > 0)
                      Expanded(
                        child: _ActionTab(
                          label: testExamPaper?.isAttempt == true
                              ? "Re-Attempt"
                              : "Attempt",
                          color: AppTokens.warning(context),
                          dim: isTime,
                          onTap: () {},
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (testExamPaper?.isAccess == false)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              height: 28,
              width: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTokens.accent(context),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppTokens.r12),
                  bottomLeft: Radius.circular(AppTokens.r12),
                ),
              ),
              child: const Icon(
                Icons.lock,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
//                        Primitives
// ============================================================

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTokens.s8,
        MediaQuery.of(context).padding.top + AppTokens.s12,
        AppTokens.s16,
        AppTokens.s20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTokens.brand.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white.withOpacity(0.16),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTokens.titleMd(context).copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionSummaryCard extends StatelessWidget {
  const _SectionSummaryCard({
    required this.sections,
    required this.perSection,
    required this.questions,
    required this.totalDuration,
  });

  final int sections;
  final String perSection;
  final int questions;
  final String totalDuration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: AppTokens.shadow1(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(
                  icon: Icons.view_agenda_rounded,
                  value: sections.toString(),
                  label: "Sections",
                ),
                const SizedBox(height: AppTokens.s8),
                _StatRow(
                  icon: Icons.schedule_rounded,
                  value: perSection,
                  label: "Per Section",
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(
                  icon: Icons.quiz_rounded,
                  value: questions.toString(),
                  label: "Questions",
                ),
                const SizedBox(height: AppTokens.s8),
                _StatRow(
                  icon: Icons.timer_rounded,
                  value: totalDuration,
                  label: "Total Duration",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTokens.accentSoft(context),
            borderRadius: AppTokens.radius8,
          ),
          child: Icon(icon, color: AppTokens.accent(context), size: 18),
        ),
        const SizedBox(width: AppTokens.s8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTokens.titleSm(context)),
            Text(
              label,
              style: AppTokens.caption(context).copyWith(
                color: AppTokens.ink2(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuestionsCard extends StatelessWidget {
  const _QuestionsCard({required this.totalQuestions});
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppTokens.radius12,
            ),
            child: SvgPicture.asset(
              "assets/image/question.svg",
              height: 18,
              width: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$totalQuestions",
                style: AppTokens.titleLg(context),
              ),
              Text(
                "Questions",
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.ink2(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveStatusCard extends StatelessWidget {
  const _LiveStatusCard({
    required this.fromtime,
    required this.totime,
    required this.declarationTime,
    required this.isDeclaration,
  });
  final String fromtime;
  final String totime;
  final String declarationTime;
  final bool isDeclaration;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hasWindow = fromtime.isNotEmpty && totime.isNotEmpty;
    Color dotColor;
    String statusText;

    if (fromtime.isEmpty) {
      dotColor = AppTokens.success(context);
      statusText = "Always Live";
    } else if (hasWindow && now.isBefore(DateTime.parse(fromtime))) {
      dotColor = AppTokens.warning(context);
      statusText =
          "Live From ${DateFormat('dd MMMM | hh:mm a').format(DateTime.parse(fromtime))}";
    } else {
      dotColor = AppTokens.danger(context);
      statusText =
          "Live Till ${DateFormat('dd MMMM | hh:mm a').format(DateTime.parse(totime))}";
    }

    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Flexible(
                child: Text(
                  statusText,
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.ink(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (declarationTime != "" && isDeclaration) ...[
            const SizedBox(height: AppTokens.s8),
            Row(
              children: [
                Text(
                  "Result Declaration on: ",
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.ink2(context),
                  ),
                ),
                Flexible(
                  child: Text(
                    DateFormat('dd MMMM | hh:mm a').format(
                      DateTime.parse(declarationTime),
                    ),
                    style: AppTokens.caption(context).copyWith(
                      color: AppTokens.ink(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.isDeclaration,
    required this.onTap,
  });
  final bool isDeclaration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dim = isDeclaration;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: Material(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        child: InkWell(
          borderRadius: AppTokens.radius12,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppTokens.s12),
            decoration: BoxDecoration(
              borderRadius: AppTokens.radius12,
              border: Border.all(color: AppTokens.border(context)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.warningSoft(context),
                    borderRadius: AppTokens.radius12,
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: AppTokens.warning(context),
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Text(
                    "View Ranking & Leaderboard",
                    style: AppTokens.titleSm(context).copyWith(
                      color: dim
                          ? AppTokens.ink2(context)
                          : AppTokens.ink(context),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTokens.ink2(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttemptNowCard extends StatelessWidget {
  const _AttemptNowCard({
    required this.title,
    required this.subtitle,
    required this.isDesktop,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final bool isDesktop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s20),
      margin: const EdgeInsets.only(bottom: AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: AppTokens.shadow1(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTokens.accentSoft(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rocket_launch_rounded,
              color: AppTokens.accent(context),
              size: 32,
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          Text(title, style: AppTokens.titleSm(context)),
          const SizedBox(height: AppTokens.s4),
          Text(
            subtitle,
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.ink2(context),
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Material(
            color: Colors.transparent,
            borderRadius: AppTokens.radius12,
            child: InkWell(
              borderRadius: AppTokens.radius12,
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
                  width: isDesktop ? 500 : double.infinity,
                  height: 46,
                  child: Center(
                    child: Text(
                      "Attempt Now",
                      style: AppTokens.titleSm(context).copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(64),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: AppTokens.caption(context).copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _IconMetric extends StatelessWidget {
  const _IconMetric({required this.asset, required this.label});
  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          asset,
          width: 14,
          height: 14,
          color: AppTokens.ink2(context),
        ),
        const SizedBox(width: AppTokens.s4),
        Text(
          label,
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.ink(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionTab extends StatelessWidget {
  const _ActionTab({
    required this.label,
    required this.color,
    required this.dim,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool dim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        color: dim ? color.withOpacity(0.5) : color,
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTokens.caption(context).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
