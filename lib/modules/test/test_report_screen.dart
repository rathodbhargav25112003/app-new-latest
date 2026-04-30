// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names, dead_code, prefer_final_fields, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:nuts_activity_indicator/nuts_activity_indicator.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:shusruta_lms/helpers/forked_packages/circular_chart_flutter/lib/circular_chart_flutter.dart';
import 'package:shusruta_lms/helpers/styles.dart';
import 'package:shusruta_lms/models/merit_list_model.dart';
import 'package:shusruta_lms/models/report_by_category_model.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';

/// Test result summary — shows attempt headline card (rank / marks /
/// percentage) plus action pair to open full solutions or the detailed
/// analytics screen.
///
/// Preserved public contract:
///   • `TestReportScreen({super.key, required title, reports, required
///     userexamId, required examId})` — `reports` optional, rest required.
///   • Static `route(RouteSettings)` reads
///     `{title, report, userexamId, examId}`.
///   • `initState` calls `getMeritList()`.
///   • `getMeritList()` → `store.onMeritListApiCall(widget.examId)`.
///   • `roundAndFormatDouble(String)` public helper — unchanged.
///   • `WillPopScope` back → pushes `Routes.reportsCategoryList` with
///     `{fromhome: true}`.
///   • "Solutions" button → `_getSolutionReport(userexamId, "View all")`
///     → `Routes.solutionReport` with `{solutionReport, filterVal,
///     userExamId}`.
///   • "Detailed Analytics" button → `Routes.testReportDetailsScreen`
///     with `{report, title, userexamId, examId}`.
///   • Observer over `ReportsCategoryStore`.
///   • Loading copy: "Getting everything ready for you... Just a moment!".
///   • Header title: "Analysis & Solutions".
///   • Body labels: "1st Attempt", "My Marks", "My Percentage",
///     "Rank #X", "X/Y", "X%".
class TestReportScreen extends StatefulWidget {
  final String title;
  final ReportByCategoryModel? reports;
  final String userexamId;
  final String examId;
  const TestReportScreen(
      {super.key,
      required this.title,
      this.reports,
      required this.userexamId,
      required this.examId});

  @override
  State<TestReportScreen> createState() => _TestReportScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => TestReportScreen(
        title: arguments['title'],
        reports: arguments['report'],
        userexamId: arguments['userexamId'],
        examId: arguments['examId'],
      ),
    );
  }
}

class _TestReportScreenState extends State<TestReportScreen> {
  final GlobalKey<AnimatedCircularChartState> _chartKey =
      GlobalKey<AnimatedCircularChartState>();
  final GlobalKey<AnimatedCircularChartState> _guessedchartKey =
      GlobalKey<AnimatedCircularChartState>();

  @override
  void initState() {
    super.initState();
    getMeritList();
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
    await store.onMeritListApiCall(widget.examId);
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);

    // Retained for API/forked chart compatibility — data shapes unchanged.
    final List<CircularStackEntry> data = <CircularStackEntry>[
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
    final List<CircularStackEntry> datax = <CircularStackEntry>[
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

    final double percentageValue =
        double.tryParse(widget.reports?.percentage ?? "") ?? 0;
    final String percentage =
        (percentageValue >= 0) ? percentageValue.toString() : "0";
    final String myMarks = (widget.reports?.myMark ?? 0) >= 0
        ? widget.reports?.myMark.toString() ?? ""
        : "0";
    final String originalDate = widget.reports?.date ?? "";
    final DateTime parsedDate = DateTime.parse(originalDate);
    final formatter = DateFormat('dd MMM, yyyy');
    final String formattedDate = formatter.format(parsedDate);

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
        Navigator.of(context).pushNamed(Routes.reportsCategoryList,
            arguments: {'fromhome': true});
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        body: Observer(
          builder: (BuildContext context) {
            final List<MeritListModel?> meritList = store.meritList;
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
                    const SizedBox(height: AppTokens.s16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s24),
                      child: Text(
                        "Getting everything ready for you... Just a moment!",
                        style: AppTokens.body(context).copyWith(
                          color: AppTokens.muted(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                _Header(
                  onBack: () {
                    Navigator.of(context).pushNamed(Routes.reportsCategoryList,
                        arguments: {'fromhome': true});
                  },
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTokens.scaffold(context),
                      borderRadius: (Platform.isWindows || Platform.isMacOS)
                          ? null
                          : const BorderRadius.only(
                              topLeft: Radius.circular(AppTokens.r28),
                              topRight: Radius.circular(AppTokens.r28),
                            ),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                        AppTokens.s20, AppTokens.s20, AppTokens.s20, AppTokens.s24),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SummaryCard(
                            title: widget.title,
                            subtitle:
                                "Attempt ${widget.reports?.isAttemptcount.toString() ?? ""} | $formattedDate",
                            rows: [
                              _SummaryRow(
                                icon: "assets/image/firstAttempt.png",
                                label: "1st Attempt",
                                value:
                                    "Rank #${widget.reports?.userFirstRank.toString()}",
                              ),
                              _SummaryRow(
                                icon: "assets/image/myMark.png",
                                label: "My Marks",
                                value:
                                    "$myMarks/${widget.reports?.mark.toString()}",
                              ),
                              _SummaryRow(
                                icon: "assets/image/myPercantage.png",
                                label: "My Percentage",
                                value: "$percentage%",
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.s20),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  label: "Solutions",
                                  outlined: true,
                                  onTap: () {
                                    _getSolutionReport(
                                        widget.userexamId, "View all");
                                  },
                                ),
                              ),
                              const SizedBox(width: AppTokens.s12),
                              Expanded(
                                child: _ActionButton(
                                  label: "Detailed Analytics",
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                        Routes.testReportDetailsScreen,
                                        arguments: {
                                          'report': widget.reports,
                                          'title': widget.title,
                                          'userexamId': widget.userexamId,
                                          'examId': widget.examId
                                        });
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

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppTokens.s12,
        (Platform.isWindows || Platform.isMacOS)
            ? AppTokens.s16
            : MediaQuery.of(context).padding.top + AppTokens.s12,
        AppTokens.s20,
        AppTokens.s20,
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppTokens.r8),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(AppTokens.r8),
              child: const SizedBox(
                height: AppTokens.s32,
                width: AppTokens.s32,
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.white, size: 16),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              "Analysis & Solutions",
              style: AppTokens.titleSm(context).copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow {
  final String icon;
  final String label;
  final String value;
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_SummaryRow> rows;
  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.border(context)),
      ),
      padding: const EdgeInsets.all(AppTokens.s16),
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
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                color: AppTokens.border(context),
                height: AppTokens.s24,
              ),
            Row(
              children: [
                Image.asset(rows[i].icon, width: 32, height: 32),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rows[i].label,
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.muted(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rows[i].value,
                        style: AppTokens.titleSm(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTokens.ink(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool outlined;
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outlined
              ? AppTokens.surface(context)
              : AppTokens.accent(context),
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: outlined
              ? Border.all(color: AppTokens.border(context))
              : null,
        ),
        child: Text(
          label,
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w600,
            color:
                outlined ? AppTokens.ink(context) : AppColors.white,
          ),
        ),
      ),
    );
  }
}
