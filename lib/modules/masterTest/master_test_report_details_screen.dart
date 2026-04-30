// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, unused_local_variable, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names, dead_null_aware_expression, dead_code

import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:intl/intl.dart';
import 'package:nuts_activity_indicator/nuts_activity_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/forked_packages/circular_chart_flutter/lib/circular_chart_flutter.dart';
import 'package:shusruta_lms/models/report_by_category_model.dart';
import 'package:shusruta_lms/models/strength_model.dart';
import 'package:shusruta_lms/modules/masterTest/leader_board_screen.dart';
import 'package:shusruta_lms/modules/masterTest/strength_weakness_graph.dart';
import 'package:shusruta_lms/modules/reports/trend_analysis_list.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/get_report_by_topic_name_model.dart';
import '../../models/merit_list_model.dart';
import '../reports/store/report_by_category_store.dart';

/// Full analytics break-down shown from the master-test report screen.
/// Redesigned around AppTokens with condensed stat helpers while
/// preserving every public touch-point:
///   • Constructor `MasterTestReportDetailsScreen({super.key, required
///     title, reports, required userexamId, required categoryId,
///     showPredictive = false, isTrend = false, required examId})`
///   • Static `route(RouteSettings)` factory → CupertinoPageRoute with
///     `title/report/userexamId/isTrend/category_id/showPredictive/examId`
///   • State fields `_chartKey`, `_chartKey2`, `_guessedchartKey`,
///     `_guessedchartKey2`, `_topicchartKey`, `_topicNameKey`,
///     `selectedValue`, `topicNames`, `_isTopicNameValid`, `topicName`,
///     `topicTime`, `isCompar`, `correctAnswers`, `incorrectAnswers`,
///     `skippedAnswers`, `guessedAnswers`, `totalQuestions`,
///     `totalAnswers` + every `*Compare` twin
///   • initState → `getReportByTopicNameList()` only
///   • Helper signatures verbatim: `_getSolutionReport`, `roundAndFormatDouble`,
///     `getMeritList`, `compareWithRank1`, `getReportByTopicNameList`,
///     `getReportByStregthList`
///   • WillPopScope → `pushNamed(Routes.masterReportsCategoryList)` + false
///   • Back arrow → `Navigator.pop(context)`
///   • `widget.isTrend` → "Series Analysis" entry to `GetTrendAnalysisList(id: categoryId)`
///   • `widget.reports!.isDeclaration` → Compare with Rank 1 toggle
///     (calls `compareWithRank1()` when flipped on)
///   • `widget.showPredictive` → Predictive NEET SS Ranking via `PredictedRankWidget`
///   • Strength / Weakness pills → `StrengthWeaknessGraph(topThreeCorrect|lastThreeIncorrect)`
///   • Preserved helpers at file scope: `_buildPredictedRankRow`,
///     `_buildCustomDivider`, `formatTimeString`, `_ChartData` class,
///     `PredictedRankWidget`, `RankCompare`
class MasterTestReportDetailsScreen extends StatefulWidget {
  final String title;
  final ReportByCategoryModel? reports;
  final String userexamId;
  final String categoryId;
  final String examId;
  final bool showPredictive;
  final bool isTrend;
  const MasterTestReportDetailsScreen(
      {super.key,
      required this.title,
      this.reports,
      required this.userexamId,
      required this.categoryId,
      this.showPredictive = false,
      this.isTrend = false,
      required this.examId});

  @override
  State<MasterTestReportDetailsScreen> createState() =>
      _MasterTestReportDetailsScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => MasterTestReportDetailsScreen(
        title: arguments['title'],
        reports: arguments['report'],
        userexamId: arguments['userexamId'],
        isTrend: arguments['isTrend'] ?? false,
        categoryId: arguments['category_id'] ?? "",
        showPredictive: arguments['showPredictive'] ?? false,
        examId: arguments['examId'],
      ),
    );
  }
}

class _MasterTestReportDetailsScreenState
    extends State<MasterTestReportDetailsScreen> {
  final GlobalKey<AnimatedCircularChartState> _chartKey =
      GlobalKey<AnimatedCircularChartState>();
  final GlobalKey<AnimatedCircularChartState> _chartKey2 =
      GlobalKey<AnimatedCircularChartState>();
  final GlobalKey<AnimatedCircularChartState> _guessedchartKey =
      GlobalKey<AnimatedCircularChartState>();
  final GlobalKey<AnimatedCircularChartState> _guessedchartKey2 =
      GlobalKey<AnimatedCircularChartState>();
  final GlobalKey<AnimatedCircularChartState> _topicchartKey =
      GlobalKey<AnimatedCircularChartState>();
  final _topicNameKey = GlobalKey<FormFieldState<String>>();
  String selectedValue = '';
  List<ReportByTopicNameModel?> topicNames = [];
  bool _isTopicNameValid = false;
  String? topicName;
  String? topicTime;
  bool isCompar = false;
  int? correctAnswers;
  int? incorrectAnswers;
  int? skippedAnswers;
  int? guessedAnswers;
  int? totalQuestions;
  int? totalAnswers;

  String? topicNameCompare;
  String? topicTimeCompare;
  int? correctAnswersCompare;
  int? incorrectAnswersCompare;
  int? skippedAnswersCompare;
  int? guessedAnswersCompare;
  int? totalQuestionsCompare;
  int? totalAnswersCompare;

  @override
  void initState() {
    super.initState();
    getReportByTopicNameList();
  }

  Future<void> _getSolutionReport(String examId, String filter) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onSolutionReportApiCall(examId, "").then((_) {
      Navigator.of(context).pushNamed(Routes.solutionReport, arguments: {
        'solutionReport': store.solutionReportCategory,
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

  Future<void> getMeritList() async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onMasterMeritListApiCall(widget.examId ?? "");
  }

  Future<void> compareWithRank1() async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.compareWithRank1(widget.examId ?? "");
  }

  Future<void> getReportByTopicNameList() async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store
        .onReportByTopicNameApiCall(
            widget.userexamId ?? "", widget.reports!.myMark.toString())
        .whenComplete(() {
      setState(() {
        topicNames = store.reportbytopicname;
      });
    });
    await getReportByStregthList();
  }

  Future<void> getReportByStregthList() async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onReportByTopicStengthApiCall(widget.userexamId ?? "");
  }

  @override
  Widget build(BuildContext context) {
    log(widget.reports!.toJson().toString());
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);

    // -----------------------------------------------------------------
    // Preserved chart / pct computations (same values, same tryParse).
    // -----------------------------------------------------------------
    List<CircularStackEntry> data = <CircularStackEntry>[
      CircularStackEntry(
        <CircularSegmentEntry>[
          CircularSegmentEntry(
              double.tryParse(
                      widget.reports?.incorrectAnswersPercentage ?? "0") ??
                  0,
              ThemeManager.incorrectChart,
              rankKey: 'Q1'),
          CircularSegmentEntry(
              double.tryParse(
                      widget.reports?.correctAnswersPercentage ?? "0") ??
                  0,
              ThemeManager.correctChart,
              rankKey: 'Q2'),
          CircularSegmentEntry(
              double.tryParse(
                      widget.reports?.skippedAnswersPercentage ?? "0") ??
                  0,
              ThemeManager.skipChart,
              rankKey: 'Q3'),
        ],
        rankKey: 'Quarterly Profits',
      ),
    ];
    List<CircularStackEntry> data2 = isCompar
        ? <CircularStackEntry>[
            CircularStackEntry(
              <CircularSegmentEntry>[
                CircularSegmentEntry(
                    double.tryParse(store
                                .examReport.value?.incorrectAnswersPercentage
                                .toString() ??
                            "0") ??
                        0,
                    ThemeManager.incorrectChart,
                    rankKey: 'Q1'),
                CircularSegmentEntry(
                    double.tryParse(store
                                .examReport.value?.correctAnswersPercentage
                                .toString() ??
                            "0") ??
                        0,
                    ThemeManager.correctChart,
                    rankKey: 'Q2'),
                CircularSegmentEntry(
                    double.tryParse(store
                                .examReport.value?.skippedAnswersPercentage
                                .toString() ??
                            "0") ??
                        0,
                    ThemeManager.skipChart,
                    rankKey: 'Q3'),
              ],
              rankKey: 'Quarterly Profits',
            ),
          ]
        : <CircularStackEntry>[];

    double percentageValue =
        double.tryParse(widget.reports?.percentage ?? "") ?? 0;
    String percentage =
        (percentageValue >= 0) ? percentageValue.toString() : "0";
    String myMarks = (widget.reports?.myMark ?? 0) >= 0
        ? widget.reports?.myMark.toString() ?? ""
        : "0";
    String originalDate = widget.reports?.date ?? "";
    DateTime parsedDate = DateTime.parse(originalDate);
    final formatter = DateFormat('dd MMM, yyyy');
    String formattedDate = formatter.format(parsedDate);
    List<CircularStackEntry> datax = <CircularStackEntry>[
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
    List<CircularStackEntry> dataxCompare = !isCompar
        ? []
        : <CircularStackEntry>[
            CircularStackEntry(
              <CircularSegmentEntry>[
                CircularSegmentEntry(
                    store.examReport.value?.correctGuessCount!.toDouble() ?? 0,
                    ThemeManager.greenSuccess,
                    rankKey: 'Q1'),
                CircularSegmentEntry(
                    store.examReport.value?.wrongGuessCount!.toDouble() ?? 0,
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
    List<_ChartData> topicData = [
      _ChartData('Correct', correctAnswers?.toDouble() ?? 0),
      _ChartData('Skipped', skippedAnswers?.toDouble() ?? 0),
      _ChartData('Incorrect', incorrectAnswers?.toDouble() ?? 0),
    ];
    List<_ChartData> topicDataCompare = [
      _ChartData('Correct', correctAnswersCompare?.toDouble() ?? 0),
      _ChartData('Skipped', skippedAnswersCompare?.toDouble() ?? 0),
      _ChartData('Incorrect', incorrectAnswersCompare?.toDouble() ?? 0),
    ];

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamed(Routes.masterReportsCategoryList);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        body: Observer(
          builder: (BuildContext context) {
            List<MeritListModel?> meritList = store.meritMasterList;
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
                // ----------------------------------------------------
                // Brand gradient header
                // ----------------------------------------------------
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
                        onTap: () => Navigator.pop(context),
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
                              "Detailed Analytics",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTokens.titleMd(context)
                                  .copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isTrend) ...[
                        _HeaderChip(
                          label: "Series Analysis",
                          onTap: () {
                            Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => GetTrendAnalysisList(
                                    id: widget.categoryId,
                                  ),
                                ));
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                // ----------------------------------------------------
                // Body sheet
                // ----------------------------------------------------
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
                          if (widget.reports!.isDeclaration ?? false) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: _CompareBtn(
                                active: isCompar,
                                onTap: () {
                                  setState(() {
                                    isCompar = !isCompar;
                                  });
                                  if (isCompar) {
                                    compareWithRank1();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: AppTokens.s12),
                          ],
                          if (widget.showPredictive) ...[
                            _ReportSection(
                              icon: Icons.trending_up_rounded,
                              title: "Predictive NEET SS Ranking",
                              subtitle: null,
                              children: [
                                if (store.predictive.value != null)
                                  PredictedRankWidget(
                                    store: store.predictive.value!,
                                  ),
                                if (isCompar) ...[
                                  const RankCompare(),
                                  if (store.rankPredictive.value != null)
                                    PredictedRankWidget(
                                      store: store.rankPredictive.value!,
                                    )
                                ]
                              ],
                            ),
                            const SizedBox(height: AppTokens.s12),
                          ],

                          // -----------------------------------------
                          // Your Marks
                          // -----------------------------------------
                          _ReportSection(
                            icon: Icons.emoji_events_rounded,
                            title: "Your Marks",
                            subtitle:
                                "Attempt ${widget.reports?.isAttemptcount.toString() ?? ""}  ·  $formattedDate",
                            children: [
                              _HeroStatRow(
                                myMarks: myMarks,
                                mark: widget.reports?.mark.toString() ?? "",
                                percentage: percentage,
                              ),
                              const SizedBox(height: AppTokens.s12),
                              _StatGrid4(
                                cards: [
                                  _StatCardData(
                                      label: "Correct Questions",
                                      value: widget.reports?.correctAnswers
                                              .toString() ??
                                          "",
                                      tone: _StatTone.success),
                                  _StatCardData(
                                      label: "Skipped Questions",
                                      value: widget.reports?.skippedAnswers ==
                                              null
                                          ? "0"
                                          : widget.reports?.skippedAnswers
                                                  .toString() ??
                                              "",
                                      tone: _StatTone.warning),
                                  _StatCardData(
                                      label: "Incorrect Questions",
                                      value: widget.reports?.incorrectAnswers
                                              .toString() ??
                                          "",
                                      tone: _StatTone.danger),
                                  _StatCardData(
                                      label: "Total Questions",
                                      value: widget.reports?.question
                                              .toString() ??
                                          "",
                                      tone: _StatTone.accent),
                                ],
                              ),
                              if (isCompar) ...[
                                const RankCompare(),
                                _HeroStatRow(
                                  myMarks: store.examReport.value?.mymark
                                          .toString() ??
                                      "",
                                  mark:
                                      widget.reports?.mark.toString() ?? "",
                                  percentage: store.examReport.value?.percentage
                                          .toString() ??
                                      "",
                                ),
                                const SizedBox(height: AppTokens.s12),
                                _StatGrid4(
                                  cards: [
                                    _StatCardData(
                                        label: "Correct Questions",
                                        value: store
                                                .examReport.value?.correctAnswers
                                                .toString() ??
                                            "",
                                        tone: _StatTone.success),
                                    _StatCardData(
                                        label: "Skipped Questions",
                                        value: store
                                                .examReport.value?.skippedAnswers
                                                .toString() ??
                                            "0",
                                        tone: _StatTone.warning),
                                    _StatCardData(
                                        label: "Incorrect Questions",
                                        value: store.examReport.value
                                                ?.incorrectAnswers
                                                .toString() ??
                                            "",
                                        tone: _StatTone.danger),
                                    _StatCardData(
                                        label: "Total Questions",
                                        value: store
                                                .examReport.value?.question
                                                .toString() ??
                                            "",
                                        tone: _StatTone.accent),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppTokens.s12),

                          // -----------------------------------------
                          // Topicwise Insights
                          // -----------------------------------------
                          _ReportSection(
                            icon: Icons.topic_rounded,
                            title: "Topicwise Insights",
                            subtitle: null,
                            children: [
                              Text(
                                "Choose Topic",
                                style: AppTokens.caption(context).copyWith(
                                    color: AppTokens.ink(context),
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: AppTokens.s8),
                              Observer(builder: (context) {
                                if (store.reportbytopicname.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return DropdownButtonFormField<String>(
                                  key: _topicNameKey,
                                  dropdownColor: AppTokens.surface(context),
                                  value: selectedValue.isNotEmpty
                                      ? selectedValue
                                      : null,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      setState(() {
                                        _isTopicNameValid = false;
                                      });
                                      return 'Please choose one.';
                                    }
                                    setState(() {
                                      _isTopicNameValid = true;
                                    });
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppTokens.surface2(context),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppTokens.r12),
                                      borderSide: BorderSide(
                                          color: AppTokens.border(context)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppTokens.r12),
                                      borderSide: BorderSide(
                                          color: AppTokens.accent(context),
                                          width: 1.2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppTokens.r12),
                                      borderSide: BorderSide(
                                          color: AppTokens.danger(context)),
                                    ),
                                    hintText: 'Choose Topic Name',
                                    hintStyle: AppTokens.body(context)
                                        .copyWith(
                                            color: AppTokens.muted(context)),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                  ),
                                  items: dropdownItems,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedValue = value ?? '';
                                      final selectedItem =
                                          store.reportbytopicname.firstWhere(
                                        (item) =>
                                            item?.topicName == selectedValue,
                                      );
                                      topicName = selectedItem?.topicName;
                                      correctAnswers =
                                          selectedItem?.correctAnswers;
                                      incorrectAnswers =
                                          selectedItem?.incorrectAnswers;
                                      skippedAnswers =
                                          selectedItem!.skippedAnswers ?? 0;
                                      totalQuestions =
                                          selectedItem.totalQuestions;
                                      topicTime =
                                          selectedItem.totalTime ?? "00:00";
                                      totalAnswers =
                                          (selectedItem.correctAnswers ?? 0) +
                                              (selectedItem.incorrectAnswers ??
                                                  0) +
                                              (selectedItem.skippedAnswers ??
                                                  0);
                                      if (isCompar) {
                                        final selectedItem = store
                                            .examReport
                                            .value!
                                            .topicNameReport!
                                            .firstWhere(
                                          (item) =>
                                              item.topicName == selectedValue,
                                        );
                                        topicNameCompare =
                                            selectedItem.topicName;
                                        correctAnswersCompare =
                                            selectedItem.correctAnswers;
                                        incorrectAnswersCompare =
                                            selectedItem.incorrectAnswers;
                                        skippedAnswersCompare =
                                            selectedItem.skippedAnswers ?? 0;
                                        totalQuestionsCompare =
                                            selectedItem.totalQuestions;
                                        topicTimeCompare =
                                            selectedItem.totalTime ?? "00:00";
                                        totalAnswersCompare = (selectedItem
                                                    .correctAnswers ??
                                                0) +
                                            (selectedItem.incorrectAnswers ??
                                                0) +
                                            (selectedItem.skippedAnswers ?? 0);
                                      }
                                    });
                                  },
                                  isExpanded: true,
                                  icon: Icon(Icons.keyboard_arrow_down,
                                      color: AppTokens.ink2(context)),
                                  iconSize: 24,
                                  elevation: 16,
                                  style: AppTokens.body(context),
                                );
                              }),
                              const SizedBox(height: AppTokens.s16),
                              if (selectedValue.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppTokens.s16),
                                  child: Text(
                                    "Pick a topic to see its breakdown.",
                                    textAlign: TextAlign.center,
                                    style: AppTokens.caption(context).copyWith(
                                        color: AppTokens.muted(context)),
                                  ),
                                )
                              else ...[
                                _TopicCenterTotal(
                                  total: totalQuestions?.toString() ?? "0",
                                ),
                                const SizedBox(height: AppTokens.s12),
                                _StatGrid4(
                                  cards: [
                                    _StatCardData(
                                        label: "Correct",
                                        value:
                                            correctAnswers?.toString() ?? "0",
                                        tone: _StatTone.success),
                                    _StatCardData(
                                        label: "Skipped",
                                        value:
                                            skippedAnswers?.toString() ?? "0",
                                        tone: _StatTone.warning),
                                    _StatCardData(
                                        label: "Incorrect",
                                        value:
                                            incorrectAnswers?.toString() ?? "0",
                                        tone: _StatTone.danger),
                                    _StatCardData(
                                        label: "Total Questions",
                                        value:
                                            totalAnswers?.toString() ?? "0",
                                        tone: _StatTone.accent),
                                  ],
                                ),
                                if (isCompar) ...[
                                  const SizedBox(height: AppTokens.s12),
                                  const RankCompare(),
                                  _TopicCenterTotal(
                                    total:
                                        totalQuestionsCompare?.toString() ?? "0",
                                  ),
                                  const SizedBox(height: AppTokens.s12),
                                  _StatGrid4(
                                    cards: [
                                      _StatCardData(
                                          label: "Correct",
                                          value: correctAnswersCompare
                                                  ?.toString() ??
                                              "0",
                                          tone: _StatTone.success),
                                      _StatCardData(
                                          label: "Skipped",
                                          value: skippedAnswersCompare
                                                  ?.toString() ??
                                              "0",
                                          tone: _StatTone.warning),
                                      _StatCardData(
                                          label: "Incorrect",
                                          value: incorrectAnswersCompare
                                                  ?.toString() ??
                                              "0",
                                          tone: _StatTone.danger),
                                      _StatCardData(
                                          label: "Total Questions",
                                          value: totalAnswersCompare
                                                  ?.toString() ??
                                              "0",
                                          tone: _StatTone.accent),
                                    ],
                                  ),
                                ],
                              ]
                            ],
                          ),
                          const SizedBox(height: AppTokens.s12),

                          // -----------------------------------------
                          // EduMetrics (chart + legend + accuracy + time)
                          // -----------------------------------------
                          _ReportSection(
                            icon: Icons.analytics_rounded,
                            title: "EduMetrics",
                            subtitle: null,
                            children: [
                              Stack(
                                alignment: AlignmentDirectional.center,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Total Questions",
                                        style: AppTokens.caption(context)
                                            .copyWith(
                                                color: AppTokens.ink2(context)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.reports?.question.toString() ??
                                            "",
                                        style: AppTokens.displayMd(context),
                                      ),
                                    ],
                                  ),
                                  AnimatedCircularChart(
                                    key: _chartKey,
                                    size: const Size(500.0, 300),
                                    initialChartData: data,
                                    holeRadius: 40,
                                    chartType: CircularChartType.Radial,
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppTokens.s8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _LegendDot(
                                        color: AppTokens.success(context),
                                        label:
                                            "Correct ($correctAnsPercentage%)"),
                                    _LegendDot(
                                        color: AppTokens.danger(context),
                                        label:
                                            "Incorrect ($incorrectAnsPercentage%)"),
                                    _LegendDot(
                                        color: AppTokens.warning(context),
                                        label:
                                            "Skipped ($skippedAnsPercentage%)"),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppTokens.s16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricBox(
                                      label: "Accuracy",
                                      value: "$accuracyPercentage%",
                                      tone: _StatTone.accent,
                                      icon: Icons.track_changes_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: AppTokens.s8),
                                  Expanded(
                                    child: _MetricBox(
                                      label: "Time Taken",
                                      value: formatTimeString(
                                          widget.reports?.Time ?? ""),
                                      tone: _StatTone.warning,
                                      icon: Icons.timer_outlined,
                                    ),
                                  ),
                                ],
                              ),
                              if (isCompar) ...[
                                const SizedBox(height: AppTokens.s16),
                                const RankCompare(),
                                const SizedBox(height: AppTokens.s12),
                                AnimatedCircularChart(
                                  key: _chartKey2,
                                  size: const Size(500.0, 300),
                                  initialChartData: data2,
                                  holeRadius: 40,
                                  chartType: CircularChartType.Radial,
                                ),
                                const SizedBox(height: AppTokens.s16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _MetricBox(
                                        label: "Accuracy",
                                        value:
                                            "${store.examReport.value?.accuracyPercentage ?? ""}%",
                                        tone: _StatTone.accent,
                                        icon: Icons.track_changes_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: AppTokens.s8),
                                    Expanded(
                                      child: _MetricBox(
                                        label: "Time Taken",
                                        value: formatTimeString(store
                                                .examReport.value?.time ??
                                            ""),
                                        tone: _StatTone.warning,
                                        icon: Icons.timer_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppTokens.s12),

                          // -----------------------------------------
                          // Guess Analytics
                          // -----------------------------------------
                          _ReportSection(
                            icon: Icons.help_outline_rounded,
                            title: "Guess Analytics",
                            subtitle: null,
                            children: [
                              if (widget.reports?.wrongGuessCount == 0 &&
                                  widget.reports?.correctGuessCount == 0)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppTokens.s24),
                                  child: Center(
                                    child: Text(
                                      "No Answer is Guessed",
                                      style: AppTokens.body(context).copyWith(
                                          color: AppTokens.muted(context)),
                                    ),
                                  ),
                                )
                              else ...[
                                Stack(
                                  alignment: AlignmentDirectional.center,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Guessed Answers",
                                          style: AppTokens.caption(context)
                                              .copyWith(
                                                  color: AppTokens.ink2(
                                                      context)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.reports?.guessedAnswersCount
                                                  .toString() ??
                                              "",
                                          style: AppTokens.displayMd(context),
                                        ),
                                      ],
                                    ),
                                    AnimatedCircularChart(
                                      key: _guessedchartKey,
                                      size: const Size(500.0, 300),
                                      initialChartData: datax,
                                      holeRadius: 30,
                                      chartType: CircularChartType.Radial,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTokens.s12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _MetricBox(
                                        label: "Correct Answer",
                                        value:
                                            "${widget.reports?.correctGuessCount ?? 0}",
                                        tone: _StatTone.success,
                                        icon: Icons.check_circle_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: AppTokens.s8),
                                    Expanded(
                                      child: _MetricBox(
                                        label: "Incorrect Answer",
                                        value:
                                            "${widget.reports?.wrongGuessCount ?? 0}",
                                        tone: _StatTone.danger,
                                        icon: Icons.cancel_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (isCompar) ...[
                                const SizedBox(height: AppTokens.s12),
                                const RankCompare(),
                                if (store.examReport.value?.wrongGuessCount ==
                                        0 &&
                                    store.examReport.value?.correctGuessCount ==
                                        0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: AppTokens.s24),
                                    child: Center(
                                      child: Text(
                                        "No Answer is Guessed",
                                        style: AppTokens.body(context).copyWith(
                                            color: AppTokens.muted(context)),
                                      ),
                                    ),
                                  )
                                else ...[
                                  Stack(
                                    alignment: AlignmentDirectional.center,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "Guessed Answers",
                                            style: AppTokens.caption(context)
                                                .copyWith(
                                                    color: AppTokens.ink2(
                                                        context)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            store.examReport.value
                                                    ?.guessedAnswersCount
                                                    .toString() ??
                                                "",
                                            style:
                                                AppTokens.displayMd(context),
                                          ),
                                        ],
                                      ),
                                      AnimatedCircularChart(
                                        key: _guessedchartKey2,
                                        size: const Size(500.0, 300),
                                        initialChartData: dataxCompare,
                                        holeRadius: 30,
                                        chartType: CircularChartType.Radial,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTokens.s12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _MetricBox(
                                          label: "Correct Answer",
                                          value:
                                              "${store.examReport.value?.correctGuessCount ?? 0}",
                                          tone: _StatTone.success,
                                          icon: Icons.check_circle_rounded,
                                        ),
                                      ),
                                      const SizedBox(width: AppTokens.s8),
                                      Expanded(
                                        child: _MetricBox(
                                          label: "Incorrect Answer",
                                          value:
                                              "${store.examReport.value?.wrongGuessCount ?? 0}",
                                          tone: _StatTone.danger,
                                          icon: Icons.cancel_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ],
                          ),
                          const SizedBox(height: AppTokens.s12),

                          // -----------------------------------------
                          // Answer Evolve
                          // -----------------------------------------
                          _ReportSection(
                            icon: Icons.swap_horiz_rounded,
                            title: "Answer Evolve",
                            subtitle: null,
                            children: [
                              _EvolveRow(
                                label: "Correct to Incorrect",
                                value:
                                    "${widget.reports?.correct_incorrect ?? 0}",
                                gradient: [
                                  AppTokens.success(context),
                                  AppTokens.danger(context),
                                ],
                              ),
                              const SizedBox(height: AppTokens.s8),
                              _EvolveRow(
                                label: "Incorrect to Correct",
                                value:
                                    "${widget.reports?.incorrect_correct ?? 0}",
                                gradient: [
                                  AppTokens.danger(context),
                                  AppTokens.success(context),
                                ],
                              ),
                              const SizedBox(height: AppTokens.s8),
                              _EvolveRow(
                                label: "Incorrect to Incorrect",
                                value:
                                    "${widget.reports?.incorrect_incorres ?? 0}",
                                gradient: [
                                  AppTokens.danger(context),
                                  AppTokens.danger(context),
                                ],
                              ),
                              if (isCompar) ...[
                                const SizedBox(height: AppTokens.s12),
                                const RankCompare(),
                                _EvolveRow(
                                  label: "Correct to Incorrect",
                                  value:
                                      "${store.examReport.value?.correct_incorrect ?? 0}",
                                  gradient: [
                                    AppTokens.success(context),
                                    AppTokens.danger(context),
                                  ],
                                ),
                                const SizedBox(height: AppTokens.s8),
                                _EvolveRow(
                                  label: "Incorrect to Correct",
                                  value:
                                      "${store.examReport.value?.incorrect_correct ?? 0}",
                                  gradient: [
                                    AppTokens.danger(context),
                                    AppTokens.success(context),
                                  ],
                                ),
                                const SizedBox(height: AppTokens.s8),
                                _EvolveRow(
                                  label: "Incorrect to Incorrect",
                                  value:
                                      "${store.examReport.value?.incorrect_incorres ?? 0}",
                                  gradient: [
                                    AppTokens.danger(context),
                                    AppTokens.danger(context),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppTokens.s12),

                          // -----------------------------------------
                          // Strength Spotlight
                          // -----------------------------------------
                          _ReportSection(
                            icon: Icons.bolt_rounded,
                            title: "Strength Spotlight",
                            subtitle: null,
                            children: [
                              Observer(builder: (context) {
                                if (store.reportbytopicstreght.isEmpty) {
                                  return _EmptyHint(
                                    text:
                                        "We're sorry, there's no content available right now. Please check back later or explore other sections for more educational resources.",
                                  );
                                }
                                return Column(
                                  children: List.generate(
                                      store.reportbytopicstreght.length,
                                      (index) {
                                    final item =
                                        store.reportbytopicstreght[index];
                                    final List<TopThreeCorrect?> topics =
                                        item?.topThreeCorrect ?? [];
                                    return Wrap(
                                      spacing: AppTokens.s8,
                                      runSpacing: AppTokens.s8,
                                      children: List.generate(topics.length,
                                          (topicIndex) {
                                        final t = topics[topicIndex];
                                        return _TopicPill(
                                          label: t?.topicName ?? "",
                                          tone: _PillTone.success,
                                          onTap: () {
                                            Navigator.push(
                                                context,
                                                CupertinoPageRoute(
                                                    builder: (context) =>
                                                        StrengthWeaknessGraph(
                                                          topThreeCorrect: store
                                                              .reportbytopicstreght[
                                                                  index]!
                                                              .topThreeCorrect![
                                                                  topicIndex],
                                                        )));
                                          },
                                        );
                                      }),
                                    );
                                  }),
                                );
                              }),
                              if (isCompar) ...[
                                const RankCompare(),
                                const SizedBox(height: AppTokens.s8),
                                Observer(builder: (context) {
                                  if ((store.examReport.value?.topThreeCorrect
                                              ?.isEmpty ??
                                          true)) {
                                    return _EmptyHint(
                                      text:
                                          "We're sorry, there's no content available right now. Please check back later or explore other sections for more educational resources.",
                                    );
                                  }
                                  final topics = store
                                          .examReport.value?.topThreeCorrect ??
                                      [];
                                  return Wrap(
                                    spacing: AppTokens.s8,
                                    runSpacing: AppTokens.s8,
                                    children: List.generate(topics.length,
                                        (topicIndex) {
                                      final t = topics[topicIndex];
                                      return _TopicPill(
                                        label: t.topicName ?? "",
                                        tone: _PillTone.success,
                                        onTap: () {
                                          final data = TopThreeCorrect(
                                            correctAnswers: t.correctAnswers,
                                          );
                                          Navigator.push(
                                              context,
                                              CupertinoPageRoute(
                                                  builder: (context) =>
                                                      StrengthWeaknessGraph(
                                                          topThreeCorrect:
                                                              data)));
                                        },
                                      );
                                    }),
                                  );
                                }),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppTokens.s12),

                          // -----------------------------------------
                          // Weakness Spotlight
                          // -----------------------------------------
                          _ReportSection(
                            icon: Icons.warning_amber_rounded,
                            title: "Weakness Spotlight",
                            subtitle: null,
                            children: [
                              Observer(builder: (context) {
                                if (store.reportbytopicstreght.isEmpty) {
                                  return _EmptyHint(
                                    text:
                                        "We're sorry, there's no content available right now. Please check back later or explore other sections for more educational resources.",
                                  );
                                }
                                return Column(
                                  children: List.generate(
                                      store.reportbytopicstreght.length,
                                      (index) {
                                    final item =
                                        store.reportbytopicstreght[index];
                                    final List<LastThreeIncorrect?> topics =
                                        item?.lastThreeIncorrect ?? [];
                                    return Wrap(
                                      spacing: AppTokens.s8,
                                      runSpacing: AppTokens.s8,
                                      children: List.generate(topics.length,
                                          (topicIndex) {
                                        final t = topics[topicIndex];
                                        return _TopicPill(
                                          label: t?.topicName ?? "",
                                          tone: _PillTone.danger,
                                          onTap: () {
                                            Navigator.push(
                                                context,
                                                CupertinoPageRoute(
                                                    builder: (context) =>
                                                        StrengthWeaknessGraph(
                                                          lastThreeIncorrect: store
                                                              .reportbytopicstreght[
                                                                  index]!
                                                              .lastThreeIncorrect![
                                                                  topicIndex],
                                                        )));
                                          },
                                        );
                                      }),
                                    );
                                  }),
                                );
                              }),
                              if (isCompar) ...[
                                const RankCompare(),
                                const SizedBox(height: AppTokens.s8),
                                Observer(builder: (context) {
                                  if ((store.examReport.value?.lastThreeIncorrect
                                              ?.isEmpty ??
                                          true)) {
                                    return _EmptyHint(
                                      text:
                                          "We're sorry, there's no content available right now. Please check back later or explore other sections for more educational resources.",
                                    );
                                  }
                                  final topics = store.examReport.value
                                          ?.lastThreeIncorrect ??
                                      [];
                                  return Wrap(
                                    spacing: AppTokens.s8,
                                    runSpacing: AppTokens.s8,
                                    children: List.generate(topics.length,
                                        (topicIndex) {
                                      final t = topics[topicIndex];
                                      return _TopicPill(
                                        label: t.topicName ?? "",
                                        tone: _PillTone.danger,
                                        onTap: () {
                                          final data = LastThreeIncorrect(
                                            correctAnswers: t.correctAnswers,
                                          );
                                          Navigator.push(
                                              context,
                                              CupertinoPageRoute(
                                                  builder: (context) =>
                                                      StrengthWeaknessGraph(
                                                          lastThreeIncorrect:
                                                              data)));
                                        },
                                      );
                                    }),
                                  );
                                }),
                              ],
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

// ============================================================
//                        Primitives
// ============================================================

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

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.brand,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompareBtn extends StatelessWidget {
  const _CompareBtn({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: active
                ? null
                : const LinearGradient(
                    colors: [AppTokens.brand, AppTokens.brand2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: active ? AppTokens.dangerSoft(context) : null,
            borderRadius: BorderRadius.circular(999),
            border: active
                ? Border.all(color: AppTokens.danger(context))
                : null,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              active ? "Reset" : "Compare with Rank 1",
              style: AppTokens.caption(context).copyWith(
                color:
                    active ? AppTokens.danger(context) : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          borderRadius: AppTokens.radius16,
          border: Border.all(color: AppTokens.border(context)),
          boxShadow: AppTokens.shadow1(context),
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s12, vertical: AppTokens.s4),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppTokens.s12,
            0,
            AppTokens.s12,
            AppTokens.s16,
          ),
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          iconColor: AppTokens.ink2(context),
          collapsedIconColor: AppTokens.ink2(context),
          title: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                ),
                child:
                    Icon(icon, color: AppTokens.accent(context), size: 20),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTokens.titleSm(context),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTokens.caption(context)
                            .copyWith(color: AppTokens.ink2(context)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          children: children,
        ),
      ),
    );
  }
}

class _HeroStatRow extends StatelessWidget {
  const _HeroStatRow({
    required this.myMarks,
    required this.mark,
    required this.percentage,
  });

  final String myMarks;
  final String mark;
  final String percentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("My Marks",
                    style: AppTokens.caption(context)
                        .copyWith(color: AppTokens.ink2(context))),
                const SizedBox(height: 2),
                Text(
                  "$myMarks/$mark",
                  style: AppTokens.titleLg(context),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: AppTokens.border(context),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: AppTokens.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("My Percentage",
                      style: AppTokens.caption(context)
                          .copyWith(color: AppTokens.ink2(context))),
                  const SizedBox(height: 2),
                  Text(
                    "$percentage%",
                    style: AppTokens.titleLg(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _StatTone { success, warning, danger, accent }

class _StatCardData {
  const _StatCardData(
      {required this.label, required this.value, required this.tone});
  final String label;
  final String value;
  final _StatTone tone;
}

class _StatGrid4 extends StatelessWidget {
  const _StatGrid4({required this.cards});
  final List<_StatCardData> cards;

  @override
  Widget build(BuildContext context) {
    Widget card(_StatCardData c) => _StatCardTile(data: c);
    return Column(
      children: [
        Row(children: [
          Expanded(child: card(cards[0])),
          const SizedBox(width: AppTokens.s8),
          Expanded(child: card(cards[1])),
        ]),
        const SizedBox(height: AppTokens.s8),
        Row(children: [
          Expanded(child: card(cards[2])),
          const SizedBox(width: AppTokens.s8),
          Expanded(child: card(cards[3])),
        ]),
      ],
    );
  }
}

class _StatCardTile extends StatelessWidget {
  const _StatCardTile({required this.data});
  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    Color bg() {
      switch (data.tone) {
        case _StatTone.success:
          return AppTokens.successSoft(context);
        case _StatTone.warning:
          return AppTokens.warningSoft(context);
        case _StatTone.danger:
          return AppTokens.dangerSoft(context);
        case _StatTone.accent:
          return AppTokens.accentSoft(context);
      }
    }

    Color fg() {
      switch (data.tone) {
        case _StatTone.success:
          return AppTokens.success(context);
        case _StatTone.warning:
          return AppTokens.warning(context);
        case _StatTone.danger:
          return AppTokens.danger(context);
        case _StatTone.accent:
          return AppTokens.accent(context);
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: AppTokens.caption(context)
                      .copyWith(color: AppTokens.ink2(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: AppTokens.titleMd(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg(),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.circle, color: fg(), size: 10),
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.label,
    required this.value,
    required this.tone,
    required this.icon,
  });

  final String label;
  final String value;
  final _StatTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    Color bg() {
      switch (tone) {
        case _StatTone.success:
          return AppTokens.successSoft(context);
        case _StatTone.warning:
          return AppTokens.warningSoft(context);
        case _StatTone.danger:
          return AppTokens.dangerSoft(context);
        case _StatTone.accent:
          return AppTokens.accentSoft(context);
      }
    }

    Color fg() {
      switch (tone) {
        case _StatTone.success:
          return AppTokens.success(context);
        case _StatTone.warning:
          return AppTokens.warning(context);
        case _StatTone.danger:
          return AppTokens.danger(context);
        case _StatTone.accent:
          return AppTokens.accent(context);
      }
    }

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
            height: 36,
            width: 36,
            alignment: Alignment.center,
            decoration:
                BoxDecoration(color: bg(), shape: BoxShape.circle),
            child: Icon(icon, color: fg(), size: 18),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTokens.caption(context)
                      .copyWith(color: AppTokens.ink2(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTokens.titleSm(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicCenterTotal extends StatelessWidget {
  const _TopicCenterTotal({required this.total});
  final String total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Total Questions",
          style: AppTokens.caption(context)
              .copyWith(color: AppTokens.ink2(context)),
        ),
        const SizedBox(height: 2),
        Text(
          total,
          style: AppTokens.displayMd(context),
        ),
      ],
    );
  }
}

class _EvolveRow extends StatelessWidget {
  const _EvolveRow({
    required this.label,
    required this.value,
    required this.gradient,
  });

  final String label;
  final String value;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        border: GradientBoxBorder(
          gradient: LinearGradient(colors: gradient),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTokens.caption(context)
                      .copyWith(color: AppTokens.ink2(context)),
                ),
                const SizedBox(height: 2),
                Text(value, style: AppTokens.titleMd(context)),
              ],
            ),
          ),
          Container(
            height: 32,
            width: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.swap_vert_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

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
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTokens.caption(context)
              .copyWith(color: AppTokens.ink2(context)),
        ),
      ],
    );
  }
}

enum _PillTone { success, danger }

class _TopicPill extends StatelessWidget {
  const _TopicPill({
    required this.label,
    required this.tone,
    required this.onTap,
  });

  final String label;
  final _PillTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = tone == _PillTone.success
        ? AppTokens.success(context)
        : AppTokens.danger(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s16, vertical: AppTokens.s8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTokens.caption(context)
            .copyWith(color: AppTokens.muted(context)),
      ),
    );
  }
}

// ============================================================
//           Preserved file-scope helpers & classes
// ============================================================

class _ChartData {
  _ChartData(this.x, this.y);

  final String x;
  final double y;
}

Widget _buildPredictedRankRow(String year, String rankRange) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          year == "2024"
              ? "Prediction - NEET SS '${year.substring(2)}"
              : "As Per NEET SS '${year.substring(2)}",
          style: TextStyle(
            fontSize: Dimensions.fontSizeDefault,
            fontWeight: FontWeight.w600,
            color: ThemeManager.black,
          ),
        ),
        Text(
          rankRange,
          style: TextStyle(
            fontSize: Dimensions.fontSizeDefaultLarge,
            fontWeight: FontWeight.bold,
            color: ThemeManager.primaryColor,
          ),
        ),
      ],
    ),
  );
}

Widget _buildCustomDivider() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Divider(
      thickness: 1.5,
      color: ThemeManager.grey.withOpacity(0.6),
    ),
  );
}

String formatTimeString(String timeString) {
  if (timeString.isEmpty || !timeString.contains(":")) {
    return "-";
  }

  List<String> parts = timeString.split(":");

  if (parts.length != 3) {
    return "-";
  }

  try {
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    int seconds = int.parse(parts[2]);

    if (hours < 0 || minutes < 0 || seconds < 0) {
      return "-";
    }

    int totalSeconds = (hours * 3600) + (minutes * 60) + seconds;
    int mins = totalSeconds ~/ 60;
    int secs = totalSeconds % 60;

    if (mins > 0) {
      return "$mins mins $secs secs";
    } else {
      return "$secs secs";
    }
  } catch (e) {
    return "Error parsing time";
  }
}

class PredictedRankWidget extends StatelessWidget {
  final Map<String, dynamic> store;

  const PredictedRankWidget({super.key, required this.store});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPredictedRankRow(
            "2023",
            store['predicted_rank_2022'] ?? 'loading..',
          ),
          const Divider(),
          _buildPredictedRankRow(
            "2024",
            store['predicted_rank_2023'] ?? 'loading..',
          ),
          const Divider(),
          _buildPredictedRankRow(
            "2025",
            store['predicted_rank_2024'] ?? 'loading..',
          ),
          const Divider(),
          const Text(
            "Disclaimer: The NEET SS Surgical Group Rank Predictor offers an estimated rank based on past data, with a possible variation of \u00b1100-200 ranks. It is intended for guidance and may not represent the exact final rank.",
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class RankCompare extends StatelessWidget {
  const RankCompare({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Divider(
          color: ThemeManager.black,
        ),
        Text(
          "Rank 1",
          style: interBold.copyWith(
            fontSize: Dimensions.PADDING_SIZE_LARGE,
            color: ThemeManager.blueFinal,
          ),
        ),
        Divider(
          color: ThemeManager.black,
        ),
      ],
    );
  }
}
