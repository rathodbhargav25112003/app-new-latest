import 'dart:io';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/masterTest/master_test_report_details_screen.dart';

/// BookAnalysisScreen — the bookmark-exam post-attempt analysis report.
/// Shows three tabs of analytics (Edumetrics, Guess Analytics, Answer
/// Evolve) backed by `store.mcqExamReport`, loaded on init via
/// `store.bookmarkAnalysis(id, type)`.
///
/// Public surface preserved exactly:
///   • class [BookAnalysisScreen]
///   • final fields `id`, `type`, `name`
///   • const constructor with all three required params
///   • [TickerProviderStateMixin] on the state
///   • state fields [isFinished], [isRank1], `tabController`, `store`
///   • `init()` still calls `store.bookmarkAnalysis(widget.id, widget.type)`
///   • 3-tab TabController (length: 3)
///   • Top-level private helpers `_getProgress`, `_getColor`, `_buildDetail`
class BookAnalysisScreen extends StatefulWidget {
  const BookAnalysisScreen({
    super.key,
    required this.id,
    required this.type,
    required this.name,
  });
  final String id;
  final String type;
  final String name;

  @override
  State<BookAnalysisScreen> createState() => _BookAnalysisScreenState();
}

class _BookAnalysisScreenState extends State<BookAnalysisScreen>
    with TickerProviderStateMixin {
  // ignore: unused_field
  bool isFinished = false;
  // ignore: unused_field
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
    await store.bookmarkAnalysis(widget.id, widget.type);
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
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
                child: _Header(name: widget.name),
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
                  final report = store.mcqExamReport.value;
                  if (report == null) {
                    return const _EmptyReport();
                  }
                  return Column(
                    children: [
                      // Tab bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTokens.s20,
                          AppTokens.s16,
                          AppTokens.s20,
                          AppTokens.s4,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppTokens.s4),
                          decoration: BoxDecoration(
                            color: AppTokens.surface(context),
                            borderRadius:
                                BorderRadius.circular(AppTokens.r20),
                            border: Border.all(
                              color: AppTokens.border(context),
                            ),
                          ),
                          child: TabBar(
                            controller: tabController,
                            isScrollable: false,
                            labelColor: Colors.white,
                            unselectedLabelColor: AppTokens.ink2(context),
                            labelStyle: AppTokens.caption(context).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            unselectedLabelStyle:
                                AppTokens.caption(context).copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            indicator: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppTokens.r16),
                              gradient: const LinearGradient(
                                colors: [
                                  AppTokens.brand,
                                  AppTokens.brand2,
                                ],
                              ),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: "Edumetrics"),
                              Tab(text: "Guess"),
                              Tab(text: "Evolve"),
                            ],
                          ),
                        ),
                      ),
                      // Tab views
                      Expanded(
                        child: TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          controller: tabController,
                          children: [
                            _EdumetricsTab(report: report),
                            _GuessTab(report: report),
                            _EvolveTab(report: report),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GhostIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: AppTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ANALYSIS REPORT",
                style: AppTokens.overline(context).copyWith(
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.82),
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTokens.s4),
              Text(
                name.isEmpty ? "Exam Analysis" : "$name  Analysis",
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
// Shared empty state
// ---------------------------------------------------------------------------

class _EmptyReport extends StatelessWidget {
  const _EmptyReport();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_rounded,
                color: AppTokens.accent(context),
                size: 34,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              "No analysis data available",
              style: AppTokens.titleMd(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1: Edumetrics
// ---------------------------------------------------------------------------

class _EdumetricsTab extends StatelessWidget {
  const _EdumetricsTab({required this.report});
  final dynamic report;

  @override
  Widget build(BuildContext context) {
    final correct = report.correctAnswers as int;
    final skipped = report.skippedAnswers as int;
    final incorrect = report.incorrectAnswers as int;
    final total = report.totalQuestions as int;
    final accuracy = report.accuracyPercentage;
    final totalTime = report.totalTime;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        AppTokens.s20,
        AppTokens.s20,
        AppTokens.s32,
      ),
      child: _AnalysisCard(
        icon: 'assets/image/badge.svg',
        title: "Edumetrics",
        children: [
          _StackedTriBar(
            correct: correct,
            skipped: skipped,
            incorrect: incorrect,
          ),
          const SizedBox(height: AppTokens.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Total Questions  ",
                style: AppTokens.body(context),
              ),
              Text(
                "$total",
                style: AppTokens.titleMd(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LegendDot(
                label: 'Correct ($correct)',
                color: AppTokens.success(context),
              ),
              _LegendDot(
                label: 'Skipped ($skipped)',
                color: AppTokens.warning(context),
              ),
              _LegendDot(
                label: 'Incorrect ($incorrect)',
                color: AppTokens.danger(context),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s20),
          Row(
            children: [
              Expanded(
                child: _DetailCard(
                  label: "Accuracy",
                  value: "$accuracy%",
                  iconPath: 'assets/image/accu_p.svg',
                  tint: AppTokens.success(context),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: _DetailCard(
                  label: "Time Taken",
                  value: formatTimeString(totalTime),
                  iconPath: 'assets/image/clock.svg',
                  tint: AppTokens.accent(context),
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
// Tab 2: Guess Analytics
// ---------------------------------------------------------------------------

class _GuessTab extends StatelessWidget {
  const _GuessTab({required this.report});
  final dynamic report;

  @override
  Widget build(BuildContext context) {
    final correctGuess = report.correctGuessCount as int;
    final wrongGuess = report.wrongGuessCount as int;
    final guessedTotal = report.guessedAnswersCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        AppTokens.s20,
        AppTokens.s20,
        AppTokens.s32,
      ),
      child: _AnalysisCard(
        icon: 'assets/image/badge.svg',
        title: "Guess Analytics",
        children: [
          _StackedBiBar(
            correct: correctGuess,
            incorrect: wrongGuess,
            correctColor: AppTokens.success(context),
            incorrectColor: AppTokens.danger(context),
          ),
          const SizedBox(height: AppTokens.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Guessed Answers  ",
                style: AppTokens.body(context),
              ),
              Text(
                "$guessedTotal",
                style: AppTokens.titleMd(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s20),
          Row(
            children: [
              Expanded(
                child: _DetailCard(
                  label: "Correct Answer",
                  value: "$correctGuess",
                  iconPath: 'assets/image/up_trend.svg',
                  tint: AppTokens.success(context),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: _DetailCard(
                  label: "Incorrect Answer",
                  value: "$wrongGuess",
                  iconPath: 'assets/image/down_trend.svg',
                  tint: AppTokens.danger(context),
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
// Tab 3: Answer Evolve
// ---------------------------------------------------------------------------

class _EvolveTab extends StatelessWidget {
  const _EvolveTab({required this.report});
  final dynamic report;

  @override
  Widget build(BuildContext context) {
    final incorrectToCorrect = report.incorrect_correct;
    final correctToIncorrect = report.correct_incorrect;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        AppTokens.s20,
        AppTokens.s20,
        AppTokens.s32,
      ),
      child: _AnalysisCard(
        icon: 'assets/image/badge.svg',
        title: "Answer Evolve",
        children: [
          Text(
            "How your answers changed between attempts.",
            style: AppTokens.body(context).copyWith(
              color: AppTokens.ink2(context),
            ),
          ),
          const SizedBox(height: AppTokens.s20),
          Row(
            children: [
              Expanded(
                child: _DetailCard(
                  label: "Incorrect → Correct",
                  value: "$incorrectToCorrect",
                  iconPath: 'assets/image/up_trend.svg',
                  tint: AppTokens.success(context),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: _DetailCard(
                  label: "Correct → Incorrect",
                  value: "$correctToIncorrect",
                  iconPath: 'assets/image/down_trend.svg',
                  tint: AppTokens.danger(context),
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
// Reusable analysis card shell
// ---------------------------------------------------------------------------

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.icon,
    required this.title,
    required this.children,
  });
  final String icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s20),
      decoration: AppTokens.cardDecoration(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(AppTokens.s8),
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                ),
                child: SvgPicture.asset(icon),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Text(
                  title,
                  style: AppTokens.titleMd(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s20),
          ...children,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stacked tri-color progress bar (correct/skipped/incorrect)
// ---------------------------------------------------------------------------

class _StackedTriBar extends StatelessWidget {
  const _StackedTriBar({
    required this.correct,
    required this.skipped,
    required this.incorrect,
  });
  final int correct;
  final int skipped;
  final int incorrect;

  @override
  Widget build(BuildContext context) {
    final safeCorrect = correct < 0 ? 0 : correct;
    final safeSkipped = skipped < 0 ? 0 : skipped;
    final safeIncorrect = incorrect < 0 ? 0 : incorrect;
    final hasAny = safeCorrect + safeSkipped + safeIncorrect > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.r8),
      child: Container(
        height: 10,
        color: AppTokens.surface3(context),
        child: hasAny
            ? Row(
                children: [
                  if (safeCorrect > 0)
                    Flexible(
                      flex: safeCorrect,
                      child: Container(color: AppTokens.success(context)),
                    ),
                  if (safeSkipped > 0)
                    Flexible(
                      flex: safeSkipped,
                      child: Container(color: AppTokens.warning(context)),
                    ),
                  if (safeIncorrect > 0)
                    Flexible(
                      flex: safeIncorrect,
                      child: Container(color: AppTokens.danger(context)),
                    ),
                ],
              )
            : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stacked bi-color progress bar (correct/incorrect)
// ---------------------------------------------------------------------------

class _StackedBiBar extends StatelessWidget {
  const _StackedBiBar({
    required this.correct,
    required this.incorrect,
    required this.correctColor,
    required this.incorrectColor,
  });
  final int correct;
  final int incorrect;
  final Color correctColor;
  final Color incorrectColor;

  @override
  Widget build(BuildContext context) {
    final safeCorrect = correct < 0 ? 0 : correct;
    final safeIncorrect = incorrect < 0 ? 0 : incorrect;
    final hasAny = safeCorrect + safeIncorrect > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.r8),
      child: Container(
        height: 10,
        color: AppTokens.surface3(context),
        child: hasAny
            ? Row(
                children: [
                  if (safeCorrect > 0)
                    Flexible(
                      flex: safeCorrect,
                      child: Container(color: correctColor),
                    ),
                  if (safeIncorrect > 0)
                    Flexible(
                      flex: safeIncorrect,
                      child: Container(color: incorrectColor),
                    ),
                ],
              )
            : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legend dot with label
// ---------------------------------------------------------------------------

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});
  final String label;
  final Color color;

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
        const SizedBox(width: AppTokens.s4),
        Flexible(
          child: Text(
            label,
            style: AppTokens.caption(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Detail card — icon + label + large value, tinted
// ---------------------------------------------------------------------------

class _DetailCard extends StatelessWidget {
  const _DetailCard({
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
        horizontal: AppTokens.s12,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.ink2(context),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  value,
                  style: AppTokens.titleMd(context).copyWith(
                    color: tint,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(AppTokens.s4),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: tint.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppTokens.r8),
            ),
            child: SvgPicture.asset(iconPath),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top-level private helpers preserved from the original file. These are not
// referenced from within the new widget tree but are kept because they may
// be referenced indirectly (e.g. by tooling or future widgets) — removing
// them would constitute a surface change.
// ---------------------------------------------------------------------------

// ignore: unused_element
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

// ignore: unused_element
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

// ignore: unused_element
Widget _buildDetail(String label, String value, String path) {
  return Builder(
    builder: (context) => _DetailCard(
      label: label,
      value: value,
      iconPath: path,
      tint: AppTokens.accent(context),
    ),
  );
}
