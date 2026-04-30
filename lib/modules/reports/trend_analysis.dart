// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, avoid_print, non_constant_identifier_names, unnecessary_null_comparison, dead_code, dead_null_aware_expression

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:shusruta_lms/api_service/api_service.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:shusruta_lms/helpers/forked_packages/circular_chart_flutter/lib/circular_chart_flutter.dart';
import 'package:shusruta_lms/helpers/styles.dart';
import 'package:shusruta_lms/models/trend_analysis_model.dart';
import 'package:shusruta_lms/modules/masterTest/master_test_report_details_screen.dart';
import 'package:shusruta_lms/modules/masterTest/strength_weakness_graph.dart';

/// Trend analysis of a single analysis tab (legacy deep-link screen).
///
/// Preserved public contract:
///   • `AnalysisOfAllExamScreen({super.key, required data, required title,
///     required index})`
///   • `index==1` → `Predictive(data)` page body.
///   • `index==3` → dropdown above the list ("Choose Topic Name") with
///     validator message "Please choose one." and selectedValue binding to
///     `TopicsInsight(model, topicName: selectedValue)`.
///   • Other `index` values render `YourMark` (2) / `EduMetrics` (4) /
///     `Guess` (5) / `Answer` (6) / `Strength` (7) / `Weakness` (8).
///   • `TitleWidget(name: ...)` preserved at top of every per-attempt card.
///   • Card models preserved: `YourMark({required model})`,
///     `TopicsInsight({required model, required topicName})`,
///     `EduMetrics({required model})`, `Guess({required model})`,
///     `Answer({required model})`, `Strength({required model})`,
///     `Weakness({required model})`, `Predictive({required data})`.
///   • Top-level helper `roundAndFormatDouble(String)` preserved.
///   • Strength/Weakness topic chip tap → `CupertinoPageRoute(builder:
///     StrengthWeaknessGraph(lastThreeIncorrect: model.lastThreeIncorrect[i]))`.
///   • Predictive → `ApiService().getNeetPrediction(mymark)` per attempt,
///     uses `PredictedRankWidget(store: scores[index])`.
///   • Empty-state copy preserved verbatim for Strength / Weakness / Guess /
///     TopicsInsight.
class AnalysisOfAllExamScreen extends StatefulWidget {
  const AnalysisOfAllExamScreen({
    super.key,
    required this.data,
    required this.title,
    required this.index,
  });
  final List<TrendAnalysisModel> data;
  final String title;
  final int index;
  @override
  State<AnalysisOfAllExamScreen> createState() =>
      _AnalysisOfAllExamScreenState();
}

class _AnalysisOfAllExamScreenState extends State<AnalysisOfAllExamScreen> {
  bool _isTopicNameValid = false;
  final _topicNameKey = GlobalKey<FormFieldState<String>>();
  String selectedValue = '';

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<String>> dropdownItems =
        widget.data[widget.data.length - 1].topicWiseReport.map((item) {
      final topicName = item.topicName;
      return DropdownMenuItem<String>(
        value: topicName,
        child: Text(topicName),
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _buildHeader(context),
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
                AppTokens.s20,
                AppTokens.s20,
                AppTokens.s20,
                AppTokens.s8,
              ),
              child: widget.index == 1
                  ? Predictive(data: widget.data)
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          if (widget.index == 3) ...[
                            _buildTopicDropdown(context, dropdownItems),
                            const SizedBox(height: AppTokens.s16),
                          ],
                          ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: widget.data.length,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (BuildContext context, int index) {
                              final m = widget.data[index];
                              switch (widget.index) {
                                case 2:
                                  return YourMark(model: m);
                                case 4:
                                  return EduMetrics(model: m);
                                case 5:
                                  return Guess(model: m);
                                case 6:
                                  return Answer(model: m);
                                case 7:
                                  return Strength(model: m);
                                case 8:
                                  return Weakness(model: m);
                                default:
                                  return TopicsInsight(
                                    model: m,
                                    topicName: selectedValue,
                                  );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
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
              widget.title,
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

  Widget _buildTopicDropdown(BuildContext context,
      List<DropdownMenuItem<String>> dropdownItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Choose Topic",
          style: AppTokens.caption(context).copyWith(
            fontWeight: FontWeight.w700,
            color: AppTokens.ink(context),
          ),
        ),
        const SizedBox(height: AppTokens.s8),
        Observer(builder: (context) {
          if (widget.data[widget.data.length - 1].topicWiseReport.isEmpty) {
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
              setState(() => selectedValue = value ?? '');
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
        }),
      ],
    );
  }
}

class TitleWidget extends StatelessWidget {
  const TitleWidget({super.key, required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            name,
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.ink(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTokens.s8),
          Divider(color: AppTokens.border(context), height: 1),
        ],
      ),
    );
  }
}

Widget _attemptCard(BuildContext context, Widget child) {
  return Container(
    margin: const EdgeInsets.only(bottom: AppTokens.s12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppTokens.r16),
      color: AppTokens.surface(context),
      border: Border.all(color: AppTokens.border(context)),
    ),
    child: child,
  );
}

Widget _statTile(
  BuildContext context, {
  required String label,
  required String value,
  required Color badgeColor,
  required String assetPath,
  bool flipBadge = false,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppTokens.s12,
      vertical: AppTokens.s12,
    ),
    decoration: BoxDecoration(
      color: AppTokens.surface(context),
      borderRadius: BorderRadius.circular(AppTokens.r12),
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
                label,
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.muted(context),
                ),
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
              ),
            ],
          ),
        ),
        Container(
          height: 36,
          width: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.r8),
            gradient: LinearGradient(
              colors: [badgeColor.withOpacity(0.2), badgeColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Transform.flip(
            flipY: flipBadge,
            child: SvgPicture.asset(
              assetPath,
              color: Colors.white,
              height: 18,
              width: 18,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _legendDot(BuildContext context, Color color, String label, String count) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        height: 10,
        width: 10,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
      Text(
        label,
        style: AppTokens.caption(context).copyWith(
          color: AppTokens.ink(context),
        ),
      ),
      const SizedBox(width: 4),
      Text(
        "($count)",
        style: AppTokens.caption(context).copyWith(
          fontWeight: FontWeight.w700,
          color: AppTokens.ink(context),
        ),
      ),
    ],
  );
}

///YourMark
class YourMark extends StatelessWidget {
  const YourMark({super.key, required this.model});
  final TrendAnalysisModel model;
  @override
  Widget build(BuildContext context) {
    return _attemptCard(
      context,
      Column(
        children: [
          TitleWidget(name: model.examName),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s16,
              0,
              AppTokens.s16,
              AppTokens.s16,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Image.asset(
                      "assets/image/myMark.png",
                      height: 40,
                      width: 40,
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "My Marks",
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.muted(context),
                          ),
                        ),
                        Text(
                          "${model.mymark}/${model.mark}",
                          style: AppTokens.titleSm(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s12),
                Divider(color: AppTokens.border(context), height: 1),
                const SizedBox(height: AppTokens.s12),
                Row(
                  children: [
                    Image.asset(
                      "assets/image/myPercantage.png",
                      height: 40,
                      width: 40,
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "My Percentage",
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.muted(context),
                          ),
                        ),
                        Text(
                          "${model.percentage}%",
                          style: AppTokens.titleSm(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s16),
                Row(
                  children: [
                    Expanded(
                      child: _statTile(
                        context,
                        label: "Correct Questions",
                        value: model.correctAnswers.toString(),
                        badgeColor: ThemeManager.correctChart,
                        assetPath: "assets/image/analysisUpArrow.svg",
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: _statTile(
                        context,
                        label: "Skipped Questions",
                        value: model.leftqusestion.toString(),
                        badgeColor: ThemeManager.skipChart,
                        assetPath: "assets/image/analysisClock.svg",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: _statTile(
                        context,
                        label: "Incorrect Questions",
                        value: model.incorrectAnswers.toString(),
                        badgeColor: ThemeManager.incorrectChart,
                        assetPath: "assets/image/analysisUpArrow.svg",
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: _statTile(
                        context,
                        label: "Total Questions",
                        value: model.question.toString(),
                        badgeColor: AppTokens.accent(context),
                        assetPath: "assets/image/analysisClock.svg",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TopicsInsight extends StatefulWidget {
  const TopicsInsight({
    super.key,
    required this.model,
    required this.topicName,
  });
  final TrendAnalysisModel model;
  final String topicName;
  @override
  State<TopicsInsight> createState() => _TopicsInsightState();
}

class _TopicsInsightState extends State<TopicsInsight> {
  String? topicName;
  String? topicTime;
  bool isCompar = false;
  int? correctAnswers;
  int? incorrectAnswers;
  int? skippedAnswers;
  int? guessedAnswers;
  int? totalQuestions;
  int? totalAnswers;
  final bool _isTopicNameValid = false;
  final _topicNameKey = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.topicName != '') {
      final TopicWiseReport selectedModel =
          widget.model.topicWiseReport.firstWhere(
        (e) => e.topicName == widget.topicName,
        orElse: () => TopicWiseReport(
          topicName: "NA",
          correctAnswers: 0,
          incorrectAnswers: 0,
          totalQuestions: 0,
          skippedAnswers: 0,
          totalTime: "",
        ),
      );
      if (selectedModel.topicName != "NA") {
        topicName = selectedModel.topicName;
        correctAnswers = selectedModel.correctAnswers;
        incorrectAnswers = selectedModel.incorrectAnswers;
        skippedAnswers = (selectedModel.totalQuestions ?? 0) -
            (selectedModel.correctAnswers ?? 0) -
            (selectedModel.skippedAnswers ?? 0);
        totalQuestions = selectedModel.totalQuestions;
        topicTime = selectedModel.totalTime ?? "00:00";
        totalAnswers = (selectedModel.correctAnswers ?? 0) +
            (selectedModel.incorrectAnswers ?? 0) +
            (selectedModel.skippedAnswers ?? 0);
      }
    }

    final List<_ChartData> topicData = [
      _ChartData('Correct', correctAnswers?.toDouble() ?? 0),
      _ChartData('Skipped', skippedAnswers?.toDouble() ?? 0),
      _ChartData('Incorrect', skippedAnswers?.toDouble() ?? 0),
    ];

    return _attemptCard(
      context,
      Padding(
        padding: const EdgeInsets.only(bottom: AppTokens.s12),
        child: Column(
          children: [
            TitleWidget(name: widget.model.examName),
            widget.topicName != ''
                ? Column(
                    children: [
                      Stack(
                        alignment: AlignmentDirectional.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Total Questions",
                                style: AppTokens.caption(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTokens.muted(context),
                                ),
                              ),
                              Text(
                                totalQuestions?.toString() ?? "0",
                                style: AppTokens.body(context).copyWith(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: AppTokens.ink(context),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  formatTimeString(
                                      topicTime?.toString() ?? "00:00:00"),
                                  style: AppTokens.body(context).copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppTokens.ink(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SfCircularChart(palette: [
                            ThemeManager.correctChart,
                            ThemeManager.skipChart,
                            ThemeManager.incorrectChart,
                          ], series: <CircularSeries<_ChartData, String>>[
                            DoughnutSeries<_ChartData, String>(
                              dataSource: topicData,
                              radius: '95%',
                              innerRadius: '65%',
                              xValueMapper: (_ChartData data, _) => data.x,
                              yValueMapper: (_ChartData data, _) => data.y,
                              name: 'Topicwise Insights',
                            )
                          ])
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _legendDot(context, ThemeManager.correctChart,
                                "Correct", "${correctAnswers ?? 0}"),
                            _legendDot(context, ThemeManager.skipChart,
                                "Skipped", "${skippedAnswers ?? 0}"),
                            _legendDot(context, ThemeManager.incorrectChart,
                                "Incorrect", "${incorrectAnswers ?? 0}"),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTokens.s12),
                    ],
                  )
                : SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        "No Topic Found",
                        style: AppTokens.body(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTokens.muted(context),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final double y;
}

String roundAndFormatDouble(String value) {
  double doubleValue = double.tryParse(value) ?? 0.0;
  int roundedValue = doubleValue.round();
  return roundedValue.toString();
}

class EduMetrics extends StatelessWidget {
  EduMetrics({super.key, required this.model});
  final TrendAnalysisModel model;
  final GlobalKey<AnimatedCircularChartState> _chartKey =
      GlobalKey<AnimatedCircularChartState>();

  @override
  Widget build(BuildContext context) {
    final String correctAnsPercentage =
        roundAndFormatDouble(model.correctAnswersPercentage ?? "0.0");
    final String incorrectAnsPercentage =
        roundAndFormatDouble(model.incorrectAnswersPercentage.toString());
    final String skippedAnsPercentage =
        roundAndFormatDouble(model.skippedAnswersPercentage.toString());
    final String accuracyPercentage =
        roundAndFormatDouble(model.accuracyPercentage.toString());

    final List<CircularStackEntry> data = <CircularStackEntry>[
      CircularStackEntry(
        <CircularSegmentEntry>[
          CircularSegmentEntry(
              double.tryParse(model.incorrectAnswersPercentage ?? "0") ?? 0,
              ThemeManager.incorrectChart,
              rankKey: 'Q1'),
          CircularSegmentEntry(
              double.tryParse(model.correctAnswersPercentage ?? "0") ?? 0,
              ThemeManager.correctChart,
              rankKey: 'Q2'),
          CircularSegmentEntry(
              double.tryParse(model.skippedAnswersPercentage ?? "0") ?? 0,
              ThemeManager.skipChart,
              rankKey: 'Q3'),
        ],
        rankKey: 'Quarterly Profits',
      ),
    ];

    return _attemptCard(
      context,
      Column(
        children: [
          TitleWidget(name: model.examName),
          Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Total Questions",
                    style: AppTokens.caption(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTokens.muted(context),
                    ),
                  ),
                  Text(
                    model.question.toString(),
                    style: AppTokens.body(context).copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.ink(context),
                    ),
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
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _legendDot(context, ThemeManager.correctChart, "Correct",
                        "$correctAnsPercentage%"),
                    _legendDot(context, ThemeManager.incorrectChart,
                        "Incorrect", "$incorrectAnsPercentage%"),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendDot(context, ThemeManager.skipChart, "Skipped",
                        "$skippedAnsPercentage%"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s16,
              0,
              AppTokens.s16,
              AppTokens.s16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _statTile(
                    context,
                    label: "Accuracy",
                    value: "$accuracyPercentage%",
                    badgeColor: AppTokens.accent(context),
                    assetPath: "assets/image/accuracy.svg",
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: _statTile(
                    context,
                    label: "Time Taken",
                    value: model.time.toString(),
                    badgeColor: ThemeManager.skipChart,
                    assetPath: "assets/image/timeTaken.svg",
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

class Guess extends StatelessWidget {
  Guess({super.key, required this.model});
  final TrendAnalysisModel model;
  final GlobalKey<AnimatedCircularChartState> _guessedchartKey =
      GlobalKey<AnimatedCircularChartState>();

  @override
  Widget build(BuildContext context) {
    final List<CircularStackEntry> datax = <CircularStackEntry>[
      CircularStackEntry(
        <CircularSegmentEntry>[
          CircularSegmentEntry(
            model.correctGuessCount.toDouble(),
            ThemeManager.greenSuccess,
            rankKey: 'Q1',
          ),
          CircularSegmentEntry(
            model.wrongGuessCount.toDouble(),
            ThemeManager.redAlert,
            rankKey: 'Q2',
          ),
        ],
        rankKey: 'Guessed_Questions_Stats',
      ),
    ];

    return _attemptCard(
      context,
      Column(
        children: [
          TitleWidget(name: model.examName),
          model.wrongGuessCount == 0 && model.correctGuessCount == 0
              ? SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      "No Answer is Guessed ",
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTokens.muted(context),
                      ),
                    ),
                  ),
                )
              : Stack(
                  alignment: AlignmentDirectional.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Guessed Answers",
                          style: AppTokens.caption(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTokens.muted(context),
                          ),
                        ),
                        Text(
                          model.guessedAnswersCount.toString(),
                          style: AppTokens.body(context).copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink(context),
                          ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s16,
              0,
              AppTokens.s16,
              AppTokens.s16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _statTile(
                    context,
                    label: "Correct Answer",
                    value: "${model.correctGuessCount}",
                    badgeColor: ThemeManager.greenSuccess,
                    assetPath: "assets/image/accuracy.svg",
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: _statTile(
                    context,
                    label: "Incorrect Answer",
                    value: "${model.wrongGuessCount}",
                    badgeColor: ThemeManager.redAlert,
                    assetPath: "assets/image/accuracy.svg",
                    flipBadge: true,
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

class Answer extends StatelessWidget {
  const Answer({super.key, required this.model});
  final TrendAnalysisModel model;
  @override
  Widget build(BuildContext context) {
    return _attemptCard(
      context,
      Column(
        children: [
          TitleWidget(name: model.examName),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s16,
              0,
              AppTokens.s16,
              AppTokens.s16,
            ),
            child: Column(
              children: [
                _evolveTile(
                  context,
                  label: "Correct to Incorrect",
                  value: "${model.correctIncorrect}",
                  border: GradientBoxBorder(
                    gradient: LinearGradient(colors: [
                      ThemeManager.evolveGreen,
                      ThemeManager.evolveRed,
                    ]),
                    width: 1,
                  ),
                  badgeColor: ThemeManager.evolveRed,
                  asset: "assets/image/accuracy.svg",
                  flipBadge: true,
                ),
                const SizedBox(height: AppTokens.s8),
                _evolveTile(
                  context,
                  label: "Incorrect to Correct",
                  value: "${model.incorrectCorrect}",
                  border: GradientBoxBorder(
                    gradient: LinearGradient(colors: [
                      ThemeManager.evolveRed,
                      ThemeManager.evolveGreen,
                    ]),
                    width: 1,
                  ),
                  badgeColor: ThemeManager.evolveGreen,
                  asset: "assets/image/accuracy.svg",
                ),
                const SizedBox(height: AppTokens.s8),
                _evolveTile(
                  context,
                  label: "Incorrect to Incorrect",
                  value: "${model.incorrectIncorres}",
                  border: Border.all(
                    color: ThemeManager.evolveYellow,
                    width: 1,
                  ),
                  badgeColor: ThemeManager.evolveYellow,
                  asset: "assets/image/accuracy2.svg",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _evolveTile(
    BuildContext context, {
    required String label,
    required String value,
    required BoxBorder border,
    required Color badgeColor,
    required String asset,
    bool flipBadge = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        border: border,
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink(context),
                ),
              ),
            ],
          ),
          Container(
            height: 36,
            width: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.r8),
              gradient: LinearGradient(
                colors: [badgeColor.withOpacity(0.2), badgeColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Transform.flip(
              flipY: flipBadge,
              child: SvgPicture.asset(
                asset,
                color: Colors.white,
                height: 18,
                width: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Strength extends StatelessWidget {
  const Strength({super.key, required this.model});
  final TrendAnalysisModel model;
  @override
  Widget build(BuildContext context) {
    return _attemptCard(
      context,
      Column(
        children: [
          TitleWidget(name: model.examName),
          if (model.lastThreeIncorrect.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s16,
                0,
                AppTokens.s16,
                AppTokens.s12,
              ),
              child: Text(
                "We're sorry, there's no content available right now. Please check back later or explore other sections for more educational resources.",
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppTokens.ink(context),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            _chipWrap(
              context,
              topicNames: model.lastThreeIncorrect
                  .map((e) => e.topicName)
                  .toList(),
              background: ThemeManager.strengthColor,
              onTap: (index) => Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => StrengthWeaknessGraph(
                    lastThreeIncorrect: model.lastThreeIncorrect[index],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Weakness extends StatelessWidget {
  const Weakness({super.key, required this.model});
  final TrendAnalysisModel model;
  @override
  Widget build(BuildContext context) {
    return _attemptCard(
      context,
      Column(
        children: [
          TitleWidget(name: model.examName),
          if (model.lastThreeIncorrect.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s16,
                0,
                AppTokens.s16,
                AppTokens.s12,
              ),
              child: Text(
                "We're sorry, there's no content available right now. Please check back later or explore other sections for more educational resources.",
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppTokens.ink(context),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            _chipWrap(
              context,
              topicNames: model.lastThreeIncorrect
                  .map((e) => e.topicName)
                  .toList(),
              background: ThemeManager.weaknessColor,
              onTap: (index) => Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => StrengthWeaknessGraph(
                    lastThreeIncorrect: model.lastThreeIncorrect[index],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _chipWrap(
  BuildContext context, {
  required List<String?> topicNames,
  required Color background,
  required void Function(int) onTap,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(
      AppTokens.s16,
      0,
      AppTokens.s16,
      AppTokens.s12,
    ),
    child: Wrap(
      spacing: AppTokens.s8,
      runSpacing: AppTokens.s8,
      children: List.generate(
        topicNames.length,
        (topicIndex) => GestureDetector(
          onTap: () => onTap(topicIndex),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s16,
              vertical: AppTokens.s8,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppTokens.r20),
            ),
            child: Text(
              topicNames[topicIndex] ?? "",
              style: AppTokens.caption(context).copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class Predictive extends StatefulWidget {
  const Predictive({super.key, required this.data});
  final List<TrendAnalysisModel> data;
  @override
  State<Predictive> createState() => _PredictiveState();
}

class _PredictiveState extends State<Predictive> {
  bool isLoading = true;
  List<Map<String, dynamic>> scores = [];

  @override
  void initState() {
    getScore();
    super.initState();
  }

  Future<void> getScore() async {
    final ApiService apiService = ApiService();

    for (var i = 0; i < widget.data.length; i++) {
      final Map<String, dynamic> result =
          await apiService.getNeetPrediction(widget.data[i].mymark.toString());
      scores.add(result);
    }
    isLoading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(
            child: CircularProgressIndicator(
              color: AppTokens.accent(context),
            ),
          )
        : ListView.builder(
            itemCount: scores.length,
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) => _attemptCard(
              context,
              Column(
                children: [
                  TitleWidget(name: widget.data[index].examName),
                  PredictedRankWidget(store: scores[index]),
                ],
              ),
            ),
          );
  }
}
