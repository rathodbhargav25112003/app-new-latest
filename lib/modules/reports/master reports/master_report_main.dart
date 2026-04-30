// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, non_constant_identifier_names, avoid_print, use_build_context_synchronously, unused_field

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/forked_packages/circular_chart_flutter/lib/circular_chart_flutter.dart';
import 'package:shusruta_lms/models/get_report_by_topic_name_model.dart';
import 'package:shusruta_lms/models/merit_list_model.dart';
import 'package:shusruta_lms/models/report_by_category_model.dart';
import 'package:shusruta_lms/models/strength_model.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';

/// Mock exam analysis & solutions.
///
/// Preserved public contract:
///   • `MasterReportMainScreen({super.key, this.reports, required this.title,
///     this.examId})`
///   • Static `route(RouteSettings)` reads `{report, title, examId}`.
///   • `initState` → `getMeritList()`, `getReportByTopicNameList()`,
///     `getReportByStregthList()`.
///   • `getMeritList()` → `store.onMasterMeritListApiCall(widget.examId ?? "")`.
///   • `getReportByTopicNameList()` →
///     `store.onReportByTopicNameApiCall(widget.reports?.userExamId ?? "","0")`
///     and `setState(() { topicNames = store.reportbytopicname; })`.
///   • `getReportByStregthList()` →
///     `store.onReportByTopicStengthApiCall(widget.reports?.userExamId ?? "")`.
///   • `_solutionReport(examId, filterVal)` →
///     `store.onMasterSolutionReportApiCall(examId)` → pushes
///     `Routes.solutionMasterReport` with
///     `{'solutionReport': store.masterSolutionReportCategory,
///     'filterVal': filterVal, 'userExamId': examId}`.
///   • Solutions filters: "View all" / "Correct" / "View incorrect answer".
///   • `roundAndFormatDouble(String value)` helper preserved.
///   • AppBar title "Analysis & Solutions" and ExpansionTile labels:
///     "Summit Scholars (Attempt 1)", "TopicWise Insights", "EduMetrics",
///     "Guess Analytics", "Answer Evolve", "Strength Spotlight",
///     "Weakness Watch" — all preserved.
///   • Chart data shapes (incorrect/correct/skipped percentages + correct /
///     wrong guess counts) preserved verbatim.
class MasterReportMainScreen extends StatefulWidget {
  final ReportByCategoryModel? reports;
  final String title;
  final String? examId;
  const MasterReportMainScreen({
    super.key,
    this.reports,
    required this.title,
    this.examId,
  });

  @override
  State<MasterReportMainScreen> createState() => _MasterReportMainScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => MasterReportMainScreen(
        reports: arguments['report'],
        title: arguments['title'],
        examId: arguments['examId'],
      ),
    );
  }
}

class _MasterReportMainScreenState extends State<MasterReportMainScreen> {
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
  bool _isTopicNameValid = false;
  List<ReportByTopicNameModel?> topicNames = [];

  @override
  void initState() {
    super.initState();
    getMeritList();
    getReportByTopicNameList();
    getReportByStregthList();
  }

  Future<void> getMeritList() async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onMasterMeritListApiCall(widget.examId ?? "");
    debugPrint('meritname${store.meritMasterList.map((e) => e?.fullName)}');
  }

  Future<void> getReportByTopicNameList() async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onReportByTopicNameApiCall(
        widget.reports?.userExamId ?? "", "0");
    debugPrint(
        'reportbytopicname${store.reportbytopicname.map((e) => e?.topicName)}');
    debugPrint('widget.examId${widget.reports?.userExamId}');
    setState(() {
      topicNames = store.reportbytopicname;
    });
  }

  Future<void> getReportByStregthList() async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onReportByTopicStengthApiCall(widget.reports?.userExamId ?? "");
  }

  String roundAndFormatDouble(String value) {
    double doubleValue = double.tryParse(value) ?? 0.0;
    int roundedValue = doubleValue.round();
    return roundedValue.toString();
  }

  Future<void> _solutionReport(String examId, String filterVal) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onMasterSolutionReportApiCall(examId).then((_) {
      Navigator.of(context).pushNamed(Routes.solutionMasterReport, arguments: {
        'solutionReport': store.masterSolutionReportCategory,
        'filterVal': filterVal,
        'userExamId': examId
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = <CircularStackEntry>[
      CircularStackEntry(
        <CircularSegmentEntry>[
          CircularSegmentEntry(
            double.parse(widget.reports?.incorrectAnswersPercentage ?? ""),
            ThemeManager.redAlert,
            rankKey: 'Q1',
          ),
          CircularSegmentEntry(
            double.parse(widget.reports?.correctAnswersPercentage ?? ""),
            ThemeManager.greenSuccess,
            rankKey: 'Q2',
          ),
          CircularSegmentEntry(
            double.parse(widget.reports?.skippedAnswersPercentage ?? ""),
            const Color(0xFFFF9F59),
            rankKey: 'Q3',
          ),
        ],
        rankKey: 'Quarterly Profits',
      ),
    ];

    final datay = <CircularStackEntry>[
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

    final double percentageValue =
        double.tryParse(widget.reports?.percentage ?? "") ?? 0;
    final String percentage =
        (percentageValue >= 0) ? percentageValue.toString() : "0";
    final String myMarks = (widget.reports?.myMark ?? 0) >= 0
        ? widget.reports?.myMark.toString() ?? ""
        : "0";
    final String originalDate = widget.reports?.date ?? "";
    final DateTime parsedDate = DateTime.parse(originalDate);
    final String formattedDate =
        DateFormat('dd MMM, yyyy').format(parsedDate);

    final String correctAnsPercentage =
        roundAndFormatDouble(widget.reports?.correctAnswersPercentage ?? "0.0");
    final String incorrectAnsPercentage = roundAndFormatDouble(
        widget.reports?.incorrectAnswersPercentage.toString() ?? "0.0");
    final String skippedAnsPercentage = roundAndFormatDouble(
        widget.reports?.skippedAnswersPercentage.toString() ?? "0.0");
    final String accuracyPercentage = roundAndFormatDouble(
        widget.reports?.accuracyPercentage.toString() ?? "0.0");

    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    final List<DropdownMenuItem<String>> dropdownItems = topicNames.map((item) {
      final topicName = item?.topicName;
      return DropdownMenuItem<String>(
        value: topicName,
        child: Text(topicName ?? ""),
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Observer(
              builder: (BuildContext context) {
                final List<MeritListModel?> meritList = store.meritMasterList;
                final List<ReportSrengthModel?> stength =
                    store.reportbytopicstreght;

                if (store.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppTokens.accent(context),
                        ),
                        const SizedBox(height: AppTokens.s16),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.s24),
                          child: Text(
                            "Getting everything ready for you... Just a moment!",
                            style: AppTokens.body(context).copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppTokens.ink(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.s20,
                    AppTokens.s16,
                    AppTokens.s20,
                    AppTokens.s24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewCard(
                        context,
                        formattedDate: formattedDate,
                        myMarks: myMarks,
                        percentage: percentage,
                      ),
                      const SizedBox(height: AppTokens.s16),
                      if (meritList.isNotEmpty)
                        _sectionCard(
                          context,
                          title: "Summit Scholars (Attempt 1)",
                          child: _buildMeritTable(context, meritList),
                        ),
                      if (meritList.isNotEmpty)
                        const SizedBox(height: AppTokens.s12),
                      _sectionCard(
                        context,
                        title: "TopicWise Insights",
                        child: _buildTopicInsights(context, store, dropdownItems),
                      ),
                      const SizedBox(height: AppTokens.s12),
                      _sectionCard(
                        context,
                        title: "EduMetrics",
                        child: _buildEduMetrics(
                          context,
                          data: data,
                          correctAnsPercentage: correctAnsPercentage,
                          incorrectAnsPercentage: incorrectAnsPercentage,
                          skippedAnsPercentage: skippedAnsPercentage,
                          accuracyPercentage: accuracyPercentage,
                        ),
                      ),
                      const SizedBox(height: AppTokens.s12),
                      _sectionCard(
                        context,
                        title: "Guess Analytics",
                        child: _buildGuessAnalytics(context, datay),
                      ),
                      const SizedBox(height: AppTokens.s12),
                      _sectionCard(
                        context,
                        title: "Answer Evolve",
                        child: _buildAnswerEvolve(context),
                      ),
                      if (stength.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.s12),
                        _sectionCard(
                          context,
                          title: "Strength Spotlight",
                          child: _buildTopicList(
                            context,
                            store,
                            (s) => s?.topThreeCorrect
                                    ?.map((e) => e.topicName)
                                    .toList() ??
                                [],
                          ),
                        ),
                        const SizedBox(height: AppTokens.s12),
                        _sectionCard(
                          context,
                          title: "Weakness Watch",
                          child: _buildTopicList(
                            context,
                            store,
                            (s) => s?.lastThreeIncorrect
                                    ?.map((e) => e.topicName)
                                    .toList() ??
                                [],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTokens.s8,
        left: AppTokens.s8,
        right: AppTokens.s20,
        bottom: AppTokens.s16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(AppTokens.r8),
            child: Container(
              height: AppTokens.s32,
              width: AppTokens.s32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              "Analysis & Solutions",
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context, {
    required String formattedDate,
    required String myMarks,
    required String percentage,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Text(
                formattedDate,
                style: AppTokens.caption(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTokens.muted(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Row(
            children: [
              Text(
                "Attempt ${widget.reports?.isAttemptcount.toString() ?? ""}",
                style: AppTokens.caption(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTokens.ink(context),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _solutionReport(
                    widget.reports?.userExamId ?? "", "View all"),
                borderRadius: BorderRadius.circular(AppTokens.r12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s16,
                    vertical: AppTokens.s8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTokens.brand, AppTokens.brand2],
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                  ),
                  child: Text(
                    "Solutions",
                    style: AppTokens.caption(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          Row(
            children: [
              Expanded(
                child: _OverviewCell(
                  iconAsset: "assets/image/trophy_icon.svg",
                  label: "1ˢᵗ attempt rank",
                  value: "${widget.reports?.userFirstRank.toString()}",
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: _OverviewCell(
                  iconAsset: "assets/image/marks.svg",
                  label: "My marks",
                  value: "$myMarks/${widget.reports?.mark.toString()}",
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: _OverviewCell(
                  iconAsset: "assets/image/percentage_icon.svg",
                  label: "My percentage",
                  value: percentage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          collapsedIconColor: AppTokens.accent(context),
          iconColor: AppTokens.accent(context),
          tilePadding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppTokens.s16,
            0,
            AppTokens.s16,
            AppTokens.s16,
          ),
          title: Text(
            title,
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.ink(context),
            ),
          ),
          children: [child],
        ),
      ),
    );
  }

  Widget _buildMeritTable(
      BuildContext context, List<MeritListModel?> meritList) {
    final header = AppTokens.body(context).copyWith(
      fontWeight: FontWeight.w700,
      color: AppTokens.ink(context),
    );
    final cell = AppTokens.body(context).copyWith(
      fontWeight: FontWeight.w500,
      color: AppTokens.ink(context),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor:
            MaterialStateProperty.all(AppTokens.accentSoft(context)),
        columns: [
          DataColumn(label: Text("Rank", style: header)),
          DataColumn(label: Text("Name", style: header)),
          DataColumn(label: Text("Marks", style: header)),
        ],
        rows: meritList.map((student) {
          return DataRow(cells: [
            DataCell(Text(student?.rank.toString() ?? "", style: cell)),
            DataCell(Text(student?.fullName ?? "", style: cell)),
            DataCell(Text(student?.score.toString() ?? "", style: cell)),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildTopicInsights(
    BuildContext context,
    ReportsCategoryStore store,
    List<DropdownMenuItem<String>> dropdownItems,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Observer(
          builder: (_) {
            if (store.reportbytopicname.isEmpty) {
              return const SizedBox.shrink();
            }
            return DropdownButtonFormField<String>(
              key: _topicNameKey,
              dropdownColor: AppTokens.surface(context),
              value: selectedValue.isNotEmpty ? selectedValue : null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  setState(() => _isTopicNameValid = false);
                  return 'Please choose one.';
                }
                setState(() => _isTopicNameValid = true);
                return null;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTokens.surface(context),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  borderSide: BorderSide(color: AppTokens.border(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  borderSide: BorderSide(color: AppTokens.accent(context)),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                labelText: 'Choose Topic Name',
                labelStyle: AppTokens.caption(context).copyWith(
                  color: AppTokens.muted(context),
                ),
                hintText: 'Choose Topic Name',
                hintStyle: AppTokens.caption(context).copyWith(
                  color: AppTokens.muted(context),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s16,
                  vertical: AppTokens.s12,
                ),
              ),
              items: dropdownItems,
              onChanged: (value) {
                setState(() {
                  selectedValue = value ?? "";
                  final selectedItem = store.reportbytopicname.firstWhere(
                    (item) => item?.topicName == selectedValue,
                  );
                  topicName = selectedItem?.topicName;
                  correctAnswers = selectedItem?.correctAnswers;
                  incorrectAnswers = selectedItem?.incorrectAnswers;
                  skippedAnswers = selectedItem?.skippedAnswers;
                  guessedAnswers = selectedItem?.guessedAnswers;
                });
              },
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTokens.muted(context),
              ),
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink(context),
              ),
            );
          },
        ),
        const SizedBox(height: AppTokens.s16),
        Container(
          height: 180,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.surface2(context),
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
          child: Text(
            "No Topic Found",
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppTokens.accent(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEduMetrics(
    BuildContext context, {
    required List<CircularStackEntry> data,
    required String correctAnsPercentage,
    required String incorrectAnsPercentage,
    required String skippedAnsPercentage,
    required String accuracyPercentage,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                value: widget.reports?.question.toString() ?? "",
                label: "Question",
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            Expanded(
              child: _MiniStat(
                value: widget.reports?.Time.toString() ?? "",
                label: "Total Time",
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        Container(
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            color: AppTokens.surface2(context),
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AnimatedCircularChart(
                    key: _chartKey,
                    size: const Size(180.0, 180.0),
                    initialChartData: data,
                    chartType: CircularChartType.Pie,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Legend(
                        color: ThemeManager.greenSuccess,
                        label: "Correct",
                      ),
                      const SizedBox(height: AppTokens.s8),
                      _Legend(
                        color: ThemeManager.redAlert,
                        label: "Incorrect",
                      ),
                      const SizedBox(height: AppTokens.s8),
                      _Legend(
                        color: const Color(0xFFFF9F59),
                        label: "Skipped",
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s16),
              Row(
                children: [
                  Expanded(
                    child: _PercentCell(
                      percent: "$correctAnsPercentage%",
                      label: "Correct answer",
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: _PercentCell(
                      percent: "$incorrectAnsPercentage%",
                      label: "Incorrect answer",
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: _PercentCell(
                      percent: "$skippedAnsPercentage%",
                      label: "Skipped answer",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              Row(
                children: [
                  Expanded(
                    child: _PercentCell(
                      percent: "$accuracyPercentage%",
                      label: "Accuracy",
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _solutionReport(
                          widget.reports?.userExamId ?? "", "Correct"),
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                      child: _PercentCell(
                        percent: widget.reports?.correctAnswers.toString() ?? "",
                        label: "Correct",
                        isInteractive: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _solutionReport(widget.reports?.userExamId ?? "",
                          "View incorrect answer"),
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                      child: _PercentCell(
                        percent:
                            widget.reports?.incorrectAnswers.toString() ?? "",
                        label: "Incorrect",
                        isInteractive: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: _PercentCell(
                      percent: widget.reports?.skippedAnswers.toString() ?? "",
                      label: "Skipped",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuessAnalytics(
      BuildContext context, List<CircularStackEntry> datay) {
    final bool isEmpty = widget.reports?.wrongGuessCount == 0 &&
        widget.reports?.correctGuessCount == 0;
    if (isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTokens.surface2(context),
          borderRadius: BorderRadius.circular(AppTokens.r12),
        ),
        child: Text(
          "No Answer is Guessed ",
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppTokens.accent(context),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AnimatedCircularChart(
                key: _guessedchartkey,
                size: const Size(180.0, 180.0),
                initialChartData: datay,
                chartType: CircularChartType.Pie,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Legend(
                    color: ThemeManager.greenSuccess,
                    label: "Correct",
                  ),
                  const SizedBox(height: AppTokens.s8),
                  _Legend(
                    color: ThemeManager.redAlert,
                    label: "Incorrect",
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          Row(
            children: [
              Expanded(
                child: _PercentCell(
                  percent: "${widget.reports?.guessedAnswersCount}",
                  label: "Guessed answer",
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: _PercentCell(
                  percent: "${widget.reports?.correctGuessCount}",
                  label: "Correct answer",
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: _PercentCell(
                  percent: "${widget.reports?.wrongGuessCount}",
                  label: "Incorrect answer",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerEvolve(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _EvolveCell(
              value: "${widget.reports?.incorrect_correct}",
              from: "Incorrect",
              fromColor: ThemeManager.redAlert,
              to: "Correct",
              toColor: ThemeManager.greenSuccess,
            ),
          ),
          Container(
            height: 80,
            width: 1,
            color: AppTokens.border(context),
          ),
          Expanded(
            child: _EvolveCell(
              value: "${widget.reports?.correct_incorrect}",
              from: "Correct",
              fromColor: ThemeManager.greenSuccess,
              to: "Incorrect",
              toColor: ThemeManager.redAlert,
            ),
          ),
          Container(
            height: 80,
            width: 1,
            color: AppTokens.border(context),
          ),
          Expanded(
            child: _EvolveCell(
              value: "${widget.reports?.incorrect_incorres}",
              from: "Incorrect",
              fromColor: ThemeManager.redAlert,
              to: "Incorrect",
              toColor: ThemeManager.redAlert,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicList(
    BuildContext context,
    ReportsCategoryStore store,
    List<String?> Function(ReportSrengthModel?) extractor,
  ) {
    return Observer(
      builder: (_) {
        if (store.reportbytopicstreght.isEmpty) {
          return Text(
            "We're sorry, there's no content available right now. Please check back later or explore other sections for more educational resources.",
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w500,
              color: AppTokens.ink(context),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: store.reportbytopicstreght.length,
          itemBuilder: (BuildContext context, int index) {
            final item = store.reportbytopicstreght[index];
            final List<String?> topicNames = extractor(item);
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topicNames.length,
              itemBuilder: (BuildContext context, int topicIndex) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppTokens.s4),
                  child: Row(
                    children: [
                      Container(
                        height: 6,
                        width: 6,
                        decoration: BoxDecoration(
                          color: AppTokens.accent(context),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s8),
                      Expanded(
                        child: Text(
                          topicNames[topicIndex] ?? "",
                          style: AppTokens.body(context).copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppTokens.ink(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _OverviewCell extends StatelessWidget {
  final String iconAsset;
  final String label;
  final String value;

  const _OverviewCell({
    required this.iconAsset,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            iconAsset,
            height: 32,
            width: 32,
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.muted(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.ink(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _MiniStat({
    required this.value,
    required this.label,
  });

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
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.accent(context),
            ),
          ),
          const SizedBox(height: AppTokens.s4),
          Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        Text(
          label,
          style: AppTokens.caption(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppTokens.ink(context),
          ),
        ),
      ],
    );
  }
}

class _PercentCell extends StatelessWidget {
  final String percent;
  final String label;
  final bool isInteractive;

  const _PercentCell({
    required this.percent,
    required this.label,
    this.isInteractive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: isInteractive
            ? AppTokens.accentSoft(context)
            : AppTokens.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Column(
        children: [
          Text(
            percent,
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.accent(context),
            ),
          ),
          const SizedBox(height: AppTokens.s4),
          Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.muted(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EvolveCell extends StatelessWidget {
  final String value;
  final String from;
  final Color fromColor;
  final String to;
  final Color toColor;

  const _EvolveCell({
    required this.value,
    required this.from,
    required this.fromColor,
    required this.to,
    required this.toColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w700,
            color: AppTokens.ink(context),
          ),
        ),
        const SizedBox(height: AppTokens.s4),
        Text(
          from,
          style: AppTokens.caption(context).copyWith(
            fontWeight: FontWeight.w600,
            color: fromColor,
          ),
        ),
        Text(
          "↓",
          style: AppTokens.caption(context).copyWith(
            fontWeight: FontWeight.w700,
            color: AppTokens.muted(context),
          ),
        ),
        Text(
          to,
          style: AppTokens.caption(context).copyWith(
            fontWeight: FontWeight.w600,
            color: toColor,
          ),
        ),
      ],
    );
  }
}
