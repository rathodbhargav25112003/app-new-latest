// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, use_build_context_synchronously, unused_field, avoid_print, non_constant_identifier_names, unused_local_variable

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
import 'package:shusruta_lms/models/merit_list_model.dart';
import 'package:shusruta_lms/models/report_by_category_model.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';

/// Single-attempt overview for a regular exam.
///
/// Preserved public contract:
///   • `ReportMainScreen({Key? key, this.reports, required title, this.examId})`
///   • Static `route(RouteSettings)` reads `{report, title, examId}`.
///   • `store.onMeritListApiCall(widget.examId ?? "")` in initState.
///   • `_solutionReport(examId, filter)` chains
///     `store.onSolutionReportApiCall(examId, "")` → pushes
///     `Routes.solutionReport` with
///     `{'solutionReport': store.solutionReportCategory,
///     'filterVal': filter, 'userExamId': examId}`.
///   • "Detailed Analytics" → `Routes.testReportDetailsScreen` with
///     `{report, title, userexamId, examId}`.
///   • `roundAndFormatDouble(value)` rounds a stringified double to
///     nearest int string.
///   • Labels byte-for-byte: "Getting everything ready for you... Just
///     a moment!", "Analysis & Solutions",
///     "Attempt {X} | {date}", "1st Attempt", "Rank #{X}", "My Marks",
///     "{X}/{Y}", "My Percentage", "{X}%", "Solutions",
///     "Detailed Analytics".
class ReportMainScreen extends StatefulWidget {
  final ReportByCategoryModel? reports;
  final String title;
  final String? examId;

  const ReportMainScreen({
    Key? key,
    this.reports,
    required this.title,
    this.examId,
  }) : super(key: key);

  @override
  State<ReportMainScreen> createState() => _ReportMainScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => ReportMainScreen(
        reports: arguments['report'],
        title: arguments['title'],
        examId: arguments['examId'],
      ),
    );
  }
}

class _ReportMainScreenState extends State<ReportMainScreen> {
  final GlobalKey<AnimatedCircularChartState> _chartKey =
      GlobalKey<AnimatedCircularChartState>();
  final GlobalKey<AnimatedCircularChartState> _guessedchartKey =
      GlobalKey<AnimatedCircularChartState>();

  Future<void> _solutionReport(String examId, String filterVal) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onSolutionReportApiCall(examId, "").then((_) {
      Navigator.of(context).pushNamed(Routes.solutionReport, arguments: {
        'solutionReport': store.solutionReportCategory,
        'filterVal': filterVal,
        'userExamId': examId
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _getMeritList();
  }

  Future<void> _getMeritList() async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onMeritListApiCall(widget.examId ?? "");
    debugPrint('meritname${store.meritList.map((e) => e?.fullName)}');
  }

  String roundAndFormatDouble(String value) {
    double doubleValue = double.tryParse(value) ?? 0.0;
    int roundedValue = doubleValue.round();
    return roundedValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);

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
    final List<CircularStackEntry> data = <CircularStackEntry>[
      CircularStackEntry(
        <CircularSegmentEntry>[
          CircularSegmentEntry(
            double.tryParse(widget.reports?.incorrectAnswersPercentage ?? "") ??
                0,
            ThemeManager.redAlert,
            rankKey: 'Q1',
          ),
          CircularSegmentEntry(
            double.tryParse(widget.reports?.correctAnswersPercentage ?? "") ??
                0,
            ThemeManager.greenSuccess,
            rankKey: 'Q2',
          ),
          CircularSegmentEntry(
            double.tryParse(widget.reports?.skippedAnswersPercentage ?? "") ??
                0,
            const Color(0xFFFF9F59),
            rankKey: 'Q3',
          ),
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
    DateTime parsedDate = DateTime.parse(originalDate);
    final formatter = DateFormat('dd MMM, yyyy');
    String formattedDate = formatter.format(parsedDate);

    String correctAnsPercentage =
        roundAndFormatDouble(widget.reports?.correctAnswersPercentage ?? "0.0");
    String incorrectAnsPercentage = roundAndFormatDouble(
        widget.reports?.incorrectAnswersPercentage.toString() ?? "0.0");
    String skippedAnsPercentage = roundAndFormatDouble(
        widget.reports?.skippedAnswersPercentage.toString() ?? "0.0");
    String accuracyPercentage = roundAndFormatDouble(
        widget.reports?.accuracyPercentage.toString() ?? "0.0");

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Observer(
        builder: (BuildContext context) {
          final List<MeritListModel?> meritList = store.meritList;
          if (store.isLoading) {
            return _buildLoadingState(context);
          }
          return Column(
            children: [
              _buildHeader(context),
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
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _OverviewCard(
                          title: widget.title,
                          attemptLine:
                              "Attempt ${widget.reports?.isAttemptcount.toString() ?? ""} | $formattedDate",
                          rank: widget.reports?.userFirstRank?.toString() ?? "",
                          myMarks: myMarks,
                          totalMarks: widget.reports?.mark.toString() ?? "",
                          percentage: percentage,
                        ),
                        const SizedBox(height: AppTokens.s16),
                        _buildActionButtons(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTokens.accent(context)),
          const SizedBox(height: AppTokens.s16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTokens.s8,
        left: AppTokens.s8,
        right: AppTokens.s20,
        bottom: AppTokens.s20,
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

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              _solutionReport(widget.reports?.userExamId ?? "", "View all");
            },
            borderRadius: BorderRadius.circular(AppTokens.r12),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTokens.surface(context),
                borderRadius: BorderRadius.circular(AppTokens.r12),
                border: Border.all(color: AppTokens.border(context)),
              ),
              child: Text(
                "Solutions",
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTokens.ink(context),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTokens.s12),
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(
                Routes.testReportDetailsScreen,
                arguments: {
                  'report': widget.reports,
                  'title': widget.title,
                  'userexamId': widget.reports?.userExamId,
                  'examId': widget.examId,
                },
              );
            },
            borderRadius: BorderRadius.circular(AppTokens.r12),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTokens.brand, AppTokens.brand2],
                ),
                borderRadius: BorderRadius.circular(AppTokens.r12),
              ),
              child: Text(
                "Detailed Analytics",
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String attemptLine;
  final String rank;
  final String myMarks;
  final String totalMarks;
  final String percentage;

  const _OverviewCard({
    required this.title,
    required this.attemptLine,
    required this.rank,
    required this.myMarks,
    required this.totalMarks,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
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
            children: [
              Container(
                height: 48,
                width: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                ),
                child: SvgPicture.asset(
                  "assets/image/award.svg",
                  color: AppTokens.accent(context),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTokens.ink(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      attemptLine,
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          Container(
            height: 1,
            color: AppTokens.border(context),
          ),
          const SizedBox(height: AppTokens.s12),
          _StatRow(
            asset: "assets/image/firstAttempt.png",
            label: "1st Attempt",
            value: "Rank #$rank",
          ),
          const SizedBox(height: AppTokens.s12),
          Container(height: 1, color: AppTokens.border(context)),
          const SizedBox(height: AppTokens.s12),
          _StatRow(
            asset: "assets/image/myMark.png",
            label: "My Marks",
            value: "$myMarks/$totalMarks",
          ),
          const SizedBox(height: AppTokens.s12),
          Container(height: 1, color: AppTokens.border(context)),
          const SizedBox(height: AppTokens.s12),
          _StatRow(
            asset: "assets/image/myPercantage.png",
            label: "My Percentage",
            value: "$percentage%",
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String asset;
  final String label;
  final String value;

  const _StatRow({
    required this.asset,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 40,
          width: 40,
          child: Image.asset(asset),
        ),
        const SizedBox(width: AppTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.muted(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTokens.titleSm(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
