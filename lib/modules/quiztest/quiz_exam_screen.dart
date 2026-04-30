// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, avoid_print, use_build_context_synchronously, unused_field, dead_code, unused_local_variable, dead_null_aware_expression

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/models/exam_paper_data_model.dart';
import 'package:shusruta_lms/modules/quiztest/model/quiz_model.dart';
import 'package:shusruta_lms/modules/quiztest/quiz_custom_test_cancel_dialogbox.dart';
import 'package:shusruta_lms/modules/quiztest/quiz_question_pallet.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/widgets/bottom_toast.dart';

/// Core quiz-of-the-day question-answering screen — runs the timer,
/// serves one question at a time with options + images, drives the
/// "Mark for review" / "Guess" state toggles, and on completion shows
/// the submission sheet and routes to the solution summary.
///
/// Preserved public contract:
///   • 8-field constructor
///     `QuizTestExamScreen({super.key, this.fromPallete, this.testExamPaper,
///       this.userExamId, this.isPracticeExam, this.queNo, this.remainingTime,
///       this.id, this.type})`.
///   • `static route(RouteSettings)` reads `testData`, `userexamId`,
///     `queNo`, `isPracticeExam`, `remainingTime`, `id`, `type`,
///     `fromPallete` from the arg map.
///   • All MobX store calls preserved byte-for-byte:
///     `TestCategoryStore.quizAnswerTest(context, userExamId, questionId,
///     selectedOption, isAttempted, isAttemptedAndMarkedForReview,
///     isSkipped, isMarkedForReview, guess, time)` (9-arg call),
///     `questionAnswerByIdQuiz(userExamId, queId)`,
///     `getQuizQuestionPalleteCount(userExamId)`,
///     `onReportQuizExamApiCall(userExamId)`.
///   • Submission sheet posts `Routes.quizSolutionScreen` with the 4-key
///     arg map `{report, title, userexamId, examId}`.
///   • Drawer hosts `QuizQuestionPallet(testExamPaper, userExamId,
///     remainingTimeNotifier, isPracticeExam, timer)` — 5-positional
///     constructor preserved from quiz_question_pallet.dart.
///   • Back-button behaviour: if not on first question → previous;
///     otherwise → `CustomQuizTestCancelDialogBox`.
///   • Label strings preserved verbatim: "Your Exam Time is Up!",
///     "Test Submission", "Time Left", "Attempted", "Marked for Review",
///     "Attempted and Marked for Review", "Skipped", "Guess",
///     "Not Visited", "Are you sure you want to submit the test?",
///     "Cancel", "Submit", "Mark for review", "Please Select Option",
///     "Tap the image to zoom In/Out", "No filtered data available".
class QuizTestExamScreen extends StatefulWidget {
  final QuizModel? testExamPaper;
  final String? userExamId;
  final int? queNo;
  final bool? isPracticeExam;
  final ValueNotifier<Duration>? remainingTime;
  final String? id;
  final String? type;
  final bool? fromPallete;
  const QuizTestExamScreen({
    super.key,
    this.fromPallete,
    this.testExamPaper,
    this.userExamId,
    this.isPracticeExam,
    this.queNo,
    this.remainingTime,
    this.id,
    this.type,
  });

  @override
  State<QuizTestExamScreen> createState() => _QuizTestExamScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => QuizTestExamScreen(
        testExamPaper: arguments['testData'],
        userExamId: arguments['userexamId'],
        queNo: arguments['queNo'],
        isPracticeExam: arguments['isPracticeExam'],
        remainingTime: arguments['remainingTime'],
        id: arguments['id'],
        type: arguments['type'],
        fromPallete: arguments['fromPallete'],
      ),
    );
  }
}

class _QuizTestExamScreenState extends State<QuizTestExamScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? timer;
  Duration? remainingTime;
  late ValueNotifier<Duration> remainingTimeNotifier;
  int _selectedIndex = -1;
  int _currentQuestionIndex = 0;
  bool isLastQues = false, firstQue = true;
  bool isAttempted = false;
  bool isGuess = false;
  bool isMarkedForReview = false;
  bool isAttemptedAndMarkedForReview = false;
  bool isSkipped = false;
  Uint8List? answerImgBytes;
  Uint8List? quesImgBytes;
  Duration? duration;
  String? usedExamTime;
  Widget? questionWidget;
  bool guessed = false;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    updateTimer();
    int matchingIndex = widget.testExamPaper?.test
            ?.indexWhere((e) => e.questionNumber == widget.queNo) ??
        -1;
    if (matchingIndex != -1) {
      String? matchingQueId = widget.testExamPaper?.test?[matchingIndex].sId;
      _getSelectedAnswer(matchingQueId!);
      _currentQuestionIndex = matchingIndex;
      setState(() {
        firstQue = false;
      });

      if (_currentQuestionIndex >=
          (widget.testExamPaper?.test?.length ?? 0) - 1) {
        isLastQues = true;
      } else {
        isLastQues = false;
      }
    }
  }

  void updateTimer() {
    if (widget.testExamPaper?.timeDuration != null &&
        widget.fromPallete != true) {
      List<String>? timeParts = widget.testExamPaper?.timeDuration?.split(":");
      duration = Duration(
        hours: int.parse(timeParts![0]),
        minutes: int.parse(timeParts[1]),
        seconds: int.parse(timeParts[2]),
      );
      remainingTime = duration;
      remainingTimeNotifier = ValueNotifier<Duration>(remainingTime!);
    } else {
      List<String>? timeParts = widget.testExamPaper?.timeDuration?.split(":");
      duration = Duration(
        hours: int.parse(timeParts![0]),
        minutes: int.parse(timeParts[1]),
        seconds: int.parse(timeParts[2]),
      );
      remainingTime = widget.remainingTime?.value;
      remainingTimeNotifier = ValueNotifier<Duration>(remainingTime!);
    }

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTimeNotifier.value.inSeconds > 0) {
        remainingTimeNotifier.value =
            remainingTimeNotifier.value - const Duration(seconds: 1);
      } else {
        timer.cancel();
        remainingTimeNotifier.dispose();
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: "Your Exam Time is Up!",
          backgroundColor: Theme.of(context).primaryColor,
        );
        _getCount2(widget.userExamId);
      }
    });
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lifecycle handling intentionally left as a no-op (byte-for-byte
    // preserved from original implementation).
  }

  @override
  void dispose() {
    timer?.cancel();
    remainingTimeNotifier.dispose();
    super.dispose();
  }

  Future<void> _postSelectedAnswerApiCall(
    String? userExamId,
    String? selectedOption,
    String? questionId,
    bool isAttempted,
    bool isAttemptedAndMarkedForReview,
    bool isSkipped,
    bool isMarkedForReview,
    String guess,
    String time,
  ) async {
    debugPrint("timeQues$time");
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.quizAnswerTest(
      context,
      userExamId ?? "",
      questionId ?? "",
      selectedOption ?? "",
      isAttempted,
      isAttemptedAndMarkedForReview,
      isSkipped,
      isMarkedForReview,
      guess,
      time,
    );
  }

  Future<void> _getSelectedAnswer(String queId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.questionAnswerByIdQuiz(widget.userExamId ?? "", queId);
    setState(() {
      String? nextOption =
          (store.quizAnswerExam.value?.guess?.isNotEmpty ?? false)
              ? store.quizAnswerExam.value?.guess
              : store.quizAnswerExam.value?.selectedOption;
      _selectedIndex = widget
              .testExamPaper?.test?[_currentQuestionIndex].optionsData
              ?.indexWhere((option) => option.value == nextOption) ??
          -1;
      guessed =
          (store.quizAnswerExam.value?.guess?.isEmpty ?? false) ? false : true;
      print("guessed answer $guessed");
      isGuess = (store.quizAnswerExam.value?.guess?.isNotEmpty ?? false)
          ? true
          : false;
      isMarkedForReview = store.quizAnswerExam.value?.markedForReview ?? false;
      isAttemptedAndMarkedForReview =
          store.quizAnswerExam.value?.attemptedMarkedForReview ?? false;
    });
  }

  Future<void> _getCount(String? userExamId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.getQuizQuestionPalleteCount(userExamId ?? "").then((_) {
      openBottomSheet(store);
    });
  }

  Future<void> _getCount2(String? userExamId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.getQuizQuestionPalleteCount(userExamId ?? "").then((_) {
      openBottomSheet2(store);
    });
  }

  Future<void> _generateReport(String? userExamId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onReportQuizExamApiCall(widget.userExamId ?? "").then((_) {
      Navigator.of(context).pushNamed(
        Routes.quizSolutionScreen,
        arguments: {
          'report': store.reportsQuizExam.value,
          'title': widget.testExamPaper?.quizName,
          'userexamId': userExamId,
          'examId': widget.testExamPaper?.quizId,
        },
      );
    });
  }

  _PalleteCounts _readCounts(TestCategoryStore store) {
    String padded(Object? v) => (v?.toString().padLeft(2, '0')) ?? "0";
    final c = store.quizTestQuePalleteCount.value;
    return _PalleteCounts(
      attempted: padded(c?.isAttempted),
      markedForReview: padded(c?.isMarkedForReview),
      skipped: padded(c?.isSkipped),
      attemptedAndMarkedForReview: padded(c?.isAttemptedMarkedForReview),
      notVisited: padded(c?.notVisited),
      guess: padded(c?.isGuess),
    );
  }

  void openBottomSheet(TestCategoryStore store) {
    showModalBottomSheet<void>(
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppTokens.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.r20),
        ),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      context: context,
      builder: (BuildContext context) {
        final counts = _readCounts(store);
        return Container(
          color: AppTokens.surface(context),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s24),
            child: Column(
              children: [
                Text(
                  "Test Submission",
                  style: AppTokens.titleSm(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s20),
                Expanded(
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppTokens.s8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Time Left",
                                  style: AppTokens.body(context).copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTokens.ink(context),
                                  ),
                                ),
                                Text(
                                  _fmtHMS(remainingTimeNotifier.value),
                                  style: AppTokens.body(context).copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.redText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTokens.s12),
                            _LegendCountRow(
                                color: Colors.green,
                                label: "Attempted",
                                count: counts.attempted),
                            _LegendCountRow(
                                color: Colors.blue,
                                label: "Marked for Review",
                                count: counts.markedForReview),
                            _LegendCountRow(
                                color: Colors.orange,
                                label: "Attempted and Marked for Review",
                                count: counts.attemptedAndMarkedForReview),
                            _LegendCountRow(
                                color: Colors.red,
                                label: "Skipped",
                                count: counts.skipped),
                            _LegendCountRow(
                                color: Colors.brown,
                                label: "Guess",
                                count: counts.guess),
                            _LegendCountRow(
                                color: AppTokens.ink(context),
                                label: "Not Visited",
                                count: counts.notVisited),
                            const SizedBox(height: AppTokens.s20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s24),
                  child: Text(
                    "Are you sure you want to submit the test?",
                    style: AppTokens.titleSm(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTokens.ink(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SheetButton(
                          label: "Cancel",
                          outlined: true,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s12),
                      Expanded(
                        child: _SheetButton(
                          label: "Submit",
                          outlined: false,
                          onTap: () async {
                            if (await Vibration.hasVibrator() ?? false) {
                              Vibration.vibrate();
                            }
                            timer?.cancel();
                            _generateReport(widget.userExamId);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void openBottomSheet2(TestCategoryStore store) {
    showModalBottomSheet<void>(
      isScrollControlled: false,
      isDismissible: false,
      backgroundColor: AppTokens.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.r20),
        ),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      context: context,
      builder: (BuildContext context) {
        final counts = _readCounts(store);
        return Container(
          color: AppTokens.surface(context),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s24),
            child: Column(
              children: [
                Text(
                  "Test Submission",
                  style: AppTokens.titleSm(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s20),
                Expanded(
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppTokens.s8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _LegendCountRow(
                                color: Colors.green,
                                label: "Attempted",
                                count: counts.attempted),
                            _LegendCountRow(
                                color: Colors.blue,
                                label: "Marked for Review",
                                count: counts.markedForReview),
                            _LegendCountRow(
                                color: Colors.orange,
                                label: "Attempted and Marked for Review",
                                count: counts.attemptedAndMarkedForReview),
                            _LegendCountRow(
                                color: Colors.red,
                                label: "Skipped",
                                count: counts.skipped),
                            _LegendCountRow(
                                color: Colors.brown,
                                label: "Guess",
                                count: counts.guess),
                            _LegendCountRow(
                                color: AppTokens.ink(context),
                                label: "Not Visited",
                                count: counts.notVisited),
                            const SizedBox(height: AppTokens.s20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SheetButton(
                          label: "Submit",
                          outlined: false,
                          onTap: () {
                            timer?.cancel();
                            _generateReport(widget.userExamId);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showNextQuestion() async {
    firstQue = false;
    guessed = false;
    String? questionId = widget.testExamPaper?.test?[_currentQuestionIndex].sId;

    String? selectedOption = _selectedIndex == -1
        ? ""
        : widget.testExamPaper?.test?[_currentQuestionIndex]
            .optionsData?[_selectedIndex].value;
    if (selectedOption == "" && !isMarkedForReview) {
      isSkipped = true;
      isAttempted = false;
      isAttemptedAndMarkedForReview = false;
      isMarkedForReview = false;
      isGuess = false;
    } else if (selectedOption != "" && isAttemptedAndMarkedForReview) {
      isAttemptedAndMarkedForReview = true;
      isSkipped = false;
      isAttempted = false;
      isMarkedForReview = false;
      isGuess = false;
    } else if (selectedOption == "" && isMarkedForReview) {
      isMarkedForReview = true;
      isAttemptedAndMarkedForReview = false;
      isSkipped = false;
      isAttempted = false;
      isGuess = false;
    } else if (selectedOption != "" && isGuess) {
      isMarkedForReview = false;
      isAttemptedAndMarkedForReview = false;
      isSkipped = false;
      isAttempted = false;
      isGuess = true;
    } else if (selectedOption != "") {
      isAttempted = true;
      isAttemptedAndMarkedForReview = false;
      isSkipped = false;
      isMarkedForReview = false;
      isGuess = false;
    }

    if (duration != null) {
      Duration timeDifference = duration! - remainingTimeNotifier.value;
      usedExamTime = _fmtHMS(timeDifference);
      debugPrint('usedtime $usedExamTime');
    } else {
      debugPrint('Duration values are null.');
    }
    if (isGuess == true) {
      await _postSelectedAnswerApiCall(
          widget.userExamId,
          "",
          questionId,
          isAttempted,
          isAttemptedAndMarkedForReview,
          isSkipped,
          isMarkedForReview,
          selectedOption!,
          usedExamTime ?? "00:00:00");
    } else {
      await _postSelectedAnswerApiCall(
          widget.userExamId,
          selectedOption,
          questionId,
          isAttempted,
          isAttemptedAndMarkedForReview,
          isSkipped,
          isMarkedForReview,
          "",
          usedExamTime ?? "00:00:00");
    }
    isAttempted = false;
    isSkipped = false;
    isAttemptedAndMarkedForReview = false;
    isMarkedForReview = false;
    isGuess = false;

    setState(() {
      _selectedIndex = -1;
      if (isLastQues) {
        _getCount(widget.userExamId);
      }
      _currentQuestionIndex++;
      if (_currentQuestionIndex >=
          (widget.testExamPaper?.test?.length ?? 0) - 1) {
        isLastQues = true;
        _currentQuestionIndex = (widget.testExamPaper?.test?.length ?? 0) - 1;
      } else {
        isLastQues = false;
      }

      String? questionId1 =
          widget.testExamPaper?.test?[_currentQuestionIndex].sId;
      _getSelectedAnswer(questionId1 ?? "");

      questionWidget = getQuestionText(context);
    });
  }

  void _showPreviousQuestion() {
    guessed = false;
    setState(() {
      _selectedIndex = -1;
      isLastQues = false;
      if (widget.testExamPaper?.test?.length == 1) {
        _currentQuestionIndex = 0;
        firstQue = true;
      } else if (_currentQuestionIndex > 0) {
        _currentQuestionIndex--;
      } else {
        firstQue = true;
      }
      String? questionId =
          widget.testExamPaper?.test?[_currentQuestionIndex].sId;
      _getSelectedAnswer(questionId ?? "");

      questionWidget = getQuestionText(context);
    });
  }

  Widget getQuestionText(BuildContext context) {
    if (widget.testExamPaper?.test == null ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= (widget.testExamPaper?.test?.length ?? 0)) {
      return Center(
        child: Text(
          "No filtered data available",
          style: AppTokens.body(context).copyWith(
            color: AppTokens.muted(context),
          ),
        ),
      );
    }

    String questionTxt =
        widget.testExamPaper?.test?[_currentQuestionIndex].questionText ?? "";
    questionTxt = questionTxt.replaceAllMapped(
        RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    List<String> splittedText = questionTxt.split("splittedImage");
    List<Widget> columns = [];
    int index = 0;
    for (String text in splittedText) {
      List<Widget> questionImageWidget = [];
      if (widget.testExamPaper?.test?[_currentQuestionIndex].questionImg
              ?.isNotEmpty ??
          false) {
        for (String base64String in widget
            .testExamPaper!.test![_currentQuestionIndex].questionImg!) {
          try {
            questionImageWidget.add(
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        child: PhotoView(
                          imageProvider: NetworkImage(base64String),
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.covered * 2,
                        ),
                      );
                    },
                  );
                },
                child: Row(
                  children: [
                    Expanded(
                      child: InteractiveViewer(
                        scaleEnabled: false,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Stack(
                              children: [
                                Image.network(base64String, fit: BoxFit.cover),
                                Container(color: Colors.transparent),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } catch (e) {
            debugPrint("Error decoding base64 string: $e");
          }
        }
      }
      columns.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text
                  .trim()
                  .replaceAll(RegExp(r'\n{2,}'), '\n')
                  .trim()
                  .replaceAll("--", "\u2022"),
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppTokens.ink(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: questionImageWidget,
            ),
            const SizedBox(height: AppTokens.s12),
            questionImageWidget.isNotEmpty
                ? Text(
                    "Tap the image to zoom In/Out",
                    style: AppTokens.caption(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTokens.muted(context),
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      );
      index++;
      if (index >=
          (widget.testExamPaper?.test?[_currentQuestionIndex].questionImg
                      ?.length ??
                  0) -
              1) {
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns,
    );
  }

  Future<bool> _onBackPressed() async {
    if (_currentQuestionIndex > 0) {
      _showPreviousQuestion();
      return false;
    } else {
      bool confirmExit = await showDialog(
        context: context,
        builder: (context) => CustomQuizTestCancelDialogBox(
            timer!, remainingTimeNotifier, false),
      );
      return confirmExit ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    String? selectedOption = _selectedIndex == -1
        ? ""
        : widget.testExamPaper?.test?[_currentQuestionIndex]
            .optionsData?[_selectedIndex].value;

    questionWidget = getQuestionText(context);

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppTokens.scaffold(context),
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: AppTokens.surface(context),
          title: Padding(
            padding: const EdgeInsets.only(left: AppTokens.s8),
            child: Row(
              children: [
                _IconTile(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => CustomQuizTestCancelDialogBox(
                          timer!, remainingTimeNotifier, false),
                    );
                  },
                  child: SvgPicture.asset(
                    "assets/image/arrow_back.svg",
                    color: AppTokens.ink(context),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                _IconTile(
                  onTap: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  child: Image.asset(
                    "assets/image/questionplatte.png",
                    width: 22,
                  ),
                ),
                const Spacer(),
                ValueListenableBuilder<Duration>(
                  valueListenable: remainingTimeNotifier,
                  builder: (context, remainingTime, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.s12,
                        vertical: AppTokens.s4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTokens.surface2(context),
                        borderRadius:
                            BorderRadius.circular(AppTokens.r8),
                      ),
                      child: Text(
                        _fmtHMS(remainingTime),
                        style: AppTokens.body(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTokens.ink(context),
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _getCount(widget.userExamId),
                  borderRadius: BorderRadius.circular(AppTokens.r20),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s16,
                      vertical: AppTokens.s8,
                    ),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.primaryColor),
                      borderRadius:
                          BorderRadius.circular(AppTokens.r20),
                    ),
                    child: Text(
                      "Submit",
                      style: AppTokens.caption(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTokens.s16),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTokens.s16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    widget.testExamPaper?.test?.length ?? 0,
                    (index) => Container(
                      margin: const EdgeInsets.only(right: AppTokens.s4),
                      height: 3,
                      width: 22,
                      decoration: BoxDecoration(
                        color: index == _currentQuestionIndex
                            ? AppColors.primaryColor
                            : AppTokens.border(context),
                        borderRadius:
                            BorderRadius.circular(AppTokens.r8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.s24),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      questionWidget ?? const SizedBox(),
                      const SizedBox(height: AppTokens.s16),
                      ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        itemCount: widget.testExamPaper
                            ?.test?[_currentQuestionIndex]
                            .optionsData
                            ?.length,
                        itemBuilder: (BuildContext context, int index) {
                          TestData? testExamPaper = widget
                              .testExamPaper?.test?[_currentQuestionIndex];
                          String base64String =
                              testExamPaper?.optionsData?[index].answerImg ??
                                  "";
                          bool isSelected = index == _selectedIndex;
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppTokens.s12),
                            child: _OptionTile(
                              label:
                                  "${testExamPaper?.optionsData?[index].value}.",
                              answer: testExamPaper
                                      ?.optionsData?[index].answerTitle ??
                                  "",
                              imageUrl: base64String,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedIndex = -1;
                                    isAttemptedAndMarkedForReview = false;
                                    isMarkedForReview = false;
                                    isGuess = false;
                                  } else {
                                    _selectedIndex = index;
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: AppTokens.surface2(context),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s20,
                vertical: AppTokens.s16,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MarkerButton(
                          label: "Mark for review",
                          color: isMarkedForReview
                              ? Colors.blue
                              : (isAttemptedAndMarkedForReview
                                  ? Colors.orangeAccent
                                  : null),
                          onTap: () {
                            setState(() {
                              isGuess = false;
                              if (selectedOption != "") {
                                isAttemptedAndMarkedForReview =
                                    !isAttemptedAndMarkedForReview;
                              } else {
                                isMarkedForReview = !isMarkedForReview;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppTokens.s8),
                      Expanded(
                        child: _MarkerButton(
                          label: "Guess",
                          color: isGuess ? Colors.brown : null,
                          onTap: () {
                            if (_selectedIndex != -1) {
                              setState(() {
                                isGuess = !isGuess;
                                isAttemptedAndMarkedForReview = false;
                                isMarkedForReview = false;
                              });
                              debugPrint("isGuess:$isGuess");
                            } else {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text('Please Select Option'),
                              ));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _NavCircle(
                        asset: "assets/image/arrow_back.svg",
                        disabled: firstQue,
                        onTap: firstQue ? null : _showPreviousQuestion,
                      ),
                      const SizedBox(width: AppTokens.s16),
                      _NavCircle(
                        asset: "assets/image/arrow_back.svg",
                        flipped: true,
                        disabled: false,
                        onTap: _showNextQuestion,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        drawer: Drawer(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          backgroundColor: AppTokens.surface(context),
          child: QuizQuestionPallet(
            widget.testExamPaper,
            widget.userExamId,
            remainingTimeNotifier,
            widget.isPracticeExam,
            timer,
          ),
        ),
      ),
    );
  }
}

String _fmtHMS(Duration d) {
  final h = d.inHours.toString().padLeft(2, '0');
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return "$h:$m:$s";
}

class _PalleteCounts {
  final String attempted;
  final String markedForReview;
  final String skipped;
  final String attemptedAndMarkedForReview;
  final String notVisited;
  final String guess;
  _PalleteCounts({
    required this.attempted,
    required this.markedForReview,
    required this.skipped,
    required this.attemptedAndMarkedForReview,
    required this.notVisited,
    required this.guess,
  });
}

class _LegendCountRow extends StatelessWidget {
  const _LegendCountRow({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: Row(
        children: [
          CircleAvatar(radius: 5.0, backgroundColor: color),
          const SizedBox(width: AppTokens.s8),
          Text(
            label,
            style: AppTokens.body(context).copyWith(
              color: AppTokens.ink(context),
            ),
          ),
          const Spacer(),
          Text(
            count,
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.ink(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.outlined,
    required this.onTap,
  });

  final String label;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: Container(
        height: AppTokens.s32 + AppTokens.s16,
        alignment: Alignment.center,
        decoration: outlined
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.r12),
                border: Border.all(color: AppColors.primaryColor),
                color: AppTokens.surface(context),
              )
            : BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTokens.brand, AppTokens.brand2],
                ),
                borderRadius: BorderRadius.circular(AppTokens.r12),
                boxShadow: AppTokens.shadow1(context),
              ),
        child: Text(
          label,
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w700,
            color: outlined ? AppColors.primaryColor : AppColors.white,
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r8),
      child: Container(
        height: 36,
        width: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTokens.surface2(context),
          borderRadius: BorderRadius.circular(AppTokens.r8),
        ),
        child: child,
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.answer,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String answer;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r16),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor
              : AppTokens.surface(context),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppTokens.border(context),
          ),
          borderRadius: BorderRadius.circular(AppTokens.r16),
          boxShadow: isSelected ? AppTokens.shadow1(context) : null,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16,
          vertical: AppTokens.s12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.white
                            : AppTokens.ink(context),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: Text(
                        answer,
                        style: AppTokens.body(context).copyWith(
                          color: isSelected
                              ? AppColors.white
                              : AppTokens.ink(context),
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasImage)
                  Row(
                    children: [
                      InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 3.0,
                        child: Center(
                          child: SizedBox(
                            width:
                                MediaQuery.of(context).size.width * 0.6,
                            height: 250,
                            child: Stack(
                              children: [
                                Image.network(imageUrl),
                                Container(color: Colors.transparent),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkerButton extends StatelessWidget {
  const _MarkerButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final filled = color != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? color : AppTokens.surface(context),
          border: Border.all(color: AppTokens.border(context)),
          borderRadius: BorderRadius.circular(AppTokens.r12),
          boxShadow: filled ? AppTokens.shadow1(context) : null,
        ),
        child: Text(
          label,
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w700,
            color: filled ? AppColors.white : AppTokens.ink(context),
          ),
        ),
      ),
    );
  }
}

class _NavCircle extends StatelessWidget {
  const _NavCircle({
    required this.asset,
    required this.onTap,
    required this.disabled,
    this.flipped = false,
  });

  final String asset;
  final VoidCallback? onTap;
  final bool disabled;
  final bool flipped;

  @override
  Widget build(BuildContext context) {
    final tint =
        disabled ? AppTokens.border(context) : AppColors.primaryColor;
    Widget svg = SvgPicture.asset(asset, color: tint);
    if (flipped) {
      svg = Transform.flip(flipX: true, child: svg);
    }
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        height: 48,
        width: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: tint),
        ),
        child: svg,
      ),
    );
  }
}
