// ignore_for_file: use_super_parameters, deprecated_member_use, use_build_context_synchronously, unused_import, unused_field, unused_element, unused_local_variable, duplicate_ignore, dead_null_aware_expression

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:vibration/vibration.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/get_all_my_custom_test_model.dart';
import '../widgets/bottom_toast.dart';
import 'custom_question_pallet.dart';
import 'custom_user_test_cancel_dialogbox.dart';

class CustomTestExamScreen extends StatefulWidget {
  final Data? testExamPaper;
  final String? userExamId;
  final int? queNo;
  final bool? isPracticeExam;
  final ValueNotifier<Duration>? remainingTime;
  final String? id;
  final String? type;
  final bool? fromPallete;
  const CustomTestExamScreen(
      {super.key,
      this.fromPallete,
      this.testExamPaper,
      this.userExamId,
      this.isPracticeExam,
      this.queNo,
      this.remainingTime,
      this.id,
      this.type});

  @override
  State<CustomTestExamScreen> createState() => _CustomTestExamScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => CustomTestExamScreen(
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

class _CustomTestExamScreenState extends State<CustomTestExamScreen> {
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
    // Preserved intentionally — legacy hook.
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
      String time) async {
    debugPrint("timeQues$time");
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.userAnswerCustomTest(
        context,
        userExamId ?? "",
        questionId ?? "",
        selectedOption ?? "",
        isAttempted,
        isAttemptedAndMarkedForReview,
        isSkipped,
        isMarkedForReview,
        guess,
        time);
  }

  Future<void> _getSelectedAnswer(String queId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.questionAnswerByIdCustomTest(widget.userExamId ?? "", queId);
    setState(() {
      String? nextOption =
          (store.userCustomAnswerExam.value?.guess?.isNotEmpty ?? false)
              ? store.userCustomAnswerExam.value?.guess
              : store.userCustomAnswerExam.value?.selectedOption;
      _selectedIndex = widget
              .testExamPaper?.test?[_currentQuestionIndex].optionsData
              ?.indexWhere((option) => option.value == nextOption) ??
          -1;
      guessed = (store.userCustomAnswerExam.value?.guess?.isEmpty ?? false)
          ? false
          : true;
      isGuess = (store.userCustomAnswerExam.value?.guess?.isNotEmpty ?? false)
          ? true
          : false;
      isMarkedForReview =
          store.userCustomAnswerExam.value?.markedForReview ?? false;
      isAttemptedAndMarkedForReview =
          store.userCustomAnswerExam.value?.attemptedMarkedForReview ?? false;
    });
  }

  Future<void> _getCount(String? userExamId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.getCustomTestQuestionPalleteCount(userExamId ?? "").then((_) {
      openBottomSheet(store);
    });
  }

  Future<void> _getCount2(String? userExamId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.getCustomTestQuestionPalleteCount(userExamId ?? "").then((_) {
      openBottomSheet2(store);
    });
  }

  Future<void> _generateReport(String? userExamId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store
        .onReportCustomTestExamApiCall(widget.userExamId ?? "")
        .then((_) {
      Navigator.of(context)
          .pushNamed(Routes.customTestReportScreen, arguments: {
        'report': store.reportsCustomTestExam.value,
        'title': widget.testExamPaper?.testName,
        'userexamId': userExamId,
        'examId': widget.testExamPaper?.sId
      });
    });
  }

  void openBottomSheet(TestCategoryStore store) {
    showModalBottomSheet<void>(
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: AppTokens.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.r28)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      context: context,
      builder: (BuildContext context) {
        final counts = _readCounts(store);
        return _SubmitSheet(
          counts: counts,
          remainingTime: remainingTimeNotifier.value,
          showTimeLeft: true,
          showCancel: true,
          onCancel: () => Navigator.of(context).pop(),
          onSubmit: () async {
            if (await Vibration.hasVibrator() ?? false) {
              Vibration.vibrate();
            }
            timer?.cancel();
            _generateReport(widget.userExamId);
          },
          scrollController: scrollController,
        );
      },
    );
  }

  void openBottomSheet2(TestCategoryStore store) {
    showModalBottomSheet<void>(
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: AppTokens.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.r28)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      context: context,
      builder: (BuildContext context) {
        final counts = _readCounts(store);
        return _SubmitSheet(
          counts: counts,
          remainingTime: remainingTimeNotifier.value,
          showTimeLeft: false,
          showCancel: false,
          onCancel: () {},
          onSubmit: () {
            timer?.cancel();
            _generateReport(widget.userExamId);
          },
          scrollController: scrollController,
        );
      },
    );
  }

  _PalletCounts _readCounts(TestCategoryStore store) {
    String attempted = store.customTestQuePalleteCount.value?.isAttempted
            .toString()
            .padLeft(2, '0') ??
        "0";
    String markedForReview = store
            .customTestQuePalleteCount.value?.isMarkedForReview
            .toString()
            .padLeft(2, '0') ??
        "0";
    String skipped = store.customTestQuePalleteCount.value?.isSkipped
            .toString()
            .padLeft(2, '0') ??
        "0";
    String attemptedAndMarkedForReview = store
            .customTestQuePalleteCount.value?.isAttemptedMarkedForReview
            .toString()
            .padLeft(2, '0') ??
        "0";
    String notVisited = store.customTestQuePalleteCount.value?.notVisited
            .toString()
            .padLeft(2, '0') ??
        "0";
    String guess = store.customTestQuePalleteCount.value?.isGuess
            .toString()
            .padLeft(2, '0') ??
        "0";
    return _PalletCounts(
      attempted: attempted,
      markedForReview: markedForReview,
      skipped: skipped,
      attemptedAndMarkedForReview: attemptedAndMarkedForReview,
      notVisited: notVisited,
      guess: guess,
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
      usedExamTime =
          "${timeDifference.inHours.toString().padLeft(2, '0')}:${timeDifference.inMinutes.remainder(60).toString().padLeft(2, '0')}:${timeDifference.inSeconds.remainder(60).toString().padLeft(2, '0')}";
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
      return const SizedBox();
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
            questionImageWidget
                .add(_ZoomableImage(src: base64String, maxHeight: 240));
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
                  .replaceAll("--", "•"),
              textAlign: TextAlign.left,
              style: AppTokens.titleMd(context).copyWith(
                fontSize: Dimensions.fontSizeLarge,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: AppTokens.ink(context),
              ),
            ),
            if (questionImageWidget.isNotEmpty)
              const SizedBox(height: AppTokens.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: questionImageWidget,
            ),
            if (questionImageWidget.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.s4),
                child: Text(
                  "Tap any image to zoom in / out",
                  style: AppTokens.caption(context),
                ),
              ),
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
        builder: (context) =>
            CustomUserTestCancelDialogBox(timer, remainingTimeNotifier, false),
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
    final testExamPaper = widget.testExamPaper?.test?[_currentQuestionIndex];
    final options = testExamPaper?.optionsData ?? [];
    final int total = widget.testExamPaper?.test?.length ?? 0;

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppTokens.scaffold(context),
        drawer: Drawer(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          backgroundColor: AppTokens.surface(context),
          child: CustomTestQuestionPallet(
              widget.testExamPaper,
              widget.userExamId,
              remainingTimeNotifier,
              widget.isPracticeExam,
              timer),
        ),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(86),
          child: _ExamHeader(
            onBack: () {
              showDialog(
                context: context,
                builder: (context) => CustomUserTestCancelDialogBox(
                    timer, remainingTimeNotifier, false),
              );
            },
            onOpenPallet: () => _scaffoldKey.currentState?.openDrawer(),
            onSubmit: () => _getCount(widget.userExamId),
            remainingTimeNotifier: remainingTimeNotifier,
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTokens.s12),
            _QuestionProgressRow(
              currentIndex: _currentQuestionIndex,
              total: total,
            ),
            const SizedBox(height: AppTokens.s16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    AppTokens.s16, 0, AppTokens.s16, AppTokens.s24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuestionCard(child: questionWidget ?? const SizedBox()),
                    const SizedBox(height: AppTokens.s16),
                    ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final opt = options[index];
                        final bool isSelected = index == _selectedIndex;
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppTokens.s12),
                          child: _OptionTile(
                            label: opt.value ?? "",
                            text: opt.answerTitle ?? "",
                            imageUrl: opt.answerImg ?? "",
                            selected: isSelected,
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
            _BottomBar(
              selectedOption: selectedOption,
              isMarkedForReview: isMarkedForReview,
              isAttemptedAndMarkedForReview: isAttemptedAndMarkedForReview,
              isGuess: isGuess,
              firstQue: firstQue,
              onToggleReview: () {
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
              onToggleGuess: () {
                if (_selectedIndex != -1) {
                  setState(() {
                    isGuess = !isGuess;
                    isAttemptedAndMarkedForReview = false;
                    isMarkedForReview = false;
                  });
                  debugPrint("isGuess:$isGuess");
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please Select Option'),
                  ));
                }
              },
              onPrev: _showPreviousQuestion,
              onNext: _showNextQuestion,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  Primitives
// -----------------------------------------------------------------------------

class _ExamHeader extends StatelessWidget {
  const _ExamHeader({
    Key? key,
    required this.onBack,
    required this.onOpenPallet,
    required this.onSubmit,
    required this.remainingTimeNotifier,
  }) : super(key: key);

  final VoidCallback onBack;
  final VoidCallback onOpenPallet;
  final VoidCallback onSubmit;
  final ValueNotifier<Duration> remainingTimeNotifier;

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
          MediaQuery.of(context).padding.top + 10,
          AppTokens.s12,
          AppTokens.s12),
      child: Row(
        children: [
          _HeaderIconBtn(
              icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: AppTokens.s8),
          _HeaderIconBtn(icon: Icons.grid_view_rounded, onTap: onOpenPallet),
          const Spacer(),
          _TimerPill(remainingTimeNotifier: remainingTimeNotifier),
          const SizedBox(width: AppTokens.s8),
          _SubmitChip(onTap: onSubmit),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({Key? key, required this.icon, required this.onTap})
      : super(key: key);
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(child: Icon(icon, color: Colors.white, size: 18)),
        ),
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({Key? key, required this.remainingTimeNotifier})
      : super(key: key);
  final ValueNotifier<Duration> remainingTimeNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: remainingTimeNotifier,
      builder: (context, remainingTime, child) {
        final bool critical = remainingTime.inSeconds <= 60;
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s12, vertical: 6),
          decoration: BoxDecoration(
            color: critical
                ? Colors.white.withOpacity(0.95)
                : Colors.white.withOpacity(0.22),
            borderRadius: AppTokens.radius12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_rounded,
                size: 14,
                color: critical ? AppTokens.danger(context) : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                "${remainingTime.inHours.toString().padLeft(2, '0')}:${remainingTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTime.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                style: AppTokens.caption(context).copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w700,
                  color: critical ? AppTokens.danger(context) : Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SubmitChip extends StatelessWidget {
  const _SubmitChip({Key? key, required this.onTap}) : super(key: key);
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_turned_in_rounded,
                  size: 14, color: AppTokens.accent(context)),
              const SizedBox(width: 6),
              Text(
                "Submit",
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.accent(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionProgressRow extends StatelessWidget {
  const _QuestionProgressRow(
      {Key? key, required this.currentIndex, required this.total})
      : super(key: key);
  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    final double progress =
        total == 0 ? 0 : (currentIndex + 1).clamp(0, total) / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTokens.accent(context),
                  borderRadius: AppTokens.radius12,
                ),
                child: Text(
                  "Q ${(currentIndex + 1).toString().padLeft(2, '0')}",
                  style: AppTokens.caption(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Text(
                "of ${total.toString().padLeft(2, '0')}",
                style: AppTokens.body(context),
              ),
              const Spacer(),
              Text(
                "${(progress * 100).round()}%",
                style: AppTokens.caption(context)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          ClipRRect(
            borderRadius: AppTokens.radius8,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTokens.surface3(context),
              minHeight: 6,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppTokens.accent(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({Key? key, required this.child}) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: AppTokens.shadow1(context),
      ),
      child: child,
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    Key? key,
    required this.label,
    required this.text,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  final String label;
  final String text;
  final String imageUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = selected
        ? AppTokens.accent(context)
        : AppTokens.surface(context);
    final Color border = selected
        ? AppTokens.accent(context)
        : AppTokens.border(context);
    final Color inkColor = selected ? Colors.white : AppTokens.ink(context);

    return Material(
      color: Colors.transparent,
      borderRadius: AppTokens.radius16,
      child: InkWell(
        borderRadius: AppTokens.radius16,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s16, vertical: AppTokens.s12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppTokens.radius16,
            border: Border.all(color: border, width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.22)
                      : AppTokens.surface2(context),
                  shape: BoxShape.circle,
                  border: Border.all(color: inkColor.withOpacity(0.5)),
                ),
                child: Text(
                  label,
                  style: AppTokens.caption(context).copyWith(
                    color: inkColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: AppTokens.bodyLg(context).copyWith(
                        color: inkColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (imageUrl.isNotEmpty) ...[
                      const SizedBox(height: AppTokens.s8),
                      _ZoomableImage(src: imageUrl, maxHeight: 220),
                    ],
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: AppTokens.s8),
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    Key? key,
    required this.selectedOption,
    required this.isMarkedForReview,
    required this.isAttemptedAndMarkedForReview,
    required this.isGuess,
    required this.firstQue,
    required this.onToggleReview,
    required this.onToggleGuess,
    required this.onPrev,
    required this.onNext,
  }) : super(key: key);

  final String? selectedOption;
  final bool isMarkedForReview;
  final bool isAttemptedAndMarkedForReview;
  final bool isGuess;
  final bool firstQue;
  final VoidCallback onToggleReview;
  final VoidCallback onToggleGuess;
  final VoidCallback onPrev;
  final Future<void> Function() onNext;

  @override
  Widget build(BuildContext context) {
    final Color reviewColor = isMarkedForReview
        ? AppTokens.accent(context)
        : (isAttemptedAndMarkedForReview
            ? AppTokens.warning(context)
            : AppTokens.surface2(context));
    final Color reviewInk = (isMarkedForReview ||
            isAttemptedAndMarkedForReview)
        ? Colors.white
        : AppTokens.ink(context);
    final Color guessColor =
        isGuess ? AppTokens.warning(context) : AppTokens.surface2(context);
    final Color guessInk =
        isGuess ? Colors.white : AppTokens.ink(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(AppTokens.s16, AppTokens.s12,
          AppTokens.s16, AppTokens.s12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        border: Border(
          top: BorderSide(color: AppTokens.border(context)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: "Mark for review",
                  icon: Icons.flag_rounded,
                  background: reviewColor,
                  ink: reviewInk,
                  border: AppTokens.border(context),
                  onTap: onToggleReview,
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: _ActionButton(
                  label: "Guess",
                  icon: Icons.help_outline_rounded,
                  background: guessColor,
                  ink: guessInk,
                  border: AppTokens.border(context),
                  onTap: onToggleGuess,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NavCircle(
                  icon: Icons.arrow_back_ios_new_rounded,
                  enabled: !firstQue,
                  onTap: onPrev),
              const SizedBox(width: AppTokens.s16),
              _NavCircle(
                  icon: Icons.arrow_forward_ios_rounded,
                  enabled: true,
                  onTap: () => onNext()),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.background,
    required this.ink,
    required this.border,
    required this.onTap,
  }) : super(key: key);

  final String label;
  final IconData icon;
  final Color background;
  final Color ink;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppTokens.radius12,
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: ink),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTokens.titleSm(context).copyWith(
                  color: ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCircle extends StatelessWidget {
  const _NavCircle(
      {Key? key,
      required this.icon,
      required this.enabled,
      required this.onTap})
      : super(key: key);
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color tint =
        enabled ? AppTokens.accent(context) : AppTokens.border(context);
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: tint, width: 1.4),
            color: AppTokens.surface(context),
          ),
          child: Icon(icon, color: tint, size: 18),
        ),
      ),
    );
  }
}

class _ZoomableImage extends StatelessWidget {
  const _ZoomableImage({Key? key, required this.src, required this.maxHeight})
      : super(key: key);
  final String src;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    if (src.isEmpty) return const SizedBox();
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: AppTokens.radius20),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: PhotoView(
                  imageProvider: NetworkImage(src),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  backgroundDecoration:
                      BoxDecoration(color: AppTokens.surface(context)),
                ),
              ),
            );
          },
        );
      },
      child: ClipRRect(
        borderRadius: AppTokens.radius12,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          width: double.infinity,
          color: AppTokens.surface2(context),
          child: Image.network(src, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  Submit bottom-sheet primitives
// -----------------------------------------------------------------------------

class _PalletCounts {
  final String attempted;
  final String markedForReview;
  final String skipped;
  final String attemptedAndMarkedForReview;
  final String notVisited;
  final String guess;
  _PalletCounts({
    required this.attempted,
    required this.markedForReview,
    required this.skipped,
    required this.attemptedAndMarkedForReview,
    required this.notVisited,
    required this.guess,
  });
}

class _SubmitSheet extends StatelessWidget {
  const _SubmitSheet({
    Key? key,
    required this.counts,
    required this.remainingTime,
    required this.showTimeLeft,
    required this.showCancel,
    required this.onCancel,
    required this.onSubmit,
    required this.scrollController,
  }) : super(key: key);

  final _PalletCounts counts;
  final Duration remainingTime;
  final bool showTimeLeft;
  final bool showCancel;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppTokens.s20, AppTokens.s12, AppTokens.s20,
          AppTokens.s16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppTokens.border(context),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Text(
            showTimeLeft ? "Test Submission" : "Time is up",
            style: AppTokens.titleLg(context),
          ),
          const SizedBox(height: AppTokens.s4),
          Text(
            showTimeLeft
                ? "Review your stats before submitting."
                : "Your session ended. Submit to see the report.",
            style: AppTokens.caption(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTokens.s16),
          Flexible(
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: false,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showTimeLeft)
                      _TimeLeftRow(remainingTime: remainingTime),
                    if (showTimeLeft) const SizedBox(height: AppTokens.s12),
                    _StatRow(
                        color: AppTokens.success(context),
                        label: "Attempted",
                        value: counts.attempted),
                    _StatRow(
                        color: AppTokens.accent(context),
                        label: "Marked for Review",
                        value: counts.markedForReview),
                    _StatRow(
                        color: AppTokens.warning(context),
                        label: "Attempted and Marked for Review",
                        value: counts.attemptedAndMarkedForReview),
                    _StatRow(
                        color: AppTokens.danger(context),
                        label: "Skipped",
                        value: counts.skipped),
                    _StatRow(
                        color: Colors.brown,
                        label: "Guess",
                        value: counts.guess),
                    _StatRow(
                        color: AppTokens.ink(context),
                        label: "Not Visited",
                        value: counts.notVisited),
                  ],
                ),
              ),
            ),
          ),
          if (showTimeLeft) ...[
            const SizedBox(height: AppTokens.s16),
            Text(
              "Are you sure you want to submit the test?",
              style: AppTokens.titleSm(context).copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppTokens.s16),
          Row(
            children: [
              if (showCancel) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppTokens.radius12),
                      side: BorderSide(color: AppTokens.border(context)),
                      foregroundColor: AppTokens.ink(context),
                    ),
                    child: Text("Cancel",
                        style: AppTokens.titleSm(context)
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
              ],
              Expanded(
                child: _GradientCta(label: "Submit", onTap: onSubmit),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeLeftRow extends StatelessWidget {
  const _TimeLeftRow({Key? key, required this.remainingTime}) : super(key: key);
  final Duration remainingTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s12, vertical: AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: AppTokens.radius12,
      ),
      child: Row(
        children: [
          Icon(Icons.timer_rounded, size: 16, color: AppTokens.ink2(context)),
          const SizedBox(width: AppTokens.s8),
          Text("Time Left", style: AppTokens.body(context)),
          const Spacer(),
          Text(
            "${remainingTime.inHours.toString().padLeft(2, '0')}:${remainingTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTime.inSeconds.remainder(60).toString().padLeft(2, '0')}",
            style: AppTokens.titleSm(context).copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w700,
              color: AppTokens.danger(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(
      {Key? key,
      required this.color,
      required this.label,
      required this.value})
      : super(key: key);
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
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
          Expanded(
              child: Text(label, style: AppTokens.body(context))),
          Text(
            value,
            style: AppTokens.titleSm(context)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _GradientCta extends StatelessWidget {
  const _GradientCta({Key? key, required this.label, required this.onTap})
      : super(key: key);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius12,
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTokens.brand.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            label,
            style: AppTokens.titleSm(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
