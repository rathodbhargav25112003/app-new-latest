// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names, dead_null_aware_expression

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/masterTest/question_master_pallet.dart';
import 'package:shusruta_lms/modules/masterTest/question_master_pallet_drawer.dart';
import 'package:shusruta_lms/modules/masterTest/time_traker.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/test_exampaper_list_model.dart';
import '../widgets/bottom_toast.dart';
import 'custom_master_test_dialogbox.dart';

/// Master test (non-practice) exam runner. Redesigned with AppTokens.
/// Preserves:
///   • Constructor `TestMasterExamScreen({super.key, fromPallete,
///     testExamPaper, userExamId, isPracticeExam, queNo, remainingTime,
///     showPredictive, isTrend = false, id, type, categoryId})`
///   • Static `route(RouteSettings)` factory with the 11 argument keys
///     (testData / userexamId / queNo / isPracticeExam / remainingTime / id /
///     category_id / type / isTrend / fromPallete / showPredictive)
///   • State fields: _scaffoldKey, timer, remainingTime, remainingTimeNotifier,
///     _selectedIndex = -1, _currentQuestionIndex = 0, firstQue = true,
///     isLastQues = false, 5 attempt flags (isAttempted / isMarkedForReview /
///     isGuess / isAttemptedAndMarkedForReview / isSkipped),
///     answerImgBytes / quesImgBytes, duration, usedExamTime, questionWidget,
///     scrollController, tracker (TimeTracker), _testExamPaper / _userExamId /
///     _queNo / _isPracticeExam / _remainingTime / _id / _type / _fromPallete
///     mutable mirrors (for _updateParameter), isLoading
///   • Helpers (verbatim signatures): init, _updateParameter, updateTimer,
///     didChangeAppLifecycleState, _postSelectedAnswerApiCall,
///     _getSelectedAnswer, _getCount, _getCount2, _generateReport,
///     openBottomSheet, openBottomSheet2, _saveQuestion, _showNextQuestion,
///     _showPreviousQuestion, getQuestionText, _onBackPressed
///   • TestCategoryStore APIs: `userAnswerMasterTest`, `questionAnswerById`,
///     `userAnswerExam.value`, `getQuestionMasterPalleteCount`,
///     `testQueMasterPalleteCount.value` (attempted / markedForReview /
///     skipped / attemptedMarkedForReview / notVisited / isGuess),
///     `onReportMasterExamApiCall`, `reportsMasterExam.value`
///   • Timer → ValueListenableBuilder&lt;Duration&gt; binding in AppBar
///   • Timer expiry → _getCount2(_userExamId) → openBottomSheet2 (Submit only,
///     timer?.cancel() + _generateReport)
///   • Review button → _getCount(_userExamId) → openBottomSheet (Cancel +
///     disabled Submit, onTap: null)
///   • _generateReport → `pushNamed(Routes.masterTestReportScreen)` with 7
///     argument keys (report / title / userexamId / examId / isTrend /
///     category_id / showPredictive)
///   • _saveQuestion auto-triggered on option tap — posts via
///     `_postSelectedAnswerApiCall` with `tracker.getCurrentTime()`
///   • _showNextQuestion posts via `tracker.stop()` and cascades to
///     _getCount at end
///   • _onBackPressed shows `CustomMasterTestCancelDialogBox(timer,
///     remainingTimeNotifier, false)` at first question
///   • Wide mode (>1160 × 670): `QuestionMasterPalletDrawer(key: UniqueKey(),
///     _testExamPaper, _userExamId, remainingTimeNotifier, _isPracticeExam,
///     callBack: (data) => _updateParameter(...))` side panel
///   • Narrow mode: `QuestionMasterPallet(_testExamPaper, _userExamId,
///     remainingTimeNotifier, _isPracticeExam, showPredictive: widget
///     .showPredictive)` drawer
///   • Mark for review toggle (orangeAccent when attempted-and-marked, blue
///     when marked-only) + Guess toggle (brown when active)
///   • PhotoView on NetworkImage for zoom
///   • Bullet rewrite rule (simpler): `\n{2,}` → `\n`, `--` → `•`
class TestMasterExamScreen extends StatefulWidget {
  final TestExamPaperListModel? testExamPaper;
  final String? userExamId;
  final int? queNo;
  final bool? isPracticeExam;
  final ValueNotifier<Duration>? remainingTime;
  final String? id;
  final String? type;
  final String? categoryId;
  final bool? showPredictive;
  final bool? isTrend;
  final bool? fromPallete;
  const TestMasterExamScreen(
      {super.key,
      this.fromPallete,
      this.testExamPaper,
      this.userExamId,
      this.isPracticeExam,
      this.queNo,
      this.remainingTime,
      this.showPredictive,
      this.isTrend = false,
      this.id,
      this.type,
      this.categoryId});

  @override
  State<TestMasterExamScreen> createState() => _TestMasterExamScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => TestMasterExamScreen(
        testExamPaper: arguments['testData'],
        userExamId: arguments['userexamId'],
        queNo: arguments['queNo'],
        isPracticeExam: arguments['isPracticeExam'],
        remainingTime: arguments['remainingTime'],
        id: arguments['id'],
        categoryId: arguments['category_id'] ?? "",
        type: arguments['type'],
        isTrend: arguments['isTrend'] ?? false,
        fromPallete: arguments['fromPallete'],
        showPredictive: arguments['showPredictive'],
      ),
    );
  }
}

class _TestMasterExamScreenState extends State<TestMasterExamScreen> {
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
  final ScrollController scrollController = ScrollController();
  TimeTracker tracker = TimeTracker(previousTime: '00:00:00');
  TestExamPaperListModel? _testExamPaper;
  String? _userExamId;
  int? _queNo;
  bool? _isPracticeExam;
  ValueNotifier<Duration>? _remainingTime;
  String? _id;
  String? _type;
  bool? _fromPallete;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _testExamPaper = widget.testExamPaper;
    _userExamId = widget.userExamId;
    _queNo = widget.queNo;
    _isPracticeExam = widget.isPracticeExam;
    _remainingTime = widget.remainingTime;
    _id = widget.id;
    _type = widget.type;
    _fromPallete = widget.fromPallete;
    tracker.start();
    init();
    setState(() {});
  }

  void init() {
    updateTimer();
    int matchingIndex =
        _testExamPaper?.test?.indexWhere((e) => e.questionNumber == _queNo) ??
            -1;
    if (matchingIndex != -1) {
      String? matchingQueId = _testExamPaper?.test?[matchingIndex].sId;
      _getSelectedAnswer(matchingQueId!);
      _currentQuestionIndex = matchingIndex;
      setState(() {
        firstQue = false;
      });
      if (_currentQuestionIndex >= (_testExamPaper?.test?.length ?? 0) - 1) {
        isLastQues = true;
      } else {
        isLastQues = false;
      }
    }
  }

  // Update mutable state mirrors (used from QuestionMasterPalletDrawer
  // callBack and whenever we navigate via the side panel).
  void _updateParameter({
    TestExamPaperListModel? testExamPaper,
    String? userExamId,
    int? queNo,
    bool? isPracticeExam,
    ValueNotifier<Duration>? remainingTime,
    String? id,
    String? type,
    bool? fromPallete,
  }) {
    setState(() {
      if (testExamPaper != null) _testExamPaper = testExamPaper;
      if (userExamId != null) _userExamId = userExamId;
      if (queNo != null) _queNo = queNo;
      if (remainingTime != null) _remainingTime = remainingTime;
      if (isPracticeExam != null) _isPracticeExam = isPracticeExam;
      if (id != null) _id = id;
      if (type != null) _type = type;
      if (fromPallete != null) _fromPallete = fromPallete;
    });
    init();
  }

  void updateTimer() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }
    if (_testExamPaper?.timeDuration != null && _fromPallete != true) {
      List<String>? timeParts = _testExamPaper?.timeDuration?.split(":");
      duration = Duration(
        hours: int.parse(timeParts![0]),
        minutes: int.parse(timeParts[1]),
        seconds: int.parse(timeParts[2]),
      );
      remainingTime = duration;
      remainingTimeNotifier = ValueNotifier<Duration>(remainingTime!);
    } else {
      List<String>? timeParts = _testExamPaper?.timeDuration?.split(":");
      duration = Duration(
        hours: int.parse(timeParts![0]),
        minutes: int.parse(timeParts[1]),
        seconds: int.parse(timeParts[2]),
      );
      remainingTime = _remainingTime?.value;
      remainingTimeNotifier = ValueNotifier<Duration>(remainingTime!);
    }

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      print("Time$timer");
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
        _getCount2(_userExamId);
      }
    });
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lifecycle handler intentionally left as a no-op — timer is driven by
    // remainingTimeNotifier. (Preserved from original.)
  }

  @override
  void dispose() {
    timer?.cancel();
    remainingTimeNotifier.dispose();
    super.dispose();
  }

  // ==========================================================================
  //                              STORE HELPERS
  // ==========================================================================

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
      String? questionTime) async {
    debugPrint("timeQues$time");
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.userAnswerMasterTest(
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
        questionTime);
  }

  Future<void> _getSelectedAnswer(String queId) async {
    setState(() {
      isLoading = true;
    });
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.questionAnswerById(_userExamId ?? "", queId);
    setState(() {
      String? nextOption =
          (store.userAnswerExam.value?.guess?.isNotEmpty ?? false)
              ? store.userAnswerExam.value?.guess
              : store.userAnswerExam.value?.selectedOption;
      _selectedIndex = _testExamPaper?.test?[_currentQuestionIndex].optionsData
              ?.indexWhere((option) => option.value == nextOption) ??
          -1;
      isGuess = (store.userAnswerExam.value?.guess?.isNotEmpty ?? false)
          ? true
          : false;
      isMarkedForReview = store.userAnswerExam.value?.markedForReview ?? false;
      isAttemptedAndMarkedForReview =
          store.userAnswerExam.value?.attemptedMarkedForReview ?? false;
      tracker = TimeTracker(
          previousTime:
              store.userAnswerExam.value!.timePerQuestion ?? '00:00:00');
      tracker.start();
      isLoading = false;
    });
  }

  Future<void> _getCount(String? userExamId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.getQuestionMasterPalleteCount(userExamId ?? "").then((_) {
      openBottomSheet(store);
    });
  }

  Future<void> _getCount2(String? userExamId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.getQuestionMasterPalleteCount(userExamId ?? "").then((_) {
      openBottomSheet2(store);
    });
  }

  Future<void> _generateReport(String? userExamId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onReportMasterExamApiCall(_userExamId ?? "").then((_) {
      Navigator.of(context)
          .pushNamed(Routes.masterTestReportScreen, arguments: {
        'report': store.reportsMasterExam.value,
        'title': _testExamPaper?.examName,
        'userexamId': userExamId,
        'examId': _testExamPaper?.examId,
        'isTrend': widget.isTrend,
        'category_id': widget.categoryId,
        'showPredictive': widget.showPredictive,
      });
    });
  }

  // ==========================================================================
  //                               SAVE FLOWS
  // ==========================================================================

  Future<void> _saveQuestion() async {
    setState(() {
      isLoading = true;
    });
    debugPrint("_userExamId:$_userExamId");
    firstQue = false;
    String? questionId = _testExamPaper?.test?[_currentQuestionIndex].sId;

    String? selectedOption = _selectedIndex == -1
        ? ""
        : _testExamPaper
            ?.test?[_currentQuestionIndex].optionsData?[_selectedIndex].value;
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
          _userExamId,
          "",
          questionId,
          isAttempted,
          isAttemptedAndMarkedForReview,
          isSkipped,
          isMarkedForReview,
          selectedOption!,
          usedExamTime ?? "00:00:00",
          tracker.getCurrentTime());
    } else {
      await _postSelectedAnswerApiCall(
          _userExamId,
          selectedOption,
          questionId,
          isAttempted,
          isAttemptedAndMarkedForReview,
          isSkipped,
          isMarkedForReview,
          "",
          usedExamTime ?? "00:00:00",
          tracker.getCurrentTime());
    }
    isAttempted = false;
    isSkipped = false;
    isAttemptedAndMarkedForReview = false;
    isMarkedForReview = false;
    isGuess = false;
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _showNextQuestion() async {
    setState(() {
      isLoading = true;
    });
    debugPrint("_userExamId:$_userExamId");
    firstQue = false;
    String? questionId = _testExamPaper?.test?[_currentQuestionIndex].sId;

    String? selectedOption = _selectedIndex == -1
        ? ""
        : _testExamPaper
            ?.test?[_currentQuestionIndex].optionsData?[_selectedIndex].value;
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
          _userExamId,
          "",
          questionId,
          isAttempted,
          isAttemptedAndMarkedForReview,
          isSkipped,
          isMarkedForReview,
          selectedOption!,
          usedExamTime ?? "00:00:00",
          tracker.stop());
    } else {
      await _postSelectedAnswerApiCall(
          _userExamId,
          selectedOption,
          questionId,
          isAttempted,
          isAttemptedAndMarkedForReview,
          isSkipped,
          isMarkedForReview,
          "",
          usedExamTime ?? "00:00:00",
          tracker.stop());
    }
    isAttempted = false;
    isSkipped = false;
    isAttemptedAndMarkedForReview = false;
    isMarkedForReview = false;
    isGuess = false;

    setState(() async {
      _selectedIndex = -1;
      if (isLastQues) {
        _getCount(_userExamId);
      }
      _currentQuestionIndex++;
      if (_currentQuestionIndex >= (_testExamPaper?.test?.length ?? 0) - 1) {
        isLastQues = true;
        _currentQuestionIndex = (_testExamPaper?.test?.length ?? 0) - 1;
      } else {
        isLastQues = false;
      }

      String? questionId1 = _testExamPaper?.test?[_currentQuestionIndex].sId;
      await _getSelectedAnswer(questionId1 ?? "");

      questionWidget = getQuestionText(context);

      isLoading = false;
    });
  }

  Future<void> _showPreviousQuestion() async {
    setState(() {
      isLoading = true;
    });
    setState(() async {
      _selectedIndex = -1;
      isLastQues = false;
      if (_testExamPaper?.test?.length == 1) {
        _currentQuestionIndex = 0;
        firstQue = true;
      } else if (_currentQuestionIndex > 0) {
        _currentQuestionIndex--;
      } else {
        firstQue = true;
      }
      String? questionId = _testExamPaper?.test?[_currentQuestionIndex].sId;
      await _getSelectedAnswer(questionId ?? "");

      questionWidget = getQuestionText(context);

      isLoading = false;
    });
  }

  // ==========================================================================
  //                           QUESTION TEXT RENDER
  // ==========================================================================

  Widget getQuestionText(BuildContext context) {
    if (_testExamPaper?.test == null ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= (_testExamPaper?.test?.length ?? 0)) {
      return Center(
        child: Text(
          "No filtered data available",
          style: AppTokens.body(context),
        ),
      );
    }

    String questionTxt =
        _testExamPaper?.test?[_currentQuestionIndex].questionText ?? "";
    questionTxt = questionTxt.replaceAllMapped(
        RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    List<String> splittedText = questionTxt.split("splittedImage");
    List<Widget> columns = [];
    int index = 0;
    for (String text in splittedText) {
      List<Widget> questionImageWidget = [];
      if (_testExamPaper
              ?.test?[_currentQuestionIndex].questionImg?.isNotEmpty ??
          false) {
        for (String base64String
            in _testExamPaper!.test![_currentQuestionIndex].questionImg!) {
          try {
            questionImageWidget.add(
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        backgroundColor: AppTokens.surface(context),
                        child: PhotoView(
                          imageProvider: NetworkImage(base64String),
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.covered * 2,
                          backgroundDecoration: BoxDecoration(
                              color: AppTokens.surface(context)),
                        ),
                      );
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.s8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                    child:
                        Image.network(base64String, fit: BoxFit.cover),
                  ),
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
                  .replaceAll("--", "•"),
              textAlign: TextAlign.left,
              style: AppTokens.bodyLg(context)
                  .copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: AppTokens.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: questionImageWidget,
            ),
            if (questionImageWidget.isNotEmpty)
              Text(
                "Tap the image to zoom In/Out",
                style: AppTokens.caption(context)
                    .copyWith(color: AppTokens.muted(context)),
              ),
          ],
        ),
      );
      index++;
      if (index >=
          (_testExamPaper?.test?[_currentQuestionIndex].questionImg?.length ??
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
        builder: (context) => CustomMasterTestCancelDialogBox(
            timer, remainingTimeNotifier, false),
      );
      return confirmExit ?? false;
    }
  }

  // ==========================================================================
  //                                BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    questionWidget = getQuestionText(context);
    String? selectedOption = _selectedIndex == -1
        ? ""
        : _testExamPaper
            ?.test?[_currentQuestionIndex].optionsData?[_selectedIndex].value;

    final bool wideMode = MediaQuery.of(context).size.width > 1160 &&
        MediaQuery.of(context).size.height > 670;

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppTokens.scaffold(context),
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: AppTokens.scaffold(context),
          surfaceTintColor: AppTokens.scaffold(context),
          toolbarHeight: 64,
          title: Padding(
            padding: const EdgeInsets.only(left: AppTokens.s4),
            child: Row(
              children: [
                _CircleIconBtn(
                  icon: Icons.arrow_back_rounded,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => CustomMasterTestCancelDialogBox(
                          timer, remainingTimeNotifier, false),
                    );
                  },
                ),
                if (!wideMode) ...[
                  const SizedBox(width: AppTokens.s12),
                  _CircleIconBtn(
                    icon: Icons.grid_view_rounded,
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s12,
                    vertical: AppTokens.s4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius:
                        BorderRadius.circular(AppTokens.r28),
                    border:
                        Border.all(color: AppTokens.accent(context)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 14,
                          color: AppTokens.accent(context)),
                      const SizedBox(width: AppTokens.s4),
                      ValueListenableBuilder<Duration>(
                        valueListenable: remainingTimeNotifier,
                        builder: (context, remainingTime, child) {
                          return Text(
                            "${remainingTime.inHours.toString().padLeft(2, '0')}:${remainingTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTime.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                            style: AppTokens.titleSm(context).copyWith(
                              color: AppTokens.accent(context),
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (isLoading) ...[
                  const SizedBox(width: AppTokens.s8),
                  CupertinoActivityIndicator(
                      color: AppTokens.accent(context)),
                ],
                const Spacer(),
                _ReviewBtn(onTap: () => _getCount(_userExamId)),
              ],
            ),
          ),
        ),
        body: Row(
          children: [
            if (wideMode)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.22,
                child: QuestionMasterPalletDrawer(
                  key: UniqueKey(),
                  _testExamPaper,
                  _userExamId,
                  remainingTimeNotifier,
                  _isPracticeExam,
                  callBack: (testMasterExamData) {
                    _updateParameter(
                      fromPallete: testMasterExamData.fromPallete,
                      queNo: testMasterExamData.queNo,
                      isPracticeExam: testMasterExamData.isPracticeExam,
                      remainingTime: testMasterExamData.remainingTime,
                      testExamPaper: testMasterExamData.testExamPaper,
                      userExamId: testMasterExamData.userExamId,
                    );
                  },
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppTokens.border(context),
                  ),
                  // -------------------- question header --------------------
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.s16,
                      AppTokens.s12,
                      AppTokens.s16,
                      AppTokens.s8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          "${_currentQuestionIndex + 1}.",
                          style: AppTokens.titleMd(context)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s12,
                            vertical: AppTokens.s4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTokens.brand,
                                AppTokens.brand2
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppTokens.r28),
                            boxShadow: AppTokens.shadow1(context),
                          ),
                          child: Text(
                            "Q-${(_currentQuestionIndex + 1).toString().padLeft(2, '0')}",
                            style: AppTokens.titleSm(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.s8),
                        Text(
                          "Out of ${_testExamPaper?.test?.length.toString().padLeft(2, '0') ?? 0}",
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.ink2(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // -------------------- question + options --------------------
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.s16,
                        AppTokens.s8,
                        AppTokens.s16,
                        AppTokens.s16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          questionWidget ?? const SizedBox(),
                          const SizedBox(height: AppTokens.s16),
                          _buildOptionsList(context),
                        ],
                      ),
                    ),
                  ),
                  // -------------------- footer (mark / guess / nav) --------------------
                  _buildFooter(context, selectedOption),
                ],
              ),
            ),
          ],
        ),
        drawer: Drawer(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          backgroundColor: AppTokens.surface(context),
          child: QuestionMasterPallet(
            _testExamPaper,
            _userExamId,
            remainingTimeNotifier,
            _isPracticeExam,
            showPredictive: widget.showPredictive,
          ),
        ),
      ),
    );
  }

  // ------------------------------- options list ------------------------------
  Widget _buildOptionsList(BuildContext context) {
    final optionsData =
        _testExamPaper?.test?[_currentQuestionIndex].optionsData ?? [];
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: optionsData.length,
      itemBuilder: (BuildContext context, int index) {
        final option = optionsData[index];
        final base64String = option.answerImg ?? "";
        final bool isSelected = index == _selectedIndex;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.s12),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.r20),
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
              _saveQuestion();
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTokens.accentSoft(context)
                    : AppTokens.surface(context),
                borderRadius: BorderRadius.circular(AppTokens.r20),
                border: Border.all(
                  color: isSelected
                      ? AppTokens.accent(context)
                      : AppTokens.border(context),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s16,
                vertical: AppTokens.s12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTokens.accent(context).withOpacity(0.15)
                          : AppTokens.surface2(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppTokens.accent(context)
                            : AppTokens.border(context),
                      ),
                    ),
                    child: Text(
                      option.value ?? "",
                      style: AppTokens.titleSm(context).copyWith(
                        color: isSelected
                            ? AppTokens.accent(context)
                            : AppTokens.ink2(context),
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
                          option.answerTitle ?? "",
                          style: AppTokens.body(context).copyWith(
                            color: isSelected
                                ? AppTokens.accent(context)
                                : AppTokens.ink(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (base64String.isNotEmpty) ...[
                          const SizedBox(height: AppTokens.s8),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppTokens.r12),
                            child: Image.network(
                              base64String,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------- footer ------------------------------------
  Widget _buildFooter(BuildContext context, String? selectedOption) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s16,
        AppTokens.s12,
        AppTokens.s16,
        AppTokens.s16,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        border: Border(top: BorderSide(color: AppTokens.border(context))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _ToggleChip(
                  label: "Mark for review",
                  active: isMarkedForReview || isAttemptedAndMarkedForReview,
                  activeColor: isAttemptedAndMarkedForReview
                      ? Colors.orangeAccent
                      : Colors.blue,
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
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: _ToggleChip(
                  label: "Guess",
                  active: isGuess,
                  activeColor: Colors.brown,
                  onTap: () {
                    if (_selectedIndex != -1) {
                      setState(() {
                        isGuess = !isGuess;
                        isAttemptedAndMarkedForReview = false;
                        isMarkedForReview = false;
                      });
                      debugPrint("isGuess:$isGuess");
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please Select Option'),
                        ),
                      );
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
              _NavCircleBtn(
                icon: Icons.arrow_back_rounded,
                enabled: !firstQue,
                onTap: firstQue ? null : _showPreviousQuestion,
              ),
              const SizedBox(width: AppTokens.s16),
              _NavCircleBtn(
                icon: Icons.arrow_forward_rounded,
                enabled: true,
                onTap: _showNextQuestion,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  //                      openBottomSheet  (Review → manual)
  // Shows full status legend. Cancel works; Submit is disabled (onTap: null)
  // — mirroring the original behaviour.
  // ==========================================================================
  void openBottomSheet(TestCategoryStore store) {
    final String attempted = store.testQueMasterPalleteCount.value?.isAttempted
            .toString()
            .padLeft(2, '0') ??
        "0";
    final String markedForReview =
        store.testQueMasterPalleteCount.value?.isMarkedForReview
                .toString()
                .padLeft(2, '0') ??
            "0";
    final String skipped = store.testQueMasterPalleteCount.value?.isSkipped
            .toString()
            .padLeft(2, '0') ??
        "0";
    final String attemptedandMarkedForReview = store
            .testQueMasterPalleteCount.value?.isAttemptedMarkedForReview
            .toString()
            .padLeft(2, '0') ??
        "0";
    final String notVisited = store.testQueMasterPalleteCount.value?.notVisited
            .toString()
            .padLeft(2, '0') ??
        "0";
    final String guess = store.testQueMasterPalleteCount.value?.isGuess
            .toString()
            .padLeft(2, '0') ??
        "0";

    final content = _SubmissionSheet(
      title: "Test Submission",
      timeLabel: _formattedRemaining(remainingTimeNotifier.value),
      rows: [
        _SubmissionRow(
            color: Colors.green, label: "Attempted", value: attempted),
        _SubmissionRow(
            color: Colors.blue,
            label: "Marked for Review",
            value: markedForReview),
        _SubmissionRow(
            color: Colors.orangeAccent,
            label: "Attempted and Marked for Review",
            value: attemptedandMarkedForReview),
        _SubmissionRow(
            color: Colors.red, label: "Skipped", value: skipped),
        _SubmissionRow(color: Colors.brown, label: "Guess", value: guess),
        _SubmissionRow(
            color: AppTokens.ink(context),
            label: "Not Visited",
            value: notVisited),
      ],
      onCancel: () => Navigator.of(context).pop(),
      // Submit disabled in review path — preserves original behaviour where
      // the primary submit gesture lives in openBottomSheet2 (time expired).
      onSubmit: null,
    );

    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTokens.surface(context),
            surfaceTintColor: AppTokens.surface(context),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.r20)),
            actionsPadding: EdgeInsets.zero,
            contentPadding: EdgeInsets.zero,
            content: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: Dimensions.WEB_MAX_WIDTH * 0.4),
              child: content,
            ),
          );
        },
      );
    } else {
      showModalBottomSheet<void>(
        enableDrag: false,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTokens.r20)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        backgroundColor: AppTokens.surface(context),
        context: context,
        builder: (BuildContext context) {
          return content;
        },
      );
    }
  }

  // ==========================================================================
  //                     openBottomSheet2  (Timer expiry → auto)
  // No Cancel; Submit → timer?.cancel(); _generateReport(_userExamId).
  // ==========================================================================
  void openBottomSheet2(TestCategoryStore store) {
    final String attempted = store.testQueMasterPalleteCount.value?.isAttempted
            .toString()
            .padLeft(2, '0') ??
        "0";
    final String markedForReview =
        store.testQueMasterPalleteCount.value?.isMarkedForReview
                .toString()
                .padLeft(2, '0') ??
            "0";
    final String skipped = store.testQueMasterPalleteCount.value?.isSkipped
            .toString()
            .padLeft(2, '0') ??
        "0";
    final String attemptedandMarkedForReview = store
            .testQueMasterPalleteCount.value?.isAttemptedMarkedForReview
            .toString()
            .padLeft(2, '0') ??
        "0";
    final String notVisited = store.testQueMasterPalleteCount.value?.notVisited
            .toString()
            .padLeft(2, '0') ??
        "0";
    final String guess = store.testQueMasterPalleteCount.value?.isGuess
            .toString()
            .padLeft(2, '0') ??
        "0";

    final content = _SubmissionSheet(
      title: "Test Submission",
      timeLabel: null,
      rows: [
        _SubmissionRow(
            color: Colors.green, label: "Attempted", value: attempted),
        _SubmissionRow(
            color: Colors.blue,
            label: "Marked for Review",
            value: markedForReview),
        _SubmissionRow(
            color: Colors.orangeAccent,
            label: "Attempted and Marked for Review",
            value: attemptedandMarkedForReview),
        _SubmissionRow(
            color: Colors.red, label: "Skipped", value: skipped),
        _SubmissionRow(color: Colors.brown, label: "Guess", value: guess),
        _SubmissionRow(
            color: AppTokens.ink(context),
            label: "Not Visited",
            value: notVisited),
      ],
      onCancel: null,
      onSubmit: () {
        timer?.cancel();
        _generateReport(_userExamId);
      },
    );

    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTokens.surface(context),
            surfaceTintColor: AppTokens.surface(context),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.r20)),
            actionsPadding: EdgeInsets.zero,
            contentPadding: EdgeInsets.zero,
            content: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: Dimensions.WEB_MAX_WIDTH * 0.4),
              child: content,
            ),
          );
        },
      );
    } else {
      showModalBottomSheet<void>(
        isDismissible: false,
        enableDrag: false,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTokens.r20)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        backgroundColor: AppTokens.surface(context),
        context: context,
        builder: (BuildContext context) {
          return content;
        },
      );
    }
  }

  String _formattedRemaining(Duration d) {
    return "${d.inHours.toString().padLeft(2, '0')}:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";
  }
}

// ============================================================================
//                               PRIMITIVES
// ============================================================================

class _CircleIconBtn extends StatelessWidget {
  const _CircleIconBtn({required this.icon, required this.onTap});
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
            color: AppTokens.surface(context),
            shape: BoxShape.circle,
            border: Border.all(color: AppTokens.border(context)),
            boxShadow: AppTokens.shadow1(context),
          ),
          child: Icon(icon, size: 18, color: AppTokens.ink(context)),
        ),
      ),
    );
  }
}

class _ReviewBtn extends StatelessWidget {
  const _ReviewBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTokens.r28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: BorderRadius.circular(AppTokens.r28),
            border: Border.all(color: AppTokens.accent(context)),
          ),
          child: Text(
            "Review",
            style: AppTokens.titleSm(context).copyWith(
              color: AppTokens.accent(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? activeColor : AppTokens.surface(context),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(
              color: active ? activeColor : AppTokens.border(context),
            ),
          ),
          child: Text(
            label,
            style: AppTokens.titleSm(context).copyWith(
              color: active ? Colors.white : AppTokens.ink(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavCircleBtn extends StatelessWidget {
  const _NavCircleBtn(
      {required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color c =
        enabled ? AppTokens.accent(context) : AppTokens.muted(context);
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: c, width: 1.2),
            color: AppTokens.surface(context),
          ),
          child: Icon(icon, size: 22, color: c),
        ),
      ),
    );
  }
}

class _SubmissionRow {
  const _SubmissionRow(
      {required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final String value;
}

class _SubmissionSheet extends StatelessWidget {
  const _SubmissionSheet({
    required this.title,
    required this.timeLabel,
    required this.rows,
    required this.onCancel,
    required this.onSubmit,
  });
  final String title;
  final String? timeLabel;
  final List<_SubmissionRow> rows;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s24,
          AppTokens.s24,
          AppTokens.s24,
          AppTokens.s20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppTokens.titleMd(context)),
            const SizedBox(height: AppTokens.s16),
            if (timeLabel != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Time Left",
                    style: AppTokens.body(context)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    timeLabel!,
                    style: AppTokens.titleSm(context).copyWith(
                      color: AppTokens.danger(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              Divider(
                height: 1,
                thickness: 1,
                color: AppTokens.border(context),
              ),
              const SizedBox(height: AppTokens.s12),
            ],
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTokens.s4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: r.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: Text(r.label, style: AppTokens.body(context)),
                    ),
                    Text(
                      r.value,
                      style: AppTokens.body(context)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Row(
              children: [
                if (onCancel != null) ...[
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTokens.s12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.r12),
                          side:
                              BorderSide(color: AppTokens.border(context)),
                        ),
                      ),
                      onPressed: onCancel,
                      child: Text(
                        "Cancel",
                        style: AppTokens.body(context)
                            .copyWith(color: AppTokens.ink2(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                ],
                Expanded(
                  child: Opacity(
                    opacity: onSubmit == null ? 0.5 : 1,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onSubmit,
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTokens.brand,
                                AppTokens.brand2
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppTokens.r12),
                            boxShadow: onSubmit == null
                                ? null
                                : AppTokens.shadow1(context),
                          ),
                          child: Text(
                            "Submit",
                            style: AppTokens.titleSm(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
