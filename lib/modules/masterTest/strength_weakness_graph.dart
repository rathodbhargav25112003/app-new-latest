// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names, dead_null_aware_expression

import 'package:flutter/material.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/forked_packages/circular_chart_flutter/lib/circular_chart_flutter.dart';
import 'package:shusruta_lms/models/strength_model.dart';

/// Per-topic strength / weakness graph screen — redesigned with AppTokens.
/// Preserves:
///   • Constructor `StrengthWeaknessGraph({super.key, topThreeCorrect,
///     lastThreeIncorrect})`
///   • `_chartKey` GlobalKey on AnimatedCircularChartState
///   • `analysisData` list populated in initState with either topThreeCorrect
///     or lastThreeIncorrect payload (topicName / totalQuestions /
///     correctAnswers / incorrectAnswers / correctAnswersPercentage /
///     incorrectAnswersPercentage)
///   • `_generateChartData(topicData)` helper signature
///   • `_buildLegendItem(label, color)` helper signature
///   • AnimatedCircularChart(size: 500×300, holeRadius: 40, chartType: Radial)
class StrengthWeaknessGraph extends StatefulWidget {
  const StrengthWeaknessGraph(
      {super.key, this.topThreeCorrect, this.lastThreeIncorrect});
  final TopThreeCorrect? topThreeCorrect;
  final LastThreeIncorrect? lastThreeIncorrect;
  @override
  State<StrengthWeaknessGraph> createState() => _StrengthWeaknessGraphState();
}

class _StrengthWeaknessGraphState extends State<StrengthWeaknessGraph> {
  final GlobalKey<AnimatedCircularChartState> _chartKey =
      GlobalKey<AnimatedCircularChartState>();

  // Simulating the analysis data received
  final List<Map<String, dynamic>> analysisData = [];

  @override
  void initState() {
    analysisData.add(widget.topThreeCorrect != null
        ? {
            "topicName": widget.topThreeCorrect!.topicName ?? "",
            "totalQuestions": widget.topThreeCorrect!.totalQuestions ?? 0,
            "correctAnswers": widget.topThreeCorrect!.correctAnswers ?? 0,
            "incorrectAnswers": widget.topThreeCorrect!.incorrectAnswers ?? 0,
            "correctAnswersPercentage":
                widget.topThreeCorrect!.correctAnswersPercentage,
            "incorrectAnswersPercentage":
                widget.topThreeCorrect!.incorrectAnswersPercentage
          }
        : {
            "topicName": widget.lastThreeIncorrect!.topicName,
            "totalQuestions": widget.lastThreeIncorrect!.totalQuestions,
            "correctAnswers": widget.lastThreeIncorrect!.correctAnswers,
            "incorrectAnswers": widget.lastThreeIncorrect!.incorrectAnswers,
            "correctAnswersPercentage":
                widget.lastThreeIncorrect!.correctAnswersPercentage,
            "incorrectAnswersPercentage":
                widget.lastThreeIncorrect!.incorrectAnswersPercentage
          });
    super.initState();
  }

  // This will generate the chart data dynamically based on the analysis data
  List<CircularStackEntry> _generateChartData(Map<String, dynamic> topicData) {
    return [
      CircularStackEntry(
        [
          CircularSegmentEntry(
            double.parse(topicData["correctAnswersPercentage"]) ?? 0.0,
            AppTokens.success(context),
            rankKey: 'Correct',
          ),
          CircularSegmentEntry(
            double.parse(topicData["incorrectAnswersPercentage"]) ?? 0.0,
            AppTokens.danger(context),
            rankKey: 'Incorrect',
          ),
        ],
        rankKey: topicData["topicName"],
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    final topicData = analysisData[0];
    final chartData = _generateChartData(topicData);

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          // ---------------------------------------------------
          // Brand gradient header
          // ---------------------------------------------------
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
                        "Graph Analytics",
                        style: AppTokens.overline(context)
                            .copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${topicData['topicName']}",
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
          // ---------------------------------------------------
          // Body
          // ---------------------------------------------------
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
                  AppTokens.s24,
                  AppTokens.s16,
                  AppTokens.s24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTokens.s16),
                      decoration: BoxDecoration(
                        color: AppTokens.surface(context),
                        borderRadius: AppTokens.radius20,
                        border: Border.all(color: AppTokens.border(context)),
                        boxShadow: AppTokens.shadow1(context),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedCircularChart(
                                key: _chartKey,
                                size: const Size(500.0, 300),
                                initialChartData: chartData,
                                holeRadius: 40,
                                chartType: CircularChartType.Radial,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 20),
                                  Text(
                                    "Total Questions",
                                    style: AppTokens.caption(context),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    topicData['totalQuestions'].toString(),
                                    style: AppTokens.displayMd(context),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.s16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildLegendItem(
                                  "Correct (${topicData['correctAnswersPercentage']}%)",
                                  AppTokens.success(context)),
                              _buildLegendItem(
                                  "Incorrect (${topicData['incorrectAnswersPercentage']}%)",
                                  AppTokens.danger(context)),
                            ],
                          ),
                        ],
                      ),
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

  // Legend Builder Method
  Widget _buildLegendItem(String label, Color color) {
    return Builder(builder: (context) {
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
          const SizedBox(width: AppTokens.s8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.caption(context).copyWith(
                color: AppTokens.ink(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    });
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
