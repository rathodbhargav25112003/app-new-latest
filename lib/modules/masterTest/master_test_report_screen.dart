// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, unused_local_variable, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names, dead_null_aware_expression, dead_code

import 'package:shusruta_lms/helpers/forked_packages/circular_chart_flutter/lib/circular_chart_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:nuts_activity_indicator/nuts_activity_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/models/report_by_category_model.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/get_report_by_topic_name_model.dart';
import '../../models/merit_list_model.dart';
import '../reports/store/report_by_category_store.dart';

/// Post-submission analysis & solutions screen for the master-test runner.
/// Redesigned with AppTokens while preserving:
///   • Constructor `MasterTestReportScreen({super.key, required title, reports,
///     isTrend, required userexamId, required showPredictive, required examId,
///     categoryId})`
///   • Static `route(RouteSettings)` factory returning a `CupertinoPageRoute`
///     that reads `title / report / isTrend / userexamId / examId /
///     category_id / showPredictive` from the arguments map
///   • State fields `_chartKey`, `_guessedchartkey`, `_topicNameKey`,
///     `selectedValue`, `topicName`, `correctAnswers`, `incorrectAnswers`,
///     `skippedAnswers`, `guessedAnswers`, `_isTopicNameValid`, `topicNames`
///   • initState sequence: `getReportByTopicNameList()` → `getMeritList()`
///     → `getReportByStregthList()`
///   • Helper signatures verbatim: `_getSolutionReport(examId, filter)`,
///     `getReportByStregthList()`, `roundAndFormatDouble(value)`,
///     `getReportByTopicNameList()`, `getMeritList()`
///   • Solutions button → `_getSolutionReport(widget.userexamId, "View all")`
///     → `pushNamed(Routes.solutionMasterReport, arguments: {solutionReport,
///     filterVal, userExamId})`
///   • Detailed Analytics button → `pushNamed(
///     Routes.masterTestReportDetailsScreen, arguments: {report, title,
///     userexamId, examId, category_id, isTrend, showPredictive})`
///   • Back arrow → `pushNamed(Routes.allTestCategory, arguments:
///     {'fromhome': true})` (intentionally pushes, not pops)
///   • WillPopScope → `Navigator.pop` + return false
///   • Observer isLoading gate → NutsActivityIndicator
///   • `_ChartData` class + `_getStackedColumnSeries(...)` legacy helpers
class MasterTestReportScreen extends StatefulWidget {
  final String title;
  final ReportByCategoryModel? reports;
  final String userexamId;
  final String? categoryId;
  final String examId;
  final bool showPredictive;
  final bool? isTrend;
  const MasterTestReportScreen(
      {super.key,
      required this.title,
      this.reports,
      this.isTrend,
      required this.userexamId,
      required this.showPredictive,
      required this.examId,
      this.categoryId});
  @override
  State<MasterTestReportScreen> createState() => _MasterTestReportScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => MasterTestReportScreen(
        title: arguments['title'],
        reports: arguments['report'],
        isTrend: arguments['isTrend'] ?? false,
        userexamId: arguments['userexamId'],
        examId: arguments['examId'],
        categoryId: arguments['category_id'] ?? "",
        showPredictive: arguments['showPredictive'] ?? false,
      ),
    );
  }
}

class _MasterTestReportScreenState extends State<MasterTestReportScreen> {
  final GlobalKey<AnimatedCircularChartState> _chartKey =
      GlobalKey<AnimatedCircularChartState>();
  final GlobalKey<AnimatedCircularChartState> _guessedchartkey =
      GlobalKey<AnimatedCircularChartState>();
  final _topicNameKey = GlobalKey<FormFieldState<String>>();
  String selectedValue = '';
  String? topicName;
  int? correctAnswers;
  int? incorrectAnswers;
  int? skippedAnswers;
  int? guessedAnswers;
  final bool _isTopicNameValid = false;
  List<ReportByTopicNameModel?> topicNames = [];

  @override
  void initState() {
    super.initState();
    getReportByTopicNameList();
    getMeritList();
    getReportByStregthList();
  }

  Future<void> _getSolutionReport(String examId, String filter) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onMasterSolutionReportApiCall(examId).then((_) {
      Navigator.of(context).pushNamed(Routes.solutionMasterReport, arguments: {
        'solutionReport': store.masterSolutionReportCategory,
        'filterVal': filter,
        'userExamId': examId
      });
    });
  }

  Future<void> getReportByStregthList() async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onReportByTopicStengthApiCall(widget.userexamId ?? "");
    print(
        'store.reportbytopicstreght ${store.reportbytopicstreght[0]?.lastThreeIncorrect?[0].topicName}');
  }

  String roundAndFormatDouble(String value) {
    double doubleValue = double.tryParse(value) ?? 0.0;
    int roundedValue = doubleValue.round();
    return roundedValue.toString();
  }

  Future<void> getReportByTopicNameList() async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onReportByTopicNameApiCall(widget.userexamId ?? "", "0");
    debugPrint(
        'reportbytopicname12${store.reportbytopicname.map((e) => e?.topicName)}');
    debugPrint('widget.examId12${widget.userexamId}');
    setState(() {
      topicNames = store.reportbytopicname;
    });
  }

  Future<void> getMeritList() async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onMasterMeritListApiCall(widget.examId ?? "");
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);

    // ---------------------------------------------------------------
    // Preserved chart / pct computations (kept for parity even when
    // not rendered — preserves debugPrint side-effects + ensures any
    // downstream legacy referrers continue to compile).
    // ---------------------------------------------------------------
    List<CircularStackEntry> data = <CircularStackEntry>[
      CircularStackEntry(
        <CircularSegmentEntry>[
          CircularSegmentEntry(
              double.tryParse(
                      widget.reports?.incorrectAnswersPercentage ?? "0") ??
                  0,
              ThemeManager.redAlert,
              rankKey: 'Q1'),
          CircularSegmentEntry(
              double.tryParse(
                      widget.reports?.correctAnswersPercentage ?? "0") ??
                  0,
              ThemeManager.greenSuccess,
              rankKey: 'Q2'),
          CircularSegmentEntry(
              double.tryParse(
                      widget.reports?.skippedAnswersPercentage ?? "0") ??
                  0,
              const Color(0xFFFF9F59),
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
    debugPrint("originalDate:${widget.reports?.date}");
    DateTime parsedDate =
        originalDate.isEmpty ? DateTime.now() : DateTime.parse(originalDate);
    final formatter = DateFormat('dd MMM, yyyy');
    String formattedDate = formatter.format(parsedDate);

    List<CircularStackEntry> datay = <CircularStackEntry>[
      CircularStackEntry(
        <CircularSegmentEntry>[
          CircularSegmentEntry(
              widget.reports?.correctGuessCount?.toDouble() ?? 0,
              ThemeManager.greenSuccess,
              rankKey: 'Q1'),
          CircularSegmentEntry(widget.reports?.wrongGuessCount?.toDouble() ?? 0,
              ThemeManager.redAlert,
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

    List<DropdownMenuItem<String>> dropdownItems = topicNames.map((item) {
      final topicName = item?.topicName;
      return DropdownMenuItem<String>(
        value: topicName,
        child: Text(topicName!),
      );
    }).toList();

    final String attemptCount = widget.reports?.isAttemptcount.toString() ?? "";
    final String marksRatio =
        "$myMarks/${widget.reports?.mark.toString() ?? ""}";

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        body: Observer(
          builder: (BuildContext context) {
            List<MeritListModel?> meritList = store.meritList;
            if (store.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    NutsActivityIndicator(
                      activeColor: AppTokens.accent(context),
                      animating: true,
                      radius: 20,
                    ),
                    const SizedBox(height: AppTokens.s12),
                    Text(
                      "Getting everything ready for you... Just a moment!",
                      style: AppTokens.body(context),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                // -------------------------------------------------
                // Brand gradient header
                // -------------------------------------------------
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTokens.brand, AppTokens.brand2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + AppTokens.s12,
                    left: AppTokens.s16,
                    right: AppTokens.s16,
                    bottom: AppTokens.s20,
                  ),
                  child: Row(
                    children: [
                      _CircleBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                              Routes.allTestCategory,
                              arguments: {'fromhome': true});
                        },
                      ),
                      const SizedBox(width: AppTokens.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Report",
                              style: AppTokens.overline(context)
                                  .copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Analysis & Solutions",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTokens.titleMd(context)
                                  .copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // -------------------------------------------------
                // Body sheet
                // -------------------------------------------------
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTokens.scaffold(context),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.s16,
                        AppTokens.s20,
                        AppTokens.s16,
                        AppTokens.s24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // -----------------------------------------
                          // Summary card — title + attempt + meta
                          // -----------------------------------------
                          _SummaryCard(
                            title: widget.title,
                            attemptCount: attemptCount,
                            formattedDate: formattedDate,
                            onSolutions: () => _getSolutionReport(
                                widget.userexamId, "View all"),
                            onAnalytics: () {
                              Navigator.of(context).pushNamed(
                                  Routes.masterTestReportDetailsScreen,
                                  arguments: {
                                    'report': widget.reports,
                                    'title': widget.title,
                                    'userexamId': widget.userexamId,
                                    'examId': widget.examId,
                                    'category_id': widget.categoryId,
                                    'isTrend': widget.isTrend ?? false,
                                    'showPredictive': widget.showPredictive
                                  });
                            },
                          ),
                          const SizedBox(height: AppTokens.s16),
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

  /// Preserved legacy helper for the Syncfusion stacked-column series that
  /// was previously used for per-topic analytics. Intentionally kept —
  /// callers may still reach it through mixins or subclasses.
  List<ChartSeries<_ChartData, String>> _getStackedColumnSeries(
      name, correct, incorrect, skipped, guessed) {
    final List<_ChartData> data = [
      _ChartData(name, correct, incorrect, skipped, guessed),
    ];

    return [
      StackedColumnSeries<_ChartData, String>(
          dataSource: data,
          xValueMapper: (_ChartData sales, _) => sales.topicName,
          yValueMapper: (_ChartData sales, _) => sales.correct,
          name: 'Correct',
          color: ThemeManager.greenSuccess),
      StackedColumnSeries<_ChartData, String>(
          dataSource: data,
          xValueMapper: (_ChartData sales, _) => sales.topicName,
          yValueMapper: (_ChartData sales, _) => sales.incorrect,
          name: 'incorrect',
          color: ThemeManager.redAlert),
      StackedColumnSeries<_ChartData, String>(
        dataSource: data,
        xValueMapper: (_ChartData sales, _) => sales.topicName,
        yValueMapper: (_ChartData sales, _) => sales.skip,
        name: 'Skipped',
        color: const Color(0xFFFF9F59),
      ),
      StackedColumnSeries<_ChartData, String>(
          dataSource: data,
          xValueMapper: (_ChartData sales, _) => sales.topicName,
          yValueMapper: (_ChartData sales, _) => sales.guess,
          name: 'Guessed',
          color: const Color(0xFF6457F0)),
    ];
  }
}

// ============================================================
//                        Primitives
// ============================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.attemptCount,
    required this.formattedDate,
    required this.onSolutions,
    required this.onAnalytics,
  });

  final String title;
  final String attemptCount;
  final String formattedDate;
  final VoidCallback onSolutions;
  final VoidCallback onAnalytics;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: AppTokens.accent(context),
                  size: 22,
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
                      style: AppTokens.titleSm(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Attempt $attemptCount  ·  $formattedDate",
                      style: AppTokens.caption(context)
                          .copyWith(color: AppTokens.ink2(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          Divider(
            height: 1,
            thickness: 1,
            color: AppTokens.border(context),
          ),
          const SizedBox(height: AppTokens.s16),
          Row(
            children: [
              Expanded(
                child: _ReportActionBtn(
                  label: "Solutions",
                  onTap: onSolutions,
                  tone: _ActionTone.outline,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: _ReportActionBtn(
                  label: "Detailed Analytics",
                  onTap: onAnalytics,
                  tone: _ActionTone.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _ActionTone { primary, outline }

class _ReportActionBtn extends StatelessWidget {
  const _ReportActionBtn({
    required this.label,
    required this.onTap,
    required this.tone,
  });

  final String label;
  final VoidCallback onTap;
  final _ActionTone tone;

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = tone == _ActionTone.primary;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
                    colors: [AppTokens.brand, AppTokens.brand2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isPrimary ? null : AppTokens.surface2(context),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: isPrimary
                ? null
                : Border.all(color: AppTokens.border(context)),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTokens.titleSm(context).copyWith(
                color: isPrimary ? Colors.white : AppTokens.ink(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _ChartData {
  _ChartData(
      this.topicName, this.correct, this.incorrect, this.skip, this.guess);

  final String topicName;
  final int correct;
  final int incorrect;
  final int skip;
  final int guess;
}
