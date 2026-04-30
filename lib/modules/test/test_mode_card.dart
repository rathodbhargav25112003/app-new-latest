// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names, dead_code, use_build_context_synchronously

import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/models/mcq_exam_data.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/login/store/verify_otp_phone.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/modules/test/mca_analysis_screen.dart';
import 'package:shusruta_lms/modules/test/show_test_screen.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/test/test_instruction_screen.dart';
import 'package:shusruta_lms/modules/widgets/custom_button.dart';

/// Attempt-history card rendered inside `ShowTestScreen` when there are
/// one or more test-mode attempts.
///
/// Preserved public contract:
///   • `TestModeCard({super.key, required data, required
///     testExamPaperListModel, required type, required id})`
///   • TabController length == `data.attemptList.length`; tab labels
///     "Attempt 1", "Attempt 2", …
///   • Title verbatim: "Test Mode" + "Last Test Mode Attempt :
///     {data.lastTestModeTime}".
///   • Per-tab: userExamType header, buildStat("Marks", "X / Y"),
///     buildStat("Accuracy", accuracyPercentage), buildDetail rows for
///     Attempted / Skipped / Correct / Incorrect / Bookmarked.
///   • "Analysis" → CupertinoPageRoute to
///     `McqAnalysisScreen(id: userExam_id, testExamPaperListModel)`.
///   • "Review" → `ReportsCategoryStore.onSolutionReportApiCall(userExam_id, "")`
///     then pushes `Routes.solutionReport` with
///     `{solutionReport, filterVal: "View all", userExamId}`.
///   • "Re-Attempt" → `_showBottomSheet(context, mainUserId)`:
///       desktop → AlertDialog; mobile → modal bottom sheet. Both
///       render "Reattempt Choice" / "Select any one of the options"
///       with 5 options:
///         All Questions / Correct Questions / Incorrect Questions /
///         Bookmarked Questions / Skipped Questions.
///     Selecting + tapping "Next" pushes
///     `TestInstructionScreen(userExamId: mainUserId ?? store.userExamId!,
///     type, examType, id, testExamPaperListModel)`.
///   • Reuses `buildDetail` and `buildStat` from `show_test_screen.dart`.
class TestModeCard extends StatefulWidget {
  const TestModeCard({
    super.key,
    required this.data,
    required this.testExamPaperListModel,
    required this.type,
    required this.id,
  });
  final McqExamData data;
  final TestExamPaperListModel testExamPaperListModel;
  final String type;
  final String id;

  @override
  State<TestModeCard> createState() => _TestModeCardState();
}

class _TestModeCardState extends State<TestModeCard>
    with TickerProviderStateMixin {
  TabController? tabController;

  @override
  void initState() {
    tabController =
        TabController(length: widget.data.attemptList.length, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<TestCategoryStore>(context);
    final attempt = widget.data.attemptList[tabController!.index];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.r16),
        color: AppTokens.surface(context),
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s16,
              AppTokens.s12,
              AppTokens.s16,
              AppTokens.s8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Test Mode",
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  "Last Test Mode Attempt : ${widget.data.lastTestModeTime}",
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.muted(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppTokens.s12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.r12),
              border: Border.all(
                color: AppTokens.border(context),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                TabBar(
                  onTap: (value) {
                    log(widget
                        .data.attemptList[tabController!.index].userExam_id);
                    setState(() {});
                  },
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
                  tabs: widget.data.attemptList
                      .asMap()
                      .entries
                      .map((entry) => Tab(text: "Attempt ${entry.key + 1}"))
                      .toList(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s16,
                    vertical: AppTokens.s12,
                  ),
                  child: Column(
                    children: [
                      Text(
                        attempt.userExamType,
                        style: AppTokens.body(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTokens.accent(context),
                        ),
                      ),
                      const SizedBox(height: AppTokens.s12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          buildStat(
                            "Marks",
                            "${attempt.mymark} / ${attempt.totalMarks}",
                            "assets/image/win.svg",
                          ),
                          const SizedBox(width: AppTokens.s20),
                          buildStat(
                            "Accuracy",
                            attempt.accuracyPercentage,
                            "assets/image/accuracy1.svg",
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.s16),
                      Row(
                        children: [
                          Expanded(
                            child: buildDetail(
                              "Attempted",
                              "${attempt.attemptedQuestion}",
                              "assets/image/attempted1.svg",
                            ),
                          ),
                          const SizedBox(width: AppTokens.s8),
                          Expanded(
                            child: buildDetail(
                              "Skipped",
                              "${attempt.skippedAnswersCount}",
                              "assets/image/skipped1.svg",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.s8),
                      Row(
                        children: [
                          Expanded(
                            child: buildDetail(
                              "Correct",
                              "${attempt.correctAnswersCount}",
                              "assets/image/correct.svg",
                            ),
                          ),
                          const SizedBox(width: AppTokens.s8),
                          Expanded(
                            child: buildDetail(
                              "Incorrect",
                              "${attempt.incorrectAnswersCount}",
                              "assets/image/incorrect.svg",
                            ),
                          ),
                          const SizedBox(width: AppTokens.s8),
                          Expanded(
                            child: buildDetail(
                              "Bookmarked",
                              "${attempt.bookmarkCount}",
                              "assets/image/bookmark2.svg",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppTokens.border(context)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s12,
                    vertical: AppTokens.s12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _PillButton(
                        label: "Analysis",
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => McqAnalysisScreen(
                                id: attempt.userExam_id,
                                testExamPaperListModel:
                                    widget.testExamPaperListModel,
                              ),
                            ),
                          );
                        },
                      ),
                      _PillButton(
                        label: "Review",
                        onTap: () async {
                          showLoadingDialog(context);
                          final reportsStore =
                              Provider.of<ReportsCategoryStore>(
                            context,
                            listen: false,
                          );
                          await reportsStore
                              .onSolutionReportApiCall(
                                  attempt.userExam_id, "")
                              .then((_) {
                            Navigator.pop(context);
                            Navigator.of(context).pushNamed(
                              Routes.solutionReport,
                              arguments: {
                                'solutionReport':
                                    reportsStore.solutionReportCategory,
                                'filterVal': "View all",
                                'userExamId': attempt.userExam_id,
                              },
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s16,
              vertical: AppTokens.s16,
            ),
            child: Observer(builder: (context) {
              return CustomButton(
                radius: AppTokens.r8.toDouble(),
                isLoading: store.isLoadingCountLoading,
                height: 42,
                width: (Platform.isMacOS || Platform.isWindows) ? 500 : null,
                textColor: Colors.white,
                bgColor: AppTokens.accent(context),
                onPressed: () async {
                  store.userExamId = attempt.userExam_id;
                  await store.mcqExamCounts(attempt.userExam_id, "");
                  _showBottomSheet(
                    context,
                    attempt.userExamType != "All Questions" &&
                            attempt.userExamType != "Bookmarked Questions"
                        ? attempt.mainUserExam_id
                        : null,
                  );
                },
                buttonText: "Re-Attempt",
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context, String? mainUserId) {
    if (Platform.isMacOS || Platform.isWindows) {
      _showDialog(context, mainUserId);
    } else {
      _showModalBottomSheet(context, mainUserId);
    }
  }

  void _showModalBottomSheet(BuildContext context, String? mainUserId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTokens.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.r28),
        ),
      ),
      builder: (BuildContext context) {
        final store = Provider.of<TestCategoryStore>(context);
        int selectedIndex = -1;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s20,
                vertical: AppTokens.s20,
              ),
              child: _ReattemptPicker(
                store: store,
                selectedIndex: selectedIndex,
                onSelect: (i) => setState(() => selectedIndex = i),
                onNext: () {
                  if (selectedIndex != -1) {
                    Navigator.pop(context);
                    _pushInstruction(
                        context, selectedIndex, mainUserId, store);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showDialog(BuildContext context, String? mainUserId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final store = Provider.of<TestCategoryStore>(context);
        int selectedIndex = -1;

        return Dialog(
          backgroundColor: AppTokens.surface(context),
          insetPadding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s20,
                    vertical: AppTokens.s20,
                  ),
                  child: _ReattemptPicker(
                    store: store,
                    selectedIndex: selectedIndex,
                    onSelect: (i) => setState(() => selectedIndex = i),
                    onNext: () {
                      if (selectedIndex != -1) {
                        Navigator.pop(context);
                        _pushInstruction(
                            context, selectedIndex, mainUserId, store);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _pushInstruction(
    BuildContext context,
    int selectedIndex,
    String? mainUserId,
    TestCategoryStore store,
  ) {
    final examType = selectedIndex == 0
        ? "All Questions"
        : selectedIndex == 1
            ? "Correct Questions"
            : selectedIndex == 2
                ? "Incorrect Questions"
                : selectedIndex == 3
                    ? "Bookmarked Questions"
                    : "Skipped Questions";
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => TestInstructionScreen(
          userExamId: mainUserId ?? store.userExamId!,
          type: widget.type,
          examType: examType,
          id: mainUserId ?? widget.id,
          testExamPaperListModel: widget.testExamPaperListModel,
        ),
      ),
    );
  }
}

class _ReattemptPicker extends StatelessWidget {
  final TestCategoryStore store;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onNext;

  const _ReattemptPicker({
    required this.store,
    required this.selectedIndex,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Reattempt Choice',
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w700,
            color: AppTokens.ink(context),
          ),
        ),
        const SizedBox(height: AppTokens.s4),
        Text(
          'Select any one of the options',
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.muted(context),
          ),
        ),
        const SizedBox(height: AppTokens.s16),
        _ReattemptOption(
          title: 'All Questions',
          value: '${store.mcqExamCount.value!['allQuestions']}',
          valueColor: AppTokens.ink(context),
          selected: selectedIndex == 0,
          onTap: () => onSelect(0),
        ),
        _ReattemptOption(
          title: 'Correct Questions',
          value: '${store.mcqExamCount.value!['correctAnswers']}',
          valueColor: Colors.green,
          selected: selectedIndex == 1,
          onTap: () => onSelect(1),
        ),
        _ReattemptOption(
          title: 'Incorrect Questions',
          value: '${store.mcqExamCount.value!['incorrectAnswers']}',
          valueColor: Colors.red,
          selected: selectedIndex == 2,
          onTap: () => onSelect(2),
        ),
        _ReattemptOption(
          title: 'Bookmarked Questions',
          value: '${store.mcqExamCount.value!['bookmarkCount']}',
          valueColor: Colors.blue,
          selected: selectedIndex == 3,
          onTap: () => onSelect(3),
        ),
        _ReattemptOption(
          title: 'Skipped Questions',
          value: '${store.mcqExamCount.value!['skippedQuestions']}',
          valueColor: Colors.orange,
          selected: selectedIndex == 4,
          onTap: () => onSelect(4),
        ),
        const SizedBox(height: AppTokens.s16),
        InkWell(
          onTap: onNext,
          borderRadius: BorderRadius.circular(AppTokens.r8),
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: selectedIndex != -1
                  ? AppTokens.accent(context)
                  : Colors.transparent,
              border: Border.all(color: AppTokens.border(context)),
              borderRadius: BorderRadius.circular(AppTokens.r8),
            ),
            alignment: Alignment.center,
            child: Text(
              'Next',
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w600,
                color: selectedIndex != -1
                    ? Colors.white
                    : AppTokens.muted(context),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.s8),
      ],
    );
  }
}

class _ReattemptOption extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;
  final bool selected;
  final VoidCallback onTap;

  const _ReattemptOption({
    required this.title,
    required this.value,
    required this.valueColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppTokens.s4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16,
          vertical: AppTokens.s16,
        ),
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          border: Border.all(
            color: selected
                ? AppTokens.accent(context)
                : AppTokens.border(context),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTokens.r12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink(context),
              ),
            ),
            Text(
              value,
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.r20),
          border: Border.all(color: AppTokens.border(context)),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppTokens.s4,
          horizontal: AppTokens.s12,
        ),
        child: Text(
          label,
          style: AppTokens.caption(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppTokens.accent(context),
          ),
        ),
      ),
    );
  }
}
