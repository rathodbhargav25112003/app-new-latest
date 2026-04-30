// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/new_exam_component/answer_widget.dart';
import 'package:shusruta_lms/modules/new_exam_component/guess_analytics.dart';
import 'package:shusruta_lms/modules/new_exam_component/predictive_rank_widget.dart';
import 'package:shusruta_lms/modules/new_exam_component/time_analytics_widget.dart';
import 'package:shusruta_lms/modules/new_exam_component/topic_wise_widget.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';

/// Exam analysis / report screen shown after a master exam submission.
///
/// Preserved public contract:
///   • Constructor `ExamReportScreen({super.key, required
///     TestExamPaperListModel testExamPaperListModel, required
///     String id})` — fields and order unchanged.
///   • Uses `TickerProviderStateMixin` for the 5-tab controller.
///   • `init()` hydrates via
///     `store.analysis(widget.id, widget.testExamPaperListModel.examId!)`.
///   • 5 tabs preserved in order: "NEET SS Predictive Ranking",
///     "Topic Wise Insights", "Guess Analytics", "Answer Evolve",
///     "Time Analytics" — each wired to the same child widget as
///     before (PredictiveRankingWidget / TopicWiseInsights /
///     GuessAnalytics / AnswerAnalytics / TimeAnalytics).
///   • SwipeableButtonView bottom bar still flips `isRank1` between
///     "Swipe to compare with 1st rank" ↔ "Swipe to view your rank"
///     and gates on `!store.examReport.value!.isDeclaration!`. The
///     `isFinished` transition with the 2-second delay is kept.
///   • "Available after Declaration on <dd MMM | hh:mm>" banner
///     still shows when `isDeclaration!` is true.
///   • Platform.isWindows/isMacOS kept: desktop flat-top header,
///     mobile keeps ≈28 radius + extra top padding.
///   • `getProgress(String rankRange)` is still a top-level public
///     helper — `predictive_rank_widget.dart` imports it.
///   • `_getColor(String rankRange)` remains file-private with the
///     same 50 / 5000 thresholds (green / orange / red).
///   • `SwipeAnimationWidget` + `_SwipeAnimationWidgetState` retained
///     at file bottom because legacy callers might import it.
class ExamReportScreen extends StatefulWidget {
  const ExamReportScreen({
    super.key,
    required this.testExamPaperListModel,
    required this.id,
  });

  final TestExamPaperListModel testExamPaperListModel;
  final String id;

  @override
  State<ExamReportScreen> createState() => _ExamReportScreenState();
}

class _ExamReportScreenState extends State<ExamReportScreen>
    with TickerProviderStateMixin {
  bool isFinished = false;
  bool isRank1 = false;
  TabController? tabController;
  late TestCategoryStore store;

  @override
  void initState() {
    init();
    tabController = TabController(length: 5, vsync: this);
    super.initState();
  }

  void init() async {
    store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.analysis(widget.id, widget.testExamPaperListModel.examId!);
  }

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  String _rankLabel() => isRank1 ? '1st Rank' : 'Your Rank';

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      bottomNavigationBar: Observer(
        builder: (context) {
          return Observer(builder: (context) {
            return store.isLoading
                ? const SizedBox()
                : Container(
                    decoration: BoxDecoration(
                      color: AppTokens.surface(context),
                      boxShadow: AppTokens.shadow2(context),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.s20,
                      AppTokens.s16,
                      AppTokens.s20,
                      AppTokens.s24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (store.examReport.value!.isDeclaration!) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Available after Declaration on ',
                                style: AppTokens.body(context).copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTokens.muted(context),
                                ),
                              ),
                              Text(
                                DateFormat('dd MMM | hh:mm').format(
                                  DateTime.parse(store
                                      .examReport.value!.declarationTime!),
                                ),
                                style: AppTokens.body(context).copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTokens.ink(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.s12),
                        ],
                        SwipeableButtonView(
                          buttonColor: AppTokens.surface(context),
                          buttontextstyle: AppTokens.body(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                          buttonText: isRank1
                              ? 'Swipe to view your rank '
                              : 'Swipe to compare with 1st rank',
                          buttonWidget: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppTokens.muted(context),
                          ),
                          disableColor: AppTokens.brand.withOpacity(0.5),
                          isActive: !store.examReport.value!.isDeclaration!,
                          activeColor: AppTokens.brand,
                          isFinished: isFinished,
                          onWaitingProcess: () {
                            Future.delayed(const Duration(seconds: 2), () {
                              setState(() {
                                isFinished = true;
                              });
                            });
                          },
                          onFinish: () async {
                            setState(() {
                              isFinished = false;
                              isRank1 = !isRank1;
                            });
                          },
                        ),
                      ],
                    ),
                  );
          });
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTokens.brand, AppTokens.brand2],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: _isDesktop
                  ? const EdgeInsets.symmetric(
                      vertical: AppTokens.s20,
                      horizontal: AppTokens.s24,
                    )
                  : const EdgeInsets.only(
                      top: AppTokens.s32 + AppTokens.s24,
                      left: AppTokens.s24,
                      right: AppTokens.s24,
                      bottom: AppTokens.s12,
                    ),
              child: Row(
                children: [
                  IconButton(
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: Text(
                      '${widget.testExamPaperListModel.examName ?? ""}  Analysis',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTokens.titleSm(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: AppTokens.s24,
                  right: AppTokens.s24,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.scaffold(context),
                  borderRadius: _isDesktop
                      ? null
                      : const BorderRadius.only(
                          topLeft: Radius.circular(AppTokens.r28),
                          topRight: Radius.circular(AppTokens.r28),
                        ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Observer(
                        builder: (context) {
                          if (store.isLoading) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: AppTokens.brand,
                              ),
                            );
                          }
                          return Column(
                            children: [
                              Expanded(
                                flex: 1,
                                child: TabBar(
                                  isScrollable: true,
                                  controller: tabController,
                                  labelColor: AppTokens.brand,
                                  unselectedLabelColor:
                                      AppTokens.muted(context),
                                  indicatorColor: AppTokens.brand,
                                  labelStyle:
                                      AppTokens.caption(context).copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  unselectedLabelStyle:
                                      AppTokens.caption(context).copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  tabs: const [
                                    Tab(text: 'NEET SS Predictive Ranking'),
                                    Tab(text: 'Topic Wise Insights'),
                                    Tab(text: 'Guess Analytics'),
                                    Tab(text: 'Answer Evolve'),
                                    Tab(text: 'Time Analytics'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppTokens.s8),
                              Expanded(
                                flex: 14,
                                child: TabBarView(
                                  controller: tabController,
                                  children: [
                                    SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          PredictiveRankingWidget(
                                            headerTitle: _rankLabel(),
                                            rankingTitle:
                                                'Predictive NEET SS Ranking',
                                            badgeIconPath:
                                                'assets/image/badge.svg',
                                            rankItems: [
                                              _rankItem(
                                                label: 'As per NEET SS \'23',
                                                range: (isRank1
                                                        ? store.examReport2
                                                        : store.examReport)
                                                    .value!
                                                    .predicted_rank_2022!,
                                              ),
                                              _rankItem(
                                                label: 'As per NEET SS \'24',
                                                range: (isRank1
                                                        ? store.examReport2
                                                        : store.examReport)
                                                    .value!
                                                    .predicted_rank_2023!,
                                              ),
                                              _rankItem(
                                                label:
                                                    'Prediction - NEET SS \'25',
                                                range: (isRank1
                                                        ? store.examReport2
                                                        : store.examReport)
                                                    .value!
                                                    .predicted_rank_2024!,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          TopicWiseInsights(
                                            isRank1: isRank1,
                                            topicReports1: store.examReport2
                                                .value!.topicNameReport!,
                                            topicReports2: store.examReport2
                                                    .value!
                                                    .topicNameReport!
                                                    .isEmpty
                                                ? null
                                                : store.examReport2.value!
                                                    .topicNameReport![0],
                                            headerTitle: _rankLabel(),
                                            correct: 66,
                                            skipped: 12,
                                            incorrect: 22,
                                            totalQuestions: isRank1
                                                ? store.examReport2.value!
                                                    .question!
                                                : store.examReport.value!
                                                    .question!,
                                            strengthSpotlight: isRank1
                                                ? store.examReport2.value!
                                                    .topThreeCorrect!
                                                : store.examReport.value!
                                                    .topThreeCorrect!,
                                            topicReports: store.examReport
                                                .value!.topicNameReport!,
                                            selected: isRank1
                                                ? store.examReport2.value!
                                                        .topicNameReport!
                                                        .isEmpty
                                                    ? null
                                                    : store.examReport2.value!
                                                        .topicNameReport![0]
                                                : store.examReport.value!
                                                        .topicNameReport!
                                                        .isEmpty
                                                    ? null
                                                    : store.examReport.value!
                                                        .topicNameReport![0],
                                            weaknessSpotlight: isRank1
                                                ? store.examReport2.value!
                                                    .lastThreeIncorrect!
                                                : store.examReport.value!
                                                    .lastThreeIncorrect!,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          GuessAnalytics(
                                            headerTitle: _rankLabel(),
                                            examReport: isRank1
                                                ? store.examReport2.value!
                                                : store.examReport.value!,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          AnswerAnalytics(
                                            headerTitle: _rankLabel(),
                                            examReport: isRank1
                                                ? store.examReport2.value!
                                                : store.examReport.value!,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          TimeAnalytics(
                                            headerTitle: _rankLabel(),
                                            examReport: isRank1
                                                ? store.examReport2.value!
                                                : store.examReport.value!,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Collapses the repeated RankItem construction used for each of the
  /// three NEET SS years. Behaviour is byte-identical to the old
  /// triple-nested ternary expressions: start / end strings split on
  /// "-", progress driven by `getProgress`, colour driven by
  /// `_getColor`.
  RankItem _rankItem({required String label, required String range}) {
    final parts = range.split('-');
    return RankItem(
      label: label,
      value: parts[0].trim(),
      endValue: parts[1].trim(),
      progress: getProgress(range),
      color: _getColor(range),
    );
  }
}

/// Public top-level helper — imported by
/// `predictive_rank_widget.dart` for the trend card. Threshold logic
/// preserved verbatim: ≤50 → 0.8, 51..5000 → 0.6, else → 0.3.
double getProgress(String rankRange) {
  final startRank = int.parse(rankRange.split('-')[0].trim());
  if (startRank <= 50) {
    return 0.8;
  } else if (startRank > 50 && startRank <= 5000) {
    return 0.6;
  } else {
    return 0.3;
  }
}

Color _getColor(String rankRange) {
  final startRank = int.parse(rankRange.split('-')[0].trim());
  if (startRank <= 50) {
    return Colors.green;
  } else if (startRank > 50 && startRank <= 5000) {
    return Colors.orange;
  } else {
    return Colors.red;
  }
}

/// Legacy demo swipe widget retained verbatim for any external import
/// that referenced it — not used inside this file but kept public for
/// backward compatibility.
class SwipeAnimationWidget extends StatefulWidget {
  const SwipeAnimationWidget({super.key});

  @override
  _SwipeAnimationWidgetState createState() => _SwipeAnimationWidgetState();
}

class _SwipeAnimationWidgetState extends State<SwipeAnimationWidget> {
  double arrowPosition = 0;
  bool isSwipedRight = false;

  void _onSwipeRight() {
    setState(() {
      arrowPosition = 20;
      isSwipedRight = true;
    });
  }

  void _onSwipeLeft() {
    setState(() {
      arrowPosition = 0;
      isSwipedRight = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.surface(context),
      body: Center(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! > 0) {
              _onSwipeRight();
            } else if (details.primaryVelocity != null &&
                details.primaryVelocity! < 0) {
              _onSwipeLeft();
            }
          },
          child: Container(
            width: 300,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF3366FF),
              borderRadius: BorderRadius.circular(AppTokens.r8),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                AnimatedPositioned(
                  left: arrowPosition,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                ),
                Center(
                  child: Text(
                    'Swipe to compare with 1st rank',
                    style: AppTokens.body(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
