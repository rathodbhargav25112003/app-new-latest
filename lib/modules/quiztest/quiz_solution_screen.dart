// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, unnecessary_null_comparison, unused_field, unused_local_variable, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/modules/quiztest/model/quiz_report_by_category_model.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';

/// Quiz "Quiz Of The Day" result summary screen — shows My Marks, My
/// Percentage, and Correct / Incorrect / Total stat strip with a
/// "Solutions" CTA that routes into the per-question solution report.
///
/// Preserved public contract:
///   • Named constructor
///     `QuizSolutionScreen({super.key, required this.title, this.reports,
///     required this.userexamId, required this.examId})`.
///   • `static Route<dynamic> route(RouteSettings)` reads arg map keys
///     `title`, `report`, `userexamId`, `examId` and returns a
///     `CupertinoPageRoute`.
///   • `initState()` calls `getMeritList()` →
///     `ReportsCategoryStore.onMeritListApiCall(widget.examId ?? "")`.
///   • `_getSolutionReport(examId, filter)` calls
///     `ReportsCategoryStore.onQuizSolutionReportApiCall(examId)` then
///     pushes `Routes.quizSolutionReportScreen` with keys
///     `solutionReport`, `filterVal`, `userExamId`.
///   • `roundAndFormatDouble(String)` helper preserved.
///   • Back-hardware override pushes `Routes.reportsCategoryList` and
///     returns `false`.
///   • Top-left back arrow uses `pushNamedAndRemoveUntil` to
///     `Routes.quizScreen`.
///   • Label strings preserved byte-for-byte: 'Quiz of the Day',
///     'My Marks', 'My Percentage', 'Correct', 'Incorrect', 'Total',
///     'Solutions'.
class QuizSolutionScreen extends StatefulWidget {
  final String title;
  final QuizReportByCategoryModel? reports;
  final String userexamId;
  final String examId;
  const QuizSolutionScreen({
    super.key,
    required this.title,
    this.reports,
    required this.userexamId,
    required this.examId,
  });

  @override
  State<QuizSolutionScreen> createState() => _QuizSolutionScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => QuizSolutionScreen(
        title: arguments['title'],
        reports: arguments['report'],
        userexamId: arguments['userexamId'],
        examId: arguments['examId'],
      ),
    );
  }
}

class _QuizSolutionScreenState extends State<QuizSolutionScreen> {
  @override
  void initState() {
    super.initState();
    getMeritList();
  }

  Future<void> _getSolutionReport(String examId, String filter) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onQuizSolutionReportApiCall(examId).then((_) {
      Navigator.of(context).pushNamed(
        Routes.quizSolutionReportScreen,
        arguments: {
          'solutionReport': store.quizSolutionReportCategory,
          'filterVal': filter,
          'userExamId': examId,
        },
      );
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
    final mq = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamed(Routes.reportsCategoryList);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        body: Stack(
          children: [
            Container(
              width: mq.width,
              padding: EdgeInsets.only(top: mq.height * 0.16),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/image/quizBackground.png"),
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF00369D),
                    Color(0xFF308FFF),
                  ],
                ),
              ),
              child: Column(
                children: [
                  _Hero(title: widget.title),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(
                        left: AppTokens.s20,
                        right: AppTokens.s20,
                        top: AppTokens.s24,
                      ),
                      decoration: BoxDecoration(
                        color: AppTokens.scaffold(context),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppTokens.r28),
                          topRight: Radius.circular(AppTokens.r28),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _StatsCard(reports: widget.reports),
                            const SizedBox(height: AppTokens.s20),
                            _SolutionsButton(
                              onTap: () {
                                _getSolutionReport(
                                    widget.userexamId, "View all");
                              },
                            ),
                            const SizedBox(height: AppTokens.s20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: AppTokens.s20,
              top: mq.height * 0.08,
              child: InkWell(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    Routes.quizScreen,
                    (route) => false,
                  );
                },
                borderRadius: BorderRadius.circular(AppTokens.r12),
                child: Container(
                  height: AppTokens.s32 + AppTokens.s8,
                  width: AppTokens.s32 + AppTokens.s8,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: SvgPicture.asset("assets/image/quizback.svg"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTokens.s24,
        right: AppTokens.s24,
        bottom: AppTokens.s32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset("assets/image/quizCoin.png"),
          const SizedBox(height: AppTokens.s20),
          Text(
            title.toUpperCase(),
            style: AppTokens.titleSm(context).copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTokens.s4),
          Text(
            "Quiz of the Day",
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.reports});

  final QuizReportByCategoryModel? reports;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: AppTokens.shadow1(context),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppTokens.s16),
          _StatRow(
            asset: "assets/image/myMark.png",
            label: "My Marks",
            value: "${reports?.myScore}/${reports?.totalMarks.toString()}",
          ),
          const SizedBox(height: AppTokens.s12),
          Divider(color: AppTokens.border(context), height: 0),
          const SizedBox(height: AppTokens.s12),
          _StatRow(
            asset: "assets/image/myPercantage.png",
            label: "My Percentage",
            value: "${reports?.percentage}%",
          ),
          const SizedBox(height: AppTokens.s12),
          Divider(color: AppTokens.border(context), height: 0),
          const SizedBox(height: AppTokens.s12),
          _TripleStatRow(
            asset: "assets/image/quiztotal.png",
            correct: reports?.correctAnswers.toString() ?? '',
            incorrect: reports?.incorrectAnswers.toString() ?? '',
            total: reports?.questionCount.toString() ?? '',
          ),
          const SizedBox(height: AppTokens.s16),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.asset,
    required this.label,
    required this.value,
  });

  final String asset;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTokens.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(asset, width: 40, height: 40, fit: BoxFit.contain),
          const SizedBox(width: AppTokens.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTokens.caption(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppTokens.muted(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTokens.titleSm(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTokens.ink(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripleStatRow extends StatelessWidget {
  const _TripleStatRow({
    required this.asset,
    required this.correct,
    required this.incorrect,
    required this.total,
  });

  final String asset;
  final String correct;
  final String incorrect;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: AppTokens.s12),
        Image.asset(asset, width: 40, height: 40, fit: BoxFit.contain),
        Expanded(
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _MiniStat(
                    label: "Correct",
                    value: correct,
                    color: AppTokens.success(context),
                  ),
                ),
                VerticalDivider(color: AppTokens.border(context)),
                Expanded(
                  child: _MiniStat(
                    label: "Incorrect",
                    value: incorrect,
                    color: AppTokens.danger(context),
                  ),
                ),
                VerticalDivider(color: AppTokens.border(context)),
                Expanded(
                  child: _MiniStat(
                    label: "Total",
                    value: total,
                    color: AppTokens.ink(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTokens.caption(context).copyWith(
            fontWeight: FontWeight.w500,
            color: AppTokens.muted(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTokens.titleSm(context).copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SolutionsButton extends StatelessWidget {
  const _SolutionsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: Container(
        height: AppTokens.s32 + AppTokens.s20,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTokens.brand, AppTokens.brand2],
          ),
          borderRadius: BorderRadius.circular(AppTokens.r12),
          boxShadow: AppTokens.shadow2(context),
        ),
        child: Text(
          'Solutions',
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
