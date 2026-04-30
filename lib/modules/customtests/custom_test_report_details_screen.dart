// ignore_for_file: use_super_parameters, deprecated_member_use, unused_import, unused_field, unused_element, unused_local_variable, duplicate_ignore, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:intl/intl.dart';
import 'package:nuts_activity_indicator/nuts_activity_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/forked_packages/circular_chart_flutter/lib/circular_chart_flutter.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../models/merit_list_model.dart';
import '../reports/store/report_by_category_store.dart';
import 'model/custom_test_report_by_category_model.dart';

/// Custom-test detailed analytics screen — redesigned with AppTokens.
/// Preserves the constructor signature, static route contract, state
/// fields (_chartKey, _guessedchartKey), initState → getMeritList, and
/// all `widget.reports?.*` property accesses.
class CustomTestReportDetailsScreen extends StatefulWidget {
  final String title;
  final CustomTestReportByCategoryModel? reports;
  final String userexamId;
  final String examId;

  const CustomTestReportDetailsScreen({
    Key? key,
    required this.title,
    this.reports,
    required this.userexamId,
    required this.examId,
  }) : super(key: key);

  @override
  State<CustomTestReportDetailsScreen> createState() =>
      _CustomTestReportDetailsScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => CustomTestReportDetailsScreen(
        title: arguments['title'],
        reports: arguments['report'],
        userexamId: arguments['userexamId'],
        examId: arguments['examId'],
      ),
    );
  }
}

class _CustomTestReportDetailsScreenState
    extends State<CustomTestReportDetailsScreen> {
  final GlobalKey<AnimatedCircularChartState> _chartKey =
      GlobalKey<AnimatedCircularChartState>();
  final GlobalKey<AnimatedCircularChartState> _guessedchartKey =
      GlobalKey<AnimatedCircularChartState>();

  @override
  void initState() {
    super.initState();
    getMeritList();
  }

  String roundAndFormatDouble(String value) {
    double doubleValue = double.tryParse(value) ?? 0.0;
    int roundedValue = doubleValue.round();
    return roundedValue.toString();
  }

  Future<void> getMeritList() async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onMeritListApiCall(widget.examId);
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);

    // Chart data — preserved contract (same entries, same keys, same colors).
    final List<CircularStackEntry> data = <CircularStackEntry>[
      CircularStackEntry(
        <CircularSegmentEntry>[
          CircularSegmentEntry(
            double.tryParse(
                    widget.reports?.incorrectAnswersPercentage ?? "0") ??
                0,
            ThemeManager.incorrectChart,
            rankKey: 'Q1',
          ),
          CircularSegmentEntry(
            double.tryParse(widget.reports?.correctAnswersPercentage ?? "0") ??
                0,
            ThemeManager.correctChart,
            rankKey: 'Q2',
          ),
          CircularSegmentEntry(
            double.tryParse(widget.reports?.skippedAnswersPercentage ?? "0") ??
                0,
            ThemeManager.skipChart,
            rankKey: 'Q3',
          ),
        ],
        rankKey: 'Quarterly Profits',
      ),
    ];

    final List<CircularStackEntry> datax = <CircularStackEntry>[
      CircularStackEntry(
        <CircularSegmentEntry>[
          CircularSegmentEntry(
            widget.reports?.correctGuessCount?.toDouble() ?? 0,
            ThemeManager.greenSuccess,
            rankKey: 'Q1',
          ),
          CircularSegmentEntry(
            widget.reports?.wrongGuessCount?.toDouble() ?? 0,
            ThemeManager.redAlert,
            rankKey: 'Q2',
          ),
        ],
        rankKey: 'Guessed_Questions_Stats',
      ),
    ];

    final String correctAnsPercentage =
        roundAndFormatDouble(widget.reports?.correctAnswersPercentage ?? "0.0");
    final String incorrectAnsPercentage = roundAndFormatDouble(
        widget.reports?.incorrectAnswersPercentage.toString() ?? "");
    final String skippedAnsPercentage = roundAndFormatDouble(
        widget.reports?.skippedAnswersPercentage.toString() ?? "");
    final String accuracyPercentage = roundAndFormatDouble(
        widget.reports?.accuracyPercentage.toString() ?? "");

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamed(Routes.reportsCategoryList);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        body: Observer(builder: (BuildContext context) {
          final List<MeritListModel?> meritList = store.meritList;
          if (store.isLoading) {
            return _LoadingState();
          }
          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                _Header(onBack: () => Navigator.pop(context)),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTokens.surface(context),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTokens.r28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.s20,
                        AppTokens.s24,
                        AppTokens.s20,
                        AppTokens.s32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _AnalyticsSection(
                            icon: 'assets/image/award.svg',
                            title: 'EduMetrics',
                            initiallyExpanded: true,
                            child: _EduMetricsBody(
                              chartKey: _chartKey,
                              data: data,
                              totalQuestions:
                                  widget.reports?.question?.toString() ?? "0",
                              correctPct: correctAnsPercentage,
                              incorrectPct: incorrectAnsPercentage,
                              skippedPct: skippedAnsPercentage,
                              accuracyPct: accuracyPercentage,
                              timeTaken:
                                  widget.reports?.Time?.toString() ?? "-",
                            ),
                          ),
                          const SizedBox(height: AppTokens.s16),
                          _AnalyticsSection(
                            icon: 'assets/image/award.svg',
                            title: 'Guess Analytics',
                            child: _GuessAnalyticsBody(
                              chartKey: _guessedchartKey,
                              datax: datax,
                              noGuesses: (widget.reports?.wrongGuessCount ==
                                      0 &&
                                  widget.reports?.correctGuessCount == 0),
                              guessedCount: widget.reports?.guessedAnswersCount
                                      ?.toString() ??
                                  "0",
                              correctGuess:
                                  "${widget.reports?.correctGuessCount ?? 0}",
                              wrongGuess:
                                  "${widget.reports?.wrongGuessCount ?? 0}",
                            ),
                          ),
                          const SizedBox(height: AppTokens.s16),
                          _AnalyticsSection(
                            icon: 'assets/image/award.svg',
                            title: 'Answer Evolve',
                            child: _AnswerEvolveBody(
                              correctToIncorrect:
                                  "${widget.reports?.correct_incorrect ?? 0}",
                              incorrectToCorrect:
                                  "${widget.reports?.incorrect_correct ?? 0}",
                              incorrectToIncorrect:
                                  "${widget.reports?.incorrect_incorres ?? 0}",
                            ),
                          ),
                          const SizedBox(height: AppTokens.s32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTokens.brand.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s12,
        AppTokens.s16,
        AppTokens.s20,
        AppTokens.s20,
      ),
      child: Row(
        children: [
          _HeaderIconBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: AppTokens.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Report',
                  style: AppTokens.overline(context).copyWith(
                    color: Colors.white.withOpacity(0.75),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Detailed Analytics',
                  style: AppTokens.titleLg(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: const SizedBox(
          height: 40,
          width: 40,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading
// ---------------------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NutsActivityIndicator(
            activeColor: AppTokens.accent(context),
            animating: true,
            radius: 20,
          ),
          const SizedBox(height: AppTokens.s16),
          Text(
            'Getting everything ready for you... Just a moment!',
            style: AppTokens.body(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Collapsible section shell — replaces ExpansionTile boilerplate.
// ---------------------------------------------------------------------------

class _AnalyticsSection extends StatelessWidget {
  final String icon;
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const _AnalyticsSection({
    required this.icon,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: AppTokens.shadow1(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s8,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppTokens.s16,
            0,
            AppTokens.s16,
            AppTokens.s20,
          ),
          iconColor: AppTokens.ink(context),
          collapsedIconColor: AppTokens.ink2(context),
          title: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: AppTokens.radius12,
                ),
                child: SvgPicture.asset(
                  icon,
                  width: 22,
                  color: AppTokens.accent(context),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Text(
                  title,
                  style: AppTokens.titleSm(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          children: [child],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EduMetrics body — donut chart + legend + accuracy/time stats.
// ---------------------------------------------------------------------------

class _EduMetricsBody extends StatelessWidget {
  final GlobalKey<AnimatedCircularChartState> chartKey;
  final List<CircularStackEntry> data;
  final String totalQuestions;
  final String correctPct;
  final String incorrectPct;
  final String skippedPct;
  final String accuracyPct;
  final String timeTaken;

  const _EduMetricsBody({
    required this.chartKey,
    required this.data,
    required this.totalQuestions,
    required this.correctPct,
    required this.incorrectPct,
    required this.skippedPct,
    required this.accuracyPct,
    required this.timeTaken,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final bool wide = c.maxWidth > 600;
      final chart = SizedBox(
        width: wide ? 340 : 260,
        height: wide ? 320 : 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedCircularChart(
              key: chartKey,
              size: Size(wide ? 340 : 240, wide ? 320 : 240),
              initialChartData: data,
              holeRadius: wide ? 50 : 40,
              chartType: CircularChartType.Radial,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Questions',
                  style: AppTokens.caption(context),
                ),
                const SizedBox(height: 4),
                Text(
                  totalQuestions,
                  style: AppTokens.displayMd(context).copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      final legend = Wrap(
        spacing: AppTokens.s16,
        runSpacing: AppTokens.s8,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _LegendChip(
            color: ThemeManager.correctChart,
            label: 'Correct',
            value: '$correctPct%',
          ),
          _LegendChip(
            color: ThemeManager.incorrectChart,
            label: 'Incorrect',
            value: '$incorrectPct%',
          ),
          _LegendChip(
            color: ThemeManager.skipChart,
            label: 'Skipped',
            value: '$skippedPct%',
          ),
        ],
      );

      final stats = Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Accuracy',
              value: '$accuracyPct%',
              gradient: LinearGradient(
                colors: [
                  ThemeManager.edugradiet.withOpacity(0.0),
                  ThemeManager.edugradiet,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              svg: 'assets/image/accuracy.svg',
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: _StatCard(
              label: 'Time Taken',
              value: timeTaken,
              gradient: LinearGradient(
                colors: [
                  ThemeManager.edugradiet2.withOpacity(0.0),
                  ThemeManager.edugradiet2,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              svg: 'assets/image/timeTaken.svg',
            ),
          ),
        ],
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: chart),
          const SizedBox(height: AppTokens.s16),
          legend,
          const SizedBox(height: AppTokens.s20),
          stats,
        ],
      );
    });
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendChip({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppTokens.s8),
        Text(
          label,
          style: AppTokens.body(context).copyWith(
            color: AppTokens.ink(context),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($value)',
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w700,
            color: AppTokens.ink(context),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Guess Analytics body — empty state OR donut + stats.
// ---------------------------------------------------------------------------

class _GuessAnalyticsBody extends StatelessWidget {
  final GlobalKey<AnimatedCircularChartState> chartKey;
  final List<CircularStackEntry> datax;
  final bool noGuesses;
  final String guessedCount;
  final String correctGuess;
  final String wrongGuess;

  const _GuessAnalyticsBody({
    required this.chartKey,
    required this.datax,
    required this.noGuesses,
    required this.guessedCount,
    required this.correctGuess,
    required this.wrongGuess,
  });

  @override
  Widget build(BuildContext context) {
    if (noGuesses) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTokens.surface2(context),
          borderRadius: AppTokens.radius12,
          border: Border.all(color: AppTokens.border(context)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.help_outline_rounded,
              color: AppTokens.muted(context),
              size: 32,
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              'No Answer is Guessed',
              style: AppTokens.titleSm(context),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedCircularChart(
                key: chartKey,
                size: const Size(260, 260),
                initialChartData: datax,
                holeRadius: 30,
                chartType: CircularChartType.Radial,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Guessed Answers',
                    style: AppTokens.caption(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    guessedCount,
                    style: AppTokens.displayMd(context).copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Correct Answer',
                value: correctGuess,
                gradient: LinearGradient(
                  colors: [
                    ThemeManager.edugradiet2.withOpacity(0.0),
                    ThemeManager.edugradiet2,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                svg: 'assets/image/accuracy.svg',
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: _StatCard(
                label: 'Incorrect Answer',
                value: wrongGuess,
                gradient: LinearGradient(
                  colors: [
                    ThemeManager.edugradiet3.withOpacity(0.0),
                    ThemeManager.edugradiet3,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                svg: 'assets/image/accuracy.svg',
                flipY: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Answer Evolve body — 3 gradient-border stat cards.
// ---------------------------------------------------------------------------

class _AnswerEvolveBody extends StatelessWidget {
  final String correctToIncorrect;
  final String incorrectToCorrect;
  final String incorrectToIncorrect;

  const _AnswerEvolveBody({
    required this.correctToIncorrect,
    required this.incorrectToCorrect,
    required this.incorrectToIncorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EvolveCard(
          label: 'Correct to Incorrect',
          value: correctToIncorrect,
          gradient: LinearGradient(
            colors: [ThemeManager.evolveGreen, ThemeManager.evolveRed],
          ),
          badgeGradient: LinearGradient(
            colors: [
              ThemeManager.edugradiet3.withOpacity(0.0),
              ThemeManager.edugradiet3,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          svg: 'assets/image/accuracy.svg',
          flipY: true,
        ),
        const SizedBox(height: AppTokens.s12),
        _EvolveCard(
          label: 'Incorrect to Correct',
          value: incorrectToCorrect,
          gradient: LinearGradient(
            colors: [ThemeManager.evolveRed, ThemeManager.evolveGreen],
          ),
          badgeGradient: LinearGradient(
            colors: [
              ThemeManager.edugradiet2.withOpacity(0.0),
              ThemeManager.edugradiet2,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          svg: 'assets/image/accuracy.svg',
        ),
        const SizedBox(height: AppTokens.s12),
        _EvolveCard(
          label: 'Incorrect to Incorrect',
          value: incorrectToIncorrect,
          border: Border.all(color: ThemeManager.evolveYellow, width: 1),
          badgeGradient: LinearGradient(
            colors: [
              ThemeManager.evolveYellow.withOpacity(0.36),
              ThemeManager.evolveYellow,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          svg: 'assets/image/accuracy2.svg',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared stat card (used in EduMetrics + Guess Analytics)
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Gradient gradient;
  final String svg;
  final bool flipY;

  const _StatCard({
    required this.label,
    required this.value,
    required this.gradient,
    required this.svg,
    this.flipY = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: AppTokens.shadow1(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTokens.caption(context),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTokens.titleMd(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Container(
            height: 36,
            width: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: AppTokens.radius8,
            ),
            child: Transform.flip(
              flipY: flipY,
              child: SvgPicture.asset(
                svg,
                width: 18,
                color: AppTokens.ink(context).withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Evolve card — gradient-bordered, used for the 3 Answer Evolve rows.
// ---------------------------------------------------------------------------

class _EvolveCard extends StatelessWidget {
  final String label;
  final String value;
  final LinearGradient? gradient;
  final BoxBorder? border;
  final Gradient badgeGradient;
  final String svg;
  final bool flipY;

  const _EvolveCard({
    required this.label,
    required this.value,
    this.gradient,
    this.border,
    required this.badgeGradient,
    required this.svg,
    this.flipY = false,
  });

  @override
  Widget build(BuildContext context) {
    final BoxBorder effectiveBorder = border ??
        GradientBoxBorder(
          gradient: gradient ?? const LinearGradient(colors: [Colors.grey, Colors.grey]),
          width: 1,
        );
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        border: effectiveBorder,
        boxShadow: AppTokens.shadow1(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTokens.caption(context),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTokens.titleMd(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Container(
            height: 36,
            width: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: badgeGradient,
              borderRadius: AppTokens.radius8,
            ),
            child: Transform.flip(
              flipY: flipY,
              child: SvgPicture.asset(
                svg,
                width: 18,
                color: AppTokens.ink(context).withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
