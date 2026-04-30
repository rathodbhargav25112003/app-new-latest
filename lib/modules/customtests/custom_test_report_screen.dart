// ignore_for_file: use_build_context_synchronously, deprecated_member_use, use_super_parameters, unused_import, unused_field, unused_local_variable, unused_element

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:nuts_activity_indicator/nuts_activity_indicator.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/helpers/forked_packages/circular_chart_flutter/lib/circular_chart_flutter.dart';
import 'package:shusruta_lms/models/report_by_category_model.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/merit_list_model.dart';
import '../reports/store/report_by_category_store.dart';
import 'model/custom_test_report_by_category_model.dart';

class CustomTestReportScreen extends StatefulWidget {
  final String title;
  final CustomTestReportByCategoryModel? reports;
  final String userexamId;
  final String examId;
  const CustomTestReportScreen(
      {Key? key,
      required this.title,
      this.reports,
      required this.userexamId,
      required this.examId})
      : super(key: key);
  @override
  State<CustomTestReportScreen> createState() => _CustomTestReportScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => CustomTestReportScreen(
        title: arguments['title'],
        reports: arguments['report'],
        userexamId: arguments['userexamId'],
        examId: arguments['examId'],
      ),
    );
  }
}

class _CustomTestReportScreenState extends State<CustomTestReportScreen> {
  // Preserved parity: keys are referenced by legacy chart widgets the
  // screen no longer renders directly, but downstream callbacks may
  // still wire them up via the store.
  final GlobalKey<AnimatedCircularChartState> _chartKey =
      GlobalKey<AnimatedCircularChartState>();
  final GlobalKey<AnimatedCircularChartState> _guessedchartKey =
      GlobalKey<AnimatedCircularChartState>();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _getSolutionReport(String examId, String filter) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onCustomTestSolutionReportApiCall(examId).then((_) {
      Navigator.of(context)
          .pushNamed(Routes.customTestSolutionReport, arguments: {
        'solutionReport': store.customTestSolutionReportCategory,
        'filterVal': filter,
        'userExamId': examId
      });
    });
  }

  String roundAndFormatDouble(String value) {
    double doubleValue = double.tryParse(value) ?? 0.0;
    int roundedValue = doubleValue.round();
    return roundedValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    // Kept for legacy chart parity; not rendered directly by this polish pass.
    List<CircularStackEntry> data = <CircularStackEntry>[
      CircularStackEntry(
        <CircularSegmentEntry>[
          CircularSegmentEntry(
              double.tryParse(
                      widget.reports?.incorrectAnswersPercentage ?? "0") ??
                  0,
              AppTokens.danger(context),
              rankKey: 'Q1'),
          CircularSegmentEntry(
              double.tryParse(
                      widget.reports?.correctAnswersPercentage ?? "0") ??
                  0,
              AppTokens.success(context),
              rankKey: 'Q2'),
          CircularSegmentEntry(
              double.tryParse(
                      widget.reports?.skippedAnswersPercentage ?? "0") ??
                  0,
              AppTokens.warning(context),
              rankKey: 'Q3'),
        ],
        rankKey: 'Quarterly Profits',
      ),
    ];

    double percentageValue =
        double.tryParse(widget.reports?.percentage ?? "") ?? 0;
    String percentage =
        (percentageValue >= 0) ? percentageValue.toString() : "0";
    String myMarks = (widget.reports?.myMark ?? 0) >= 0
        ? widget.reports?.myMark.toString() ?? ""
        : "0";
    String originalDate = widget.reports?.date ?? "";
    DateTime parsedDate =
        DateTime.tryParse(originalDate) ?? DateTime.now();
    final formatter = DateFormat('dd MMM, yyyy');
    String formattedDate = formatter.format(parsedDate);
    List<CircularStackEntry> datax = <CircularStackEntry>[
      CircularStackEntry(
        <CircularSegmentEntry>[
          CircularSegmentEntry(
              widget.reports?.correctGuessCount?.toDouble() ?? 0,
              AppTokens.success(context),
              rankKey: 'Q1'),
          CircularSegmentEntry(widget.reports?.wrongGuessCount?.toDouble() ?? 0,
              AppTokens.danger(context),
              rankKey: 'Q2'),
        ],
        rankKey: 'Guessed_Questions_Stats',
      ),
    ];
    String correctAnsPercentage =
        roundAndFormatDouble(widget.reports?.correctAnswersPercentage ?? "0.0");
    String incorrectAnsPercentage = roundAndFormatDouble(
        widget.reports?.incorrectAnswersPercentage.toString() ?? "");
    String skippedAnsPercentage = roundAndFormatDouble(
        widget.reports?.skippedAnswersPercentage.toString() ?? "");
    String accuracyPercentage = roundAndFormatDouble(
        widget.reports?.accuracyPercentage.toString() ?? "");

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamed(Routes.testCategory);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        body: Observer(
          builder: (BuildContext context) {
            List<MeritListModel?> meritList = store.meritList;
            if (store.isLoading) {
              return _LoadingState();
            }
            return Column(
              children: [
                _GradientHeader(
                  title: 'Analysis & Solutions',
                  subtitle: 'Your performance snapshot',
                  onBack: () =>
                      Navigator.of(context).pushNamed(Routes.testCategory),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTokens.scaffold(context),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppTokens.r28),
                        topRight: Radius.circular(AppTokens.r28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.s20,
                        AppTokens.s20,
                        AppTokens.s20,
                        AppTokens.s24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SummaryCard(
                            title: widget.title,
                            attemptLabel:
                                'Attempt ${widget.reports?.isAttemptcount.toString() ?? ""} · $formattedDate',
                            myMarks: myMarks,
                            totalMarks: widget.reports?.mark.toString() ?? '',
                            percentage: percentage,
                          ),
                          const SizedBox(height: AppTokens.s16),
                          _BreakdownCard(
                            correctPct: correctAnsPercentage,
                            incorrectPct: incorrectAnsPercentage,
                            skippedPct: skippedAnsPercentage,
                            accuracyPct: accuracyPercentage,
                          ),
                          const SizedBox(height: AppTokens.s20),
                          Row(
                            children: [
                              Expanded(
                                child: _OutlinedActionButton(
                                  label: 'Solutions',
                                  icon: Icons.menu_book_rounded,
                                  onTap: () => _getSolutionReport(
                                      widget.userexamId, "View all"),
                                ),
                              ),
                              const SizedBox(width: AppTokens.s12),
                              Expanded(
                                child: _GradientActionButton(
                                  label: 'Analysis',
                                  icon: Icons.insights_rounded,
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                      Routes.customTestReportDetailsScreen,
                                      arguments: {
                                        'report': widget.reports,
                                        'title': widget.title,
                                        'userexamId': widget.userexamId,
                                        'examId': widget.examId
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// Private UI primitives
// ============================================================================

class _GradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  const _GradientHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTokens.s12,
        left: AppTokens.s16,
        right: AppTokens.s16,
        bottom: AppTokens.s24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white.withOpacity(0.15),
            borderRadius: AppTokens.radius12,
            child: InkWell(
              borderRadius: AppTokens.radius12,
              onTap: onBack,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTokens.titleLg(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTokens.caption(context).copyWith(
                    color: Colors.white.withOpacity(0.85),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s32),
            child: Text(
              "Getting everything ready for you... Just a moment!",
              textAlign: TextAlign.center,
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink2(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String attemptLabel;
  final String myMarks;
  final String totalMarks;
  final String percentage;
  const _SummaryCard({
    required this.title,
    required this.attemptLabel,
    required this.myMarks,
    required this.totalMarks,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius20,
        border: Border.all(color: AppTokens.border(context), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius: AppTokens.radius16,
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: AppTokens.accent(context),
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.titleSm(context).copyWith(
                          color: AppTokens.ink(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        attemptLabel,
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.ink2(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s16),
            Divider(color: AppTokens.border(context), height: 0),
            const SizedBox(height: AppTokens.s16),
            Row(
              children: [
                Expanded(
                  child: _MetricBlock(
                    icon: Icons.workspace_premium_outlined,
                    tone: AppTokens.accent(context),
                    soft: AppTokens.accentSoft(context),
                    label: 'My Marks',
                    value: '$myMarks/$totalMarks',
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: _MetricBlock(
                    icon: Icons.percent_rounded,
                    tone: AppTokens.success(context),
                    soft: AppTokens.successSoft(context),
                    label: 'Percentage',
                    value: '$percentage%',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final Color soft;
  final String label;
  final String value;
  const _MetricBlock({
    required this.icon,
    required this.tone,
    required this.soft,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: AppTokens.radius12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tone, size: 18),
              const SizedBox(width: AppTokens.s8),
              Text(
                label,
                style: AppTokens.overline(context).copyWith(
                  color: tone,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s4),
          Text(
            value,
            style: AppTokens.titleMd(context).copyWith(
              color: tone,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String correctPct;
  final String incorrectPct;
  final String skippedPct;
  final String accuracyPct;
  const _BreakdownCard({
    required this.correctPct,
    required this.incorrectPct,
    required this.skippedPct,
    required this.accuracyPct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius20,
        border: Border.all(color: AppTokens.border(context), width: 1.1),
      ),
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Performance',
                style: AppTokens.titleSm(context).copyWith(
                  color: AppTokens.ink(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s12,
                  vertical: AppTokens.s4,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.successSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                ),
                child: Text(
                  'Accuracy · $accuracyPct%',
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.success(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          _BreakdownRow(
            label: 'Correct',
            percent: correctPct,
            tone: AppTokens.success(context),
            soft: AppTokens.successSoft(context),
          ),
          const SizedBox(height: AppTokens.s8),
          _BreakdownRow(
            label: 'Incorrect',
            percent: incorrectPct,
            tone: AppTokens.danger(context),
            soft: AppTokens.dangerSoft(context),
          ),
          const SizedBox(height: AppTokens.s8),
          _BreakdownRow(
            label: 'Skipped',
            percent: skippedPct,
            tone: AppTokens.warning(context),
            soft: AppTokens.warningSoft(context),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String percent;
  final Color tone;
  final Color soft;
  const _BreakdownRow({
    required this.label,
    required this.percent,
    required this.tone,
    required this.soft,
  });

  @override
  Widget build(BuildContext context) {
    final pctValue = double.tryParse(percent) ?? 0;
    final clamped = pctValue.clamp(0, 100) / 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: tone,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            Text(
              label,
              style: AppTokens.caption(context).copyWith(
                color: AppTokens.ink(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$percent%',
              style: AppTokens.caption(context).copyWith(
                color: tone,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.r8),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: clamped.toDouble(),
            backgroundColor: soft,
            valueColor: AlwaysStoppedAnimation<Color>(tone),
          ),
        ),
      ],
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlinedActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surface2(context),
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius12,
            border: Border.all(color: AppTokens.border(context), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppTokens.ink(context)),
              const SizedBox(width: AppTokens.s8),
              Text(
                label,
                style: AppTokens.titleSm(context).copyWith(
                  color: AppTokens.ink(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
            ),
            borderRadius: AppTokens.radius12,
            boxShadow: [
              BoxShadow(
                color: AppTokens.brand.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: AppTokens.s8),
              Text(
                label,
                style: AppTokens.titleSm(context).copyWith(
                  color: Colors.white,
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
