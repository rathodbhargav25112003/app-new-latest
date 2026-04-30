// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/models/trend_analysis_model.dart';
import 'package:shusruta_lms/modules/new_exam_component/answer_widget.dart';
import 'package:shusruta_lms/modules/new_exam_component/guess_analytics.dart';
import 'package:shusruta_lms/modules/new_exam_component/mark_analysis.dart';
import 'package:shusruta_lms/modules/new_exam_component/predictive_rank_widget.dart';
import 'package:shusruta_lms/modules/new_exam_component/time_analytics_widget.dart';
import 'package:shusruta_lms/modules/new_exam_component/topic_wise_widget.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/modules/reports/trend_analysis.dart';
import 'package:shusruta_lms/modules/widgets/no_internet_connection.dart';

/// Trend analysis list — tabbed analytics view for an exam's past attempts.
///
/// Preserved public contract:
///   • Constructor `GetTrendAnalysisList({super.key, required this.id})`
///   • `TickerProviderStateMixin` with `TabController(length: 8)`
///   • `store.onCallGetTrendAnalysis(widget.id)` fired in initState
///   • Tab order preserved exactly:
///     1. "NEET SS Predictive Ranking" → TrendPredictiveRankingWidget
///     2. "Marks Analysis"             → TrendMarkWidget
///     3. "Topic Wise Insights"        → TopicWiseTrendWidget
///     4. "Guess Analytics"            → TrendGuessWidget
///     5. "Answer Evolve"              → AnswerAnalysisWidget
///     6. "Time Analysis"              → TrendTimeAnalysisWidget
///     7. "Strength Spotlight"         → TrendStrengthAnalysisWidget
///     8. "Weakness Spotlight"         → TrendWeaknessAnalysisWidget
///   • Empty state copy: "We're sorry, there's no content available right
///     now. Please check back later or explore other sections for more
///     educational resources."
///   • `!store.isConnected` → `NoInternetScreen`.
///   • `buildItem(context, title, image, data, index)` — legacy card
///     builder kept for backward compatibility; taps push
///     `AnalysisOfAllExamScreen(data, title, index)`.
class GetTrendAnalysisList extends StatefulWidget {
  final String id;

  const GetTrendAnalysisList({super.key, required this.id});

  @override
  State<GetTrendAnalysisList> createState() => _GetTrendAnalysisListState();
}

class _GetTrendAnalysisListState extends State<GetTrendAnalysisList>
    with TickerProviderStateMixin {
  String query = '';
  TabController? tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 8, vsync: this);
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    store.onCallGetTrendAnalysis(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          // Gradient hero header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppTokens.s12,
              left: AppTokens.s20,
              right: AppTokens.s20,
              bottom: AppTokens.s20,
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
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                  child: Container(
                    height: AppTokens.s32,
                    width: AppTokens.s32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
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
                    "Analysis Types",
                    style: AppTokens.titleSm(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
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
              child: Observer(
                builder: (_) {
                  if (store.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTokens.accent(context),
                      ),
                    );
                  }
                  if (store.trendList.value!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.s24,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.insights_rounded,
                              size: 56,
                              color: AppTokens.muted(context),
                            ),
                            const SizedBox(height: AppTokens.s16),
                            Text(
                              "We're sorry, there's no content available right now. Please check back later or explore other sections for more educational resources.",
                              style: AppTokens.body(context).copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppTokens.ink(context),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (!store.isConnected) return const NoInternetScreen();

                  return Column(
                    children: [
                      const SizedBox(height: AppTokens.s8),
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s16,
                        ),
                        decoration: BoxDecoration(
                          color: AppTokens.surface(context),
                          borderRadius: BorderRadius.circular(AppTokens.r12),
                          border: Border.all(color: AppTokens.border(context)),
                        ),
                        child: TabBar(
                          isScrollable: true,
                          controller: tabController,
                          labelColor: AppTokens.accent(context),
                          unselectedLabelColor: AppTokens.muted(context),
                          indicatorColor: AppTokens.accent(context),
                          indicatorSize: TabBarIndicatorSize.label,
                          dividerColor: Colors.transparent,
                          labelStyle: AppTokens.caption(context).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle: AppTokens.caption(context)
                              .copyWith(fontWeight: FontWeight.w500),
                          tabs: const [
                            Tab(text: "NEET SS Predictive Ranking"),
                            Tab(text: "Marks Analysis"),
                            Tab(text: "Topic Wise Insights"),
                            Tab(text: "Guess Analytics"),
                            Tab(text: "Answer Evolve"),
                            Tab(text: "Time Analysis"),
                            Tab(text: "Strength Spotlight"),
                            Tab(text: "Weakness Spotlight"),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTokens.s8),
                      Expanded(
                        child: TabBarView(
                          controller: tabController,
                          children: [
                            SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  TrendPredictiveRankingWidget(
                                    trendAnalysisModel: store.trendList.value!,
                                    score: store.score,
                                  ),
                                ],
                              ),
                            ),
                            SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  TrendMarkWidget(
                                    trendAnalysisModel: store.trendList.value!,
                                  ),
                                ],
                              ),
                            ),
                            SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  TopicWiseTrendWidget(
                                    trendAnalysisModel: store.trendList.value!,
                                  ),
                                ],
                              ),
                            ),
                            SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  TrendGuessWidget(
                                    trendAnalysisModel: store.trendList.value!,
                                  ),
                                ],
                              ),
                            ),
                            SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  AnswerAnalysisWidget(
                                    trendAnalysisModel: store.trendList.value!,
                                  ),
                                ],
                              ),
                            ),
                            SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  TrendTimeAnalysisWidget(
                                    trendAnalysisModel: store.trendList.value!,
                                  ),
                                ],
                              ),
                            ),
                            SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  TrendStrengthAnalysisWidget(
                                    trendAnalysisModel: store.trendList.value!,
                                  ),
                                ],
                              ),
                            ),
                            SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  TrendWeaknessAnalysisWidget(
                                    trendAnalysisModel: store.trendList.value!,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTokens.s16),
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

  /// Legacy card builder — retained verbatim signature for any
  /// external callers; wraps a titled card that navigates to
  /// `AnalysisOfAllExamScreen`.
  Widget buildItem(BuildContext context, String title, String image,
      List<TrendAnalysisModel> data, int index) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.r12),
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => AnalysisOfAllExamScreen(
              data: data,
              title: title,
              index: index,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTokens.s12),
        padding: const EdgeInsets.all(AppTokens.s16),
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: Border.all(color: AppTokens.border(context)),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              padding: const EdgeInsets.all(AppTokens.s8),
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                borderRadius: BorderRadius.circular(AppTokens.r12),
              ),
              child: Image.asset(image, fit: BoxFit.contain),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Text(
                title,
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTokens.ink(context),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTokens.muted(context),
            ),
          ],
        ),
      ),
    );
  }
}
