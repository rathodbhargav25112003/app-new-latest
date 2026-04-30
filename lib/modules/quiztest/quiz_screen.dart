// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, unused_field, use_build_context_synchronously, unnecessary_null_comparison

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/modules/quiztest/start_quiz_bottom_sheet.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';

/// "Quiz of the Day" landing screen — shows the daily quiz state
/// (countdown-until-live / live-and-ready / live-and-completed /
/// no-quiz-scheduled) over the branded blue gradient hero.
///
/// Preserved public contract:
///   • `QuizScreen({super.key})` constructor + `static route(RouteSettings)`
///     factory returning `CupertinoPageRoute` (arguments read is
///     commented out in the original, preserved here).
///   • `initState()` → `getQuizData()` →
///     `TestCategoryStore.onGetTodayQuizDataApiCall()` followed by
///     `setupTimer(context, store)` if `quizId != null`.
///   • `setupTimer(BuildContext, TestCategoryStore)` preserves the exact
///     arithmetic: parses `getTodayQuizData.value?.dateTime`, if `now`
///     isBefore `startDateTime` uses `startDateTime`, otherwise uses
///     `startDateTime.add(const Duration(days: 1))`; builds a
///     `ValueNotifier<Duration>` and a 1-second periodic Timer that
///     recursively re-invokes `setupTimer` when it hits zero.
///   • `disposeTimer()` cancels timer + disposes notifier (unchanged
///     signature), and `dispose()` mirrors it.
///   • `_getSolutionReport(examId, filter)` calls
///     `ReportsCategoryStore.onQuizSolutionReportApiCall(examId)` and
///     pushes `Routes.quizSolutionReportScreen` with the 3-key args
///     `solutionReport`, `filterVal`, `userExamId`.
///   • Hardware back pushes `Routes.dashboard` and returns `false`.
///   • Top-left back tile pushes `Routes.dashboard`.
///   • Desktop (Windows/macOS) uses `showDialog` → `AlertDialog` wrapping
///     `CustomStartQuizBottomSheet`; mobile uses `showModalBottomSheet`.
///   • Strings preserved byte-for-byte: "Quiz of the Day",
///     "Quiz available in …", "Quiz live until", "Let’s Go",
///     "View Solutions", "Correct", "Incorrect", "Total",
///     "No Quiz Scheduled for Today.\nKindly Visit Later.".
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    // final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => const QuizScreen(),
    );
  }
}

class _QuizScreenState extends State<QuizScreen> {
  Timer? timer;
  Duration? remainingTime;
  late ValueNotifier<Duration> remainingTimeNotifier;
  Duration? duration;

  @override
  void initState() {
    super.initState();
    getQuizData();
  }

  Future<void> getQuizData() async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onGetTodayQuizDataApiCall();
    if (store.getTodayQuizData.value?.quizId != null) {
      setupTimer(context, store);
    }
  }

  void setupTimer(BuildContext context, TestCategoryStore store) {
    DateTime startDateTime =
        DateTime.parse(store.getTodayQuizData.value?.dateTime ?? '');
    DateTime now = DateTime.now();
    DateTime displayTime = now.isBefore(startDateTime)
        ? startDateTime
        : startDateTime.add(const Duration(days: 1));
    Duration remainingTime = displayTime.difference(now);
    remainingTimeNotifier = ValueNotifier<Duration>(remainingTime);

    if (timer != null) {
      timer?.cancel();
    }

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTimeNotifier.value.inSeconds > 0) {
        remainingTimeNotifier.value -= const Duration(seconds: 1);
      } else {
        timer.cancel();
        startDateTime = startDateTime.add(const Duration(days: 1));
        if (remainingTime.inSeconds > 0) {
          setupTimer(context, store);
        }
        setState(() {});
      }
    });
  }

  void disposeTimer() {
    timer?.cancel();
    remainingTimeNotifier.dispose();
  }

  @override
  void dispose() {
    timer?.cancel();
    remainingTimeNotifier.dispose();
    super.dispose();
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

  void _openStartSheet(BuildContext context, TestCategoryStore store) {
    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTokens.surface(context),
            surfaceTintColor: AppTokens.surface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.r20),
            ),
            actionsPadding: EdgeInsets.zero,
            actions: [
              CustomStartQuizBottomSheet(store: store),
            ],
          );
        },
      );
    } else {
      showModalBottomSheet<String>(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.r20),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return CustomStartQuizBottomSheet(store: store);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    final mq = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamed(Routes.dashboard);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        body: Stack(
          children: [
            Container(
              width: mq.width,
              padding: EdgeInsets.only(
                top: mq.height * 0.24,
                left: AppTokens.s24,
                right: AppTokens.s24,
              ),
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
              child: Observer(builder: (context) {
                if (store.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.white),
                  );
                }

                final quiz = store.getTodayQuizData.value;
                final hasQuiz = quiz?.quizId != null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _Hero(title: quiz?.quizName?.toUpperCase() ?? ''),
                    const Spacer(),
                    if (hasQuiz) _buildQuizBody(context, store) else const _NoQuizMessage(),
                    const Spacer(),
                  ],
                );
              }),
            ),
            Positioned(
              left: AppTokens.s20,
              top: mq.height * 0.08,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pushNamed(Routes.dashboard);
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

  Widget _buildQuizBody(BuildContext context, TestCategoryStore store) {
    final quiz = store.getTodayQuizData.value;
    final isCompleted = quiz?.isTodayQuizComplete == true;
    final startDateTime = DateTime.parse(quiz?.dateTime ?? '');
    final beforeStart = DateTime.now().isBefore(startDateTime);

    if (isCompleted) {
      return _CompletedBlock(
        correct: quiz?.correct?.toString() ?? "",
        incorrect: quiz?.incorrect?.toString() ?? "",
        total: quiz?.totalQuestion?.toString() ?? "",
        remainingTimeNotifier: remainingTimeNotifier,
        onViewSolutions: () {
          debugPrint(
              "store.getTodayQuizData.value?.quizUserExamId:${quiz?.quizUserExamId}");
          _getSolutionReport(quiz?.quizUserExamId ?? '', "View all");
        },
      );
    }

    if (beforeStart) {
      return _QuizAvailablePill(remainingTimeNotifier: remainingTimeNotifier);
    }

    return _LiveReadyBlock(
      remainingTimeNotifier: remainingTimeNotifier,
      onStart: () => _openStartSheet(context, store),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset("assets/image/quizCoin.png"),
        const SizedBox(height: AppTokens.s20),
        Text(
          title,
          style: AppTokens.titleSm(context).copyWith(
            fontSize: 22,
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
    );
  }
}

class _QuizAvailablePill extends StatelessWidget {
  const _QuizAvailablePill({required this.remainingTimeNotifier});

  final ValueNotifier<Duration> remainingTimeNotifier;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTokens.s32 + AppTokens.s20,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.white),
      ),
      child: ValueListenableBuilder<Duration>(
        valueListenable: remainingTimeNotifier,
        builder: (context, remainingTime, child) {
          return Text(
            "Quiz available in ${remainingTime.inHours.toString().padLeft(2, '0')}:${remainingTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTime.inSeconds.remainder(60).toString().padLeft(2, '0')}",
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          );
        },
      ),
    );
  }
}

class _LiveReadyBlock extends StatelessWidget {
  const _LiveReadyBlock({
    required this.remainingTimeNotifier,
    required this.onStart,
  });

  final ValueNotifier<Duration> remainingTimeNotifier;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LiveUntilHeader(remainingTimeNotifier: remainingTimeNotifier),
        const SizedBox(height: AppTokens.s20),
        _PrimaryPillButton(
          label: "Let\u2019s Go",
          onTap: onStart,
        ),
      ],
    );
  }
}

class _CompletedBlock extends StatelessWidget {
  const _CompletedBlock({
    required this.correct,
    required this.incorrect,
    required this.total,
    required this.remainingTimeNotifier,
    required this.onViewSolutions,
  });

  final String correct;
  final String incorrect;
  final String total;
  final ValueNotifier<Duration> remainingTimeNotifier;
  final VoidCallback onViewSolutions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LiveUntilHeader(remainingTimeNotifier: remainingTimeNotifier),
        const SizedBox(height: AppTokens.s20),
        _PrimaryPillButton(
          label: "View Solutions",
          onTap: onViewSolutions,
        ),
        const SizedBox(height: AppTokens.s16),
        _StatsStrip(correct: correct, incorrect: incorrect, total: total),
      ],
    );
  }
}

class _LiveUntilHeader extends StatelessWidget {
  const _LiveUntilHeader({required this.remainingTimeNotifier});

  final ValueNotifier<Duration> remainingTimeNotifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Quiz live until",
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w400,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: AppTokens.s8),
        ValueListenableBuilder<Duration>(
          valueListenable: remainingTimeNotifier,
          builder: (context, remainingTime, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TimePart(
                  value: remainingTime.inHours.toString().padLeft(2, '0'),
                  unit: "hrs",
                ),
                const SizedBox(width: AppTokens.s20),
                _TimePart(
                  value: remainingTime.inMinutes
                      .remainder(60)
                      .toString()
                      .padLeft(2, '0'),
                  unit: "mins",
                ),
                const SizedBox(width: AppTokens.s20),
                _TimePart(
                  value: remainingTime.inSeconds
                      .remainder(60)
                      .toString()
                      .padLeft(2, '0'),
                  unit: "secs",
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TimePart extends StatelessWidget {
  const _TimePart({required this.value, required this.unit});

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Text(
      "$value $unit",
      style: AppTokens.titleSm(context).copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      ),
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: AppTokens.s32 + AppTokens.s20,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(100),
          boxShadow: AppTokens.shadow2(context),
        ),
        child: Text(
          label,
          style: AppTokens.body(context).copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.correct,
    required this.incorrect,
    required this.total,
  });

  final String correct;
  final String incorrect;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppTokens.r8),
        border: Border.all(color: AppColors.white, width: 1.11),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: "Correct",
                value: correct,
                color: const Color(0xFF1DC574),
              ),
            ),
            VerticalDivider(color: Colors.white.withOpacity(0.4)),
            Expanded(
              child: _MiniStat(
                label: "Incorrect",
                value: incorrect,
                color: AppColors.redText,
              ),
            ),
            VerticalDivider(color: Colors.white.withOpacity(0.4)),
            Expanded(
              child: _MiniStat(
                label: "Total",
                value: total,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
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
            color: AppColors.black,
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

class _NoQuizMessage extends StatelessWidget {
  const _NoQuizMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s20,
        vertical: AppTokens.s16,
      ),
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTokens.r8),
        border: Border.all(color: AppColors.white, width: 1.11),
      ),
      child: Text(
        "No Quiz Scheduled for Today.\nKindly Visit Later.",
        style: AppTokens.body(context).copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
