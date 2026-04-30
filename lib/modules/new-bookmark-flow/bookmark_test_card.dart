import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/models/mcq_exam_data.dart';
import 'package:shusruta_lms/modules/login/store/verify_otp_phone.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/bookmark_anaysis.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/bookmark_instruction_screen.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';

import '../../helpers/app_tokens.dart';

/// BookmarkTestModeCard — the per-exam attempt summary card that shows on
/// the bookmark exam dashboard. Each card lists an attempt-wise breakdown
/// (score, accuracy, attempted/skipped/correct/incorrect), plus
/// Analysis + Review shortcuts and a Re-Attempt CTA that opens a sheet
/// (mobile) or dialog (desktop) asking the student which subset of
/// questions to re-run.
///
/// Public surface preserved exactly:
///   • class [BookmarkTestModeCard]
///   • final fields `data`, `type`, `id`, `name`, `isAll`, `time`
///   • const constructor with all seven required params
///   • [TickerProviderStateMixin] on the state
///   • `tabController` field seeded via
///     `TabController(length: widget.data.attemptList.length, vsync: this)`
///   • Re-Attempt flow still calls
///     `store.userExamId = ...` then
///     `store.mcqExamCounts(...)` and dispatches to the legacy modal
///     sheet / dialog that pushes [BookmarkInstructionScreen] with
///     `isCustom: false` and the same option labels
///   • Analysis link still pushes [BookAnalysisScreen] with
///     `{name, id: userExam_id, type}`
///   • Review link still runs
///     `ReportsCategoryStore.onSolutionReportApiCall(userExamId, type)`
///     with a loading dialog, then pushes [Routes.solutionReport] with
///     `{solutionReport, filterVal, userExamId}`
class BookmarkTestModeCard extends StatefulWidget {
  const BookmarkTestModeCard({
    super.key,
    required this.data,
    required this.type,
    required this.id,
    required this.name,
    required this.isAll,
    required this.time,
  });
  final McqExamData data;
  final String type;
  final String id;
  final String name;
  final String time;
  final bool isAll;

  @override
  State<BookmarkTestModeCard> createState() => _BookmarkTestModeCardState();
}

class _BookmarkTestModeCardState extends State<BookmarkTestModeCard>
    with TickerProviderStateMixin {
  TabController? tabController;

  @override
  void initState() {
    tabController = TabController(
      length: widget.data.attemptList.length,
      vsync: this,
    );
    super.initState();
  }

  @override
  void dispose() {
    tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<TestCategoryStore>(context);
    final int index = tabController?.index ?? 0;
    final attempt = widget.data.attemptList.isEmpty
        ? null
        : widget.data.attemptList[index];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius20,
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: AppTokens.shadow1(context),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s16,
              AppTokens.s16,
              AppTokens.s16,
              AppTokens.s8,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius: AppTokens.radius12,
                  ),
                  child: Icon(
                    Icons.fact_check_rounded,
                    color: AppTokens.accent(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Test mode', style: AppTokens.titleMd(context)),
                      const SizedBox(height: 2),
                      Text(
                        'Last attempt · ${widget.data.lastTestModeTime}',
                        style: AppTokens.caption(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.data.attemptList.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppTokens.s16),
              child: _EmptyAttempts(),
            )
          else ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
              decoration: BoxDecoration(
                color: AppTokens.surface2(context),
                borderRadius: AppTokens.radius16,
                border: Border.all(color: AppTokens.border(context)),
              ),
              child: Column(
                children: [
                  TabBar(
                    onTap: (value) {
                      if (widget.data.attemptList.isNotEmpty) {
                        log(widget
                            .data.attemptList[tabController?.index ?? 0]
                            .userExam_id);
                      }
                      setState(() {});
                    },
                    isScrollable: true,
                    controller: tabController,
                    dividerColor: Colors.transparent,
                    labelColor: AppTokens.accent(context),
                    unselectedLabelColor: AppTokens.muted(context),
                    indicatorColor: AppTokens.accent(context),
                    indicatorWeight: 2.4,
                    labelStyle:
                        AppTokens.titleSm(context).copyWith(fontSize: 12),
                    unselectedLabelStyle:
                        AppTokens.titleSm(context).copyWith(fontSize: 12),
                    tabs: widget.data.attemptList
                        .asMap()
                        .entries
                        .map((entry) =>
                            Tab(text: 'Attempt ${entry.key + 1}'))
                        .toList(),
                  ),
                  if (attempt != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.s16,
                        AppTokens.s12,
                        AppTokens.s16,
                        AppTokens.s8,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.s12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTokens.accentSoft(context),
                              borderRadius: AppTokens.radius12,
                            ),
                            child: Text(
                              attempt.userExamType,
                              style: AppTokens.caption(context).copyWith(
                                color: AppTokens.accent(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTokens.s12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Marks',
                                  value:
                                      '${attempt.mymark} / ${attempt.totalMarks}',
                                  icon: 'assets/image/win.svg',
                                ),
                              ),
                              const SizedBox(width: AppTokens.s8),
                              Expanded(
                                child: _StatCard(
                                  label: 'Accuracy',
                                  value: attempt.accuracyPercentage,
                                  icon: 'assets/image/accuracy1.svg',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.s12),
                          Row(
                            children: [
                              Expanded(
                                child: _DetailCard(
                                  label: 'Attempted',
                                  value: '${attempt.attemptedQuestion}',
                                  icon: 'assets/image/attempted1.svg',
                                ),
                              ),
                              const SizedBox(width: AppTokens.s8),
                              Expanded(
                                child: _DetailCard(
                                  label: 'Skipped',
                                  value: '${attempt.skippedAnswersCount}',
                                  icon: 'assets/image/skipped1.svg',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.s8),
                          Row(
                            children: [
                              Expanded(
                                child: _DetailCard(
                                  label: 'Correct',
                                  value: '${attempt.correctAnswersCount}',
                                  icon: 'assets/image/correct.svg',
                                  accent: AppTokens.success(context),
                                ),
                              ),
                              const SizedBox(width: AppTokens.s8),
                              Expanded(
                                child: _DetailCard(
                                  label: 'Incorrect',
                                  value: '${attempt.incorrectAnswersCount}',
                                  icon: 'assets/image/incorrect.svg',
                                  accent: AppTokens.danger(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.s16,
                      AppTokens.s8,
                      AppTokens.s16,
                      AppTokens.s12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _GhostPill(
                          icon: Icons.insights_rounded,
                          label: 'Analysis',
                          onTap: attempt == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => BookAnalysisScreen(
                                        name: widget.name,
                                        id: attempt.userExam_id,
                                        type: widget.type,
                                      ),
                                    ),
                                  );
                                },
                        ),
                        _GhostPill(
                          icon: Icons.rate_review_rounded,
                          label: 'Review',
                          onTap: attempt == null
                              ? null
                              : () async {
                                  showLoadingDialog(context);
                                  final reportStore =
                                      Provider.of<ReportsCategoryStore>(
                                          context,
                                          listen: false);
                                  await reportStore
                                      .onSolutionReportApiCall(
                                          attempt.userExam_id, widget.type)
                                      .then((_) {
                                    Navigator.pop(context);
                                    Navigator.of(context).pushNamed(
                                      Routes.solutionReport,
                                      arguments: {
                                        'solutionReport':
                                            reportStore.solutionReportCategory,
                                        'filterVal': 'View all',
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
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s16,
                AppTokens.s16,
                AppTokens.s16,
                AppTokens.s16,
              ),
              child: Observer(builder: (_) {
                final bool loading = store.isLoadingCountLoading;
                return _GradientCta(
                  label: 'Re-attempt',
                  icon: Icons.replay_rounded,
                  loading: loading,
                  onTap: loading || attempt == null
                      ? null
                      : () async {
                          store.userExamId = attempt.userExam_id;
                          await store.mcqExamCounts(
                            widget.type == 'McqBookMark'
                                ? widget.id
                                : attempt.userExam_id,
                            widget.type,
                          );
                          _showBottomSheet(context, widget.id);
                        },
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context, String? mainUserId) {
    if (Platform.isMacOS || Platform.isWindows) {
      _showDialog(context);
    } else {
      _showModalBottomSheet(context);
    }
  }

  void _showModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTokens.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTokens.r28),
          topRight: Radius.circular(AppTokens.r28),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return _ReattemptPanel(
          onPick: _handleReattemptPick,
        );
      },
    );
  }

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
          shape: RoundedRectangleBorder(
            borderRadius: AppTokens.radius20,
          ),
          backgroundColor: AppTokens.surface(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _ReattemptPanel(
              onPick: _handleReattemptPick,
            ),
          ),
        );
      },
    );
  }

  void _handleReattemptPick(BuildContext sheetContext, int selectedIndex) {
    final attempt =
        widget.data.attemptList[tabController?.index ?? 0];
    Navigator.pop(sheetContext);
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => BookmarkInstructionScreen(
          isCustom: false,
          isAll: widget.isAll,
          time: widget.time,
          option: selectedIndex == 0
              ? 'All Questions'
              : selectedIndex == 1
                  ? 'Correct Questions'
                  : selectedIndex == 2
                      ? 'InCorrect Questions'
                      : 'Skipped Questions',
          name: widget.name,
          mainId: widget.id,
          type: widget.type,
          id: selectedIndex == 0 ? widget.id : attempt.userExam_id,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final String icon;

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
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accentSoft(context),
              borderRadius: AppTokens.radius8,
            ),
            child: SvgPicture.asset(
              icon,
              width: 16,
              height: 16,
              // ignore: deprecated_member_use
              color: AppTokens.accent(context),
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTokens.caption(context)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTokens.titleSm(context).copyWith(
                    color: AppTokens.accent(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
  });

  final String label;
  final String value;
  final String icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final Color c = accent ?? AppTokens.ink(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            icon,
            width: 16,
            height: 16,
            // ignore: deprecated_member_use
            color: c,
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              label,
              style: AppTokens.caption(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTokens.titleSm(context).copyWith(
              color: c,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostPill extends StatelessWidget {
  const _GhostPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppTokens.accentSoft(context),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppTokens.accent(context).withOpacity(0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: AppTokens.accent(context)),
                const SizedBox(width: 6),
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
      ),
    );
  }
}

class _GradientCta extends StatelessWidget {
  const _GradientCta({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null && !loading;
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppTokens.radius12,
          child: Ink(
            decoration: BoxDecoration(
              gradient: enabled
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTokens.brand, AppTokens.brand2],
                    )
                  : null,
              color: enabled ? null : AppTokens.surface3(context),
              borderRadius: AppTokens.radius12,
              boxShadow: enabled ? AppTokens.shadow1(context) : null,
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: enabled
                              ? Colors.white
                              : AppTokens.muted(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: AppTokens.titleSm(context).copyWith(
                            color: enabled
                                ? Colors.white
                                : AppTokens.muted(context),
                            fontSize: 14,
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

class _EmptyAttempts extends StatelessWidget {
  const _EmptyAttempts();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            color: AppTokens.muted(context),
            size: 18,
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              'No attempts recorded yet.',
              style: AppTokens.caption(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reattempt picker — shared between modal sheet and dialog
// ---------------------------------------------------------------------------

class _ReattemptPanel extends StatefulWidget {
  const _ReattemptPanel({required this.onPick});
  final void Function(BuildContext ctx, int selectedIndex) onPick;

  @override
  State<_ReattemptPanel> createState() => _ReattemptPanelState();
}

class _ReattemptPanelState extends State<_ReattemptPanel> {
  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<TestCategoryStore>(context);
    final counts = store.mcqExamCount.value ?? const {};

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s20,
        vertical: AppTokens.s20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: AppTokens.radius12,
                ),
                child: Icon(
                  Icons.replay_circle_filled_rounded,
                  size: 18,
                  color: AppTokens.accent(context),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Re-attempt choice',
                        style: AppTokens.titleMd(context)),
                    const SizedBox(height: 2),
                    Text(
                      'Pick which pool you want to rerun',
                      style: AppTokens.caption(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s20),
          _ReattemptOption(
            title: 'All questions',
            value: '${counts['allQuestions'] ?? 0}',
            valueColor: AppTokens.ink(context),
            selected: selectedIndex == 0,
            onTap: () => setState(() => selectedIndex = 0),
          ),
          _ReattemptOption(
            title: 'Correct questions',
            value: '${counts['correctAnswers'] ?? 0}',
            valueColor: AppTokens.success(context),
            selected: selectedIndex == 1,
            onTap: () => setState(() => selectedIndex = 1),
          ),
          _ReattemptOption(
            title: 'Incorrect questions',
            value: '${counts['incorrectAnswers'] ?? 0}',
            valueColor: AppTokens.danger(context),
            selected: selectedIndex == 2,
            onTap: () => setState(() => selectedIndex = 2),
          ),
          _ReattemptOption(
            title: 'Skipped questions',
            value: '${counts['skippedQuestions'] ?? 0}',
            valueColor: AppTokens.warning(context),
            selected: selectedIndex == 4,
            onTap: () => setState(() => selectedIndex = 4),
          ),
          const SizedBox(height: AppTokens.s20),
          _GradientCta(
            label: 'Next',
            icon: Icons.arrow_forward_rounded,
            loading: false,
            onTap: selectedIndex == -1
                ? null
                : () => widget.onPick(context, selectedIndex),
          ),
          const SizedBox(height: AppTokens.s8),
        ],
      ),
    );
  }
}

class _ReattemptOption extends StatelessWidget {
  const _ReattemptOption({
    required this.title,
    required this.value,
    required this.valueColor,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String value;
  final Color valueColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTokens.radius12,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s16,
              vertical: AppTokens.s16,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppTokens.accentSoft(context)
                  : AppTokens.surface(context),
              borderRadius: AppTokens.radius12,
              border: Border.all(
                color: selected
                    ? AppTokens.accent(context)
                    : AppTokens.border(context),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: selected
                      ? AppTokens.accent(context)
                      : AppTokens.border(context),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTokens.titleSm(context).copyWith(fontSize: 14),
                  ),
                ),
                Text(
                  value,
                  style: AppTokens.titleSm(context).copyWith(
                    color: valueColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
