import 'dart:io';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/app/routes.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/modules/widgets/bottom_practice_sheet.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart' as test;
import 'package:shusruta_lms/modules/new-bookmark-flow/bookmark_test_card.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/store/new_bookmark_store.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/bookmark_instruction_screen.dart';

/// BookmarkExamScreen — the exam-mode hub for a bookmark exam.
/// Shows the total bookmark question count, a Practice Mode card
/// (with inline stats or an empty state), and a Test Mode card
/// (delegating to [BookmarkTestModeCard] when there are attempts,
/// or rendering an empty state CTA).
///
/// Public surface preserved exactly:
///   • class [BookmarkExamScreen]
///   • final fields `type`, `name`, `isAll`, `time`, `question`,
///     `id`, `isCustom`
///   • const constructor with all seven required params
///   • initState call to
///     `store.ongetCustomAnalysisApiCall(widget.type, widget.id,
///      widget.isAll)`
///   • private [startPractice] method (id, mainId) with the
///     platform-gated [PracticeBottomSheet] wrapper (AlertDialog on
///     desktop, ModalBottomSheet on mobile) and all ten arguments
///     forwarded to PracticeBottomSheet exactly as before
///   • Start Practice flow: onCreateCustomeExamApiCall → pushNamed
///     `Routes.practiceTestExams` with arguments exactly preserved
///   • Attempt Now flow: push [BookmarkInstructionScreen] with
///     all required params preserved
///   • Top-level widgets [buildDetail] and [buildStat] with
///     signatures `(String, String, String) → Widget`
class BookmarkExamScreen extends StatefulWidget {
  const BookmarkExamScreen({
    super.key,
    required this.type,
    required this.name,
    required this.isAll,
    required this.time,
    required this.question,
    required this.id,
    required this.isCustom,
  });
  final String type;
  final String question;
  final String name;
  final String time;
  final bool isAll;
  final bool isCustom;
  final String id;
  @override
  State<BookmarkExamScreen> createState() => _BookmarkExamScreenState();
}

class _BookmarkExamScreenState extends State<BookmarkExamScreen> {
  @override
  void initState() {
    final store = Provider.of<BookmarkNewStore>(context, listen: false);
    store.ongetCustomAnalysisApiCall(widget.type, widget.id, widget.isAll);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<BookmarkNewStore>(context);
    final isDesktop = Platform.isWindows || Platform.isMacOS;

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          // Gradient hero
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTokens.s20,
                  isDesktop ? AppTokens.s16 : AppTokens.s12,
                  AppTokens.s20,
                  AppTokens.s20,
                ),
                child: _Header(title: widget.name),
              ),
            ),
          ),

          // Body sheet
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTokens.surface2(context),
                borderRadius: isDesktop
                    ? null
                    : const BorderRadius.only(
                        topLeft: Radius.circular(28.8),
                        topRight: Radius.circular(28.8),
                      ),
              ),
              child: Observer(
                builder: (_) {
                  if (store.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTokens.accent(context),
                      ),
                    );
                  }
                  final examData = store.examsData.value;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.s20,
                      AppTokens.s24,
                      AppTokens.s20,
                      AppTokens.s32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question count card
                        _QuestionCountCard(
                          count: widget.question,
                        ),
                        const SizedBox(height: AppTokens.s16),

                        // Practice Mode card — data-driven
                        if (examData != null) ...[
                          if (examData.isPractice) ...[
                            _PracticeModeCard(
                              lastPracticeTime:
                                  examData.lastPracticeTime.toString(),
                              attempted: examData
                                  .practiceReport.attemptedQuestion
                                  .toString(),
                              skipped: examData
                                  .practiceReport.skippedAnswersCount
                                  .toString(),
                              correct: examData
                                  .practiceReport.correctAnswersCount
                                  .toString(),
                              incorrect: examData
                                  .practiceReport.incorrectAnswersCount
                                  .toString(),
                              bookmarked: examData
                                  .practiceReport.bookmarkCount
                                  .toString(),
                              onResume: () {
                                startPractice(
                                  examData.practiceReport.userExam_id,
                                  widget.id,
                                );
                              },
                            ),
                            const SizedBox(height: AppTokens.s16),
                          ] else ...[
                            _ModeEmptyCard(
                              sectionTitle: "Practice Mode",
                              heading: "Practice not started yet",
                              message: "Begin now to improve!",
                              ctaLabel: "Start Practice",
                              onCta: _handleStartPractice,
                            ),
                            const SizedBox(height: AppTokens.s16),
                          ],
                        ],

                        // Test Mode card — delegate when attempts exist
                        if (examData != null && examData.isAttempt) ...[
                          BookmarkTestModeCard(
                            isAll: widget.isAll,
                            id: widget.id,
                            type: widget.type,
                            name: widget.name,
                            time: widget.time,
                            data: examData,
                          ),
                        ],

                        // Test Mode empty state
                        if (examData != null && !examData.isAttempt) ...[
                          _ModeEmptyCard(
                            sectionTitle: "Test Mode",
                            heading: "Test not started yet",
                            message: "Start now to track your progress!",
                            ctaLabel: "Attempt Now",
                            onCta: _handleAttemptNow,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Action handlers (navigation preserved verbatim)
  // ---------------------------------------------------------------------

  Future<void> _handleStartPractice() async {
    final bookmarkStore =
        Provider.of<BookmarkNewStore>(context, listen: false);
    final List<test.TestData> dataList =
        await bookmarkStore.ongetBookmarkMacqQuestionsListApiCall(
      "All Questions",
      widget.id.isEmpty ? "6719b2d0ddf6a41c091c0f90" : widget.id,
      widget.isAll,
      widget.type == "MockBookmark",
      widget.isCustom,
    );
    final now = DateTime.now();
    final List<String> parts = widget.time.split(":");
    final int hours = int.parse(parts[0]);
    final int minutes = int.parse(parts[1]);
    final int totalMinutes = (hours * 60) + minutes;
    final endTime = now.add(Duration(minutes: totalMinutes));
    final Map<String, dynamic>? data =
        await bookmarkStore.onCreateCustomeExamApiCall(widget.type, {
      "customTest_id":
          widget.id.isEmpty ? "6719b2d0ddf6a41c091c0f90" : widget.id,
      "start_time": now.toIso8601String(),
      'isAll': widget.isAll,
      "end_time": endTime.toIso8601String(),
      "isAllQSolve": widget.isAll,
      'isPractice': true,
    });
    if (!mounted) return;
    final store2 =
        Provider.of<TestCategoryStore>(context, listen: false);
    store2.qutestionList.value = dataList;
    store2.type.value = widget.type;
    Navigator.of(context).pushNamed(
      Routes.practiceTestExams,
      arguments: {
        'testData': test.TestExamPaperListModel(
          examName: widget.name,
          test: dataList,
        ),
        'userexamId': data!['_id'],
        'isPracticeExam': true,
        'id': widget.id,
        'isAll': widget.isAll,
        'isCustom': widget.isCustom,
        "mainId": widget.id,
        'type': widget.type,
      },
    );
  }

  void _handleAttemptNow() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => BookmarkInstructionScreen(
          isCustom: widget.isCustom,
          isAll: widget.isAll,
          option: "All Questions",
          time: widget.time,
          name: widget.name,
          type: widget.type,
          mainId: widget.id,
          id: widget.id,
        ),
      ),
    );
  }

  void startPractice(id, mainId) {
    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            actionsPadding: EdgeInsets.zero,
            actions: [
              PracticeBottomSheet(
                context,
                null,
                id,
                widget.type,
                true,
                widget.time,
                widget.name,
                widget.isAll,
                mainId,
                widget.isCustom,
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
          return PracticeBottomSheet(
            context,
            null,
            id,
            widget.type,
            true,
            widget.time,
            widget.name,
            widget.isAll,
            mainId,
            widget.isCustom,
          );
        },
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GhostIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: AppTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "EXAM MODE",
                style: AppTokens.overline(context).copyWith(
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.82),
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTokens.s4),
              Text(
                title.isEmpty ? "Bookmark Exam" : title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTokens.titleLg(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GhostIconButton extends StatelessWidget {
  const _GhostIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.18),
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Question count card
// ---------------------------------------------------------------------------

class _QuestionCountCard extends StatelessWidget {
  const _QuestionCountCard({required this.count});
  final String count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: AppTokens.cardDecoration(context),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(AppTokens.s12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTokens.r12),
            ),
            child: SvgPicture.asset(
              "assets/image/question.svg",
              // ignore: deprecated_member_use
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppTokens.s16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count,
                style: AppTokens.displayMd(context).copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: AppTokens.s4),
              Text(
                "Questions",
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.ink2(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Practice mode card — with stats grid
// ---------------------------------------------------------------------------

class _PracticeModeCard extends StatelessWidget {
  const _PracticeModeCard({
    required this.lastPracticeTime,
    required this.attempted,
    required this.skipped,
    required this.correct,
    required this.incorrect,
    required this.bookmarked,
    required this.onResume,
  });

  final String lastPracticeTime;
  final String attempted;
  final String skipped;
  final String correct;
  final String incorrect;
  final String bookmarked;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s20),
      decoration: AppTokens.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: "Practice Mode",
            subtitle: "Last Practice Session : $lastPracticeTime",
          ),
          const SizedBox(height: AppTokens.s20),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: "Attempted",
                  value: attempted,
                  iconPath: "assets/image/attempted1.svg",
                  tint: AppTokens.accent(context),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: _StatTile(
                  label: "Unattempted",
                  value: skipped,
                  iconPath: "assets/image/skipped1.svg",
                  tint: AppTokens.warning(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: "Correct",
                  value: correct,
                  iconPath: "assets/image/correct.svg",
                  tint: AppTokens.success(context),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: _StatTile(
                  label: "Incorrect",
                  value: incorrect,
                  iconPath: "assets/image/incorrect.svg",
                  tint: AppTokens.danger(context),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: _StatTile(
                  label: "Bookmarked",
                  value: bookmarked,
                  iconPath: "assets/image/bookmark2.svg",
                  tint: AppTokens.accent(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s20),
          _GradientCta(
            label: "Resume Practice",
            onTap: onResume,
            icon: Icons.play_arrow_rounded,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mode empty card — shared for both Practice & Test empty states
// ---------------------------------------------------------------------------

class _ModeEmptyCard extends StatelessWidget {
  const _ModeEmptyCard({
    required this.sectionTitle,
    required this.heading,
    required this.message,
    required this.ctaLabel,
    required this.onCta,
  });

  final String sectionTitle;
  final String heading;
  final String message;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s20),
      decoration: AppTokens.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: sectionTitle),
          const SizedBox(height: AppTokens.s16),
          Divider(color: AppTokens.border(context), height: 1),
          const SizedBox(height: AppTokens.s20),
          Center(
            child: SvgPicture.asset("assets/image/attemp.svg"),
          ),
          const SizedBox(height: AppTokens.s16),
          Center(
            child: Text(
              heading,
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s4),
          Center(
            child: Text(
              message,
              style: AppTokens.caption(context).copyWith(
                color: AppTokens.ink2(context),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s20),
          _GradientCta(
            label: ctaLabel,
            onTap: onCta,
            icon: Icons.bolt_rounded,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header — title + optional subtitle line
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTokens.titleMd(context).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppTokens.s4),
          Text(
            subtitle!,
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.ink2(context),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stat tile — icon + value + label, tinted
// ---------------------------------------------------------------------------

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.iconPath,
    required this.tint,
  });
  final String label;
  final String value;
  final String iconPath;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(AppTokens.s4),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: tint.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppTokens.r8),
            ),
            child: SvgPicture.asset(iconPath),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTokens.titleSm(context).copyWith(
                    color: tint,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  label,
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.ink2(context),
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient CTA
// ---------------------------------------------------------------------------

class _GradientCta extends StatelessWidget {
  const _GradientCta({
    required this.label,
    required this.onTap,
    this.icon,
  });
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isMacOS || Platform.isWindows;
    return SizedBox(
      width: isDesktop ? 500 : double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.r12),
          child: Ink(
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTokens.r12),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: AppTokens.brand.withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: AppTokens.s8),
                ],
                Text(
                  label,
                  style: AppTokens.body(context).copyWith(
                    color: Colors.white,
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

// ---------------------------------------------------------------------------
// Top-level helpers preserved from the original file. These are public and
// may be referenced from elsewhere (search across the codebase confirms
// siblings define their own versions) — signature and name preserved.
// ---------------------------------------------------------------------------

Widget buildDetail(String label, String value, String path) {
  return Builder(
    builder: (context) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(path, height: 32, width: 32),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTokens.titleSm(context).copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  label,
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.ink2(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildStat(String label, String value, String path) {
  return Builder(
    builder: (context) => Row(
      children: [
        SvgPicture.asset(path, height: 25, width: 25),
        const SizedBox(width: AppTokens.s8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTokens.caption(context).copyWith(
                color: AppTokens.ink2(context),
                height: 1,
              ),
            ),
            const SizedBox(height: AppTokens.s4),
            Text(
              value,
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
