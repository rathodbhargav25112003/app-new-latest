// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names, dead_code, prefer_final_fields, use_build_context_synchronously, avoid_print, unused_element, unnecessary_string_interpolations, dead_null_aware_expression

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/api_service/exam_attempt_api.dart' show HeartbeatPayload, AnswerPatch;
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/constants.dart';
// Wave-2 lifecycle helper for the exam-mode attempt screen
import 'package:shusruta_lms/modules/new_exam_component/widgets/exam_attempt_attachment.dart';
import 'package:shusruta_lms/modules/test/question_pallet.dart';
import 'package:shusruta_lms/modules/test/question_pallet_drawer.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:vibration/vibration.dart';

import '../../app/routes.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/test_exampaper_list_model.dart';
import '../../services/resume_orchestrator.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_test_cancel_dialogbox.dart';

class TestExamScreen extends StatefulWidget {
  final TestExamPaperListModel? testExamPaper;
  final String? userExamId;
  final int? queNo;
  final bool? isPracticeExam;
  final ValueNotifier<Duration>? remainingTime;
  final String? id;
  final String? type;
  final bool? fromPallete;
  const TestExamScreen({
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
  State<TestExamScreen> createState() => _TestExamScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => TestExamScreen(
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

class _TestExamScreenState extends State<TestExamScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? timer;
  Duration? remainingTime;
  late ValueNotifier<Duration> remainingTimeNotifier;
  // Tracks whether remainingTimeNotifier has been initialized + disposed so
  // we don't double-dispose (time-out branch used to dispose it, and
  // widget.dispose() would then dispose it again → crash).
  bool _notifierInitialized = false;
  bool _notifierDisposed = false;
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

  TestExamPaperListModel? _testExamPaper;
  String? _userExamId;
  int? _queNo;
  bool? _isPracticeExam;
  ValueNotifier<Duration>? _remainingTime;
  String? _id;
  String? _type;
  bool? _fromPallete;
  bool isLoading = false;

  // Wave-2 attempt-lifecycle attachment — owns heartbeat to
  // /api/exam-attempt/:id/heartbeat + SharedPreferences crash-recovery
  // mirror + AppLifecycleState.paused flush. See exam_attempt_attachment.
  ExamAttemptAttachment? _att;

  @override
  void initState() {
    super.initState();

    // Initialize state variables with widget parameters
    _testExamPaper = widget.testExamPaper;
    _userExamId = widget.userExamId;
    _queNo = widget.queNo;
    _isPracticeExam = widget.isPracticeExam;
    _remainingTime = widget.remainingTime;
    _id = widget.id;
    _type = widget.type;
    _fromPallete = widget.fromPallete;

    init();

    setState(() {});

    // Wave-2: attach lifecycle helper. Ships current question + the
    // residual time-remaining in ms so resume restores the timer
    // accurately. Skipped when there's no userExamId (legacy paths).
    final uid = widget.userExamId;
    if (uid != null && uid.isNotEmpty) {
      _att = ExamAttemptAttachment(
        userExamId: uid,
        examId: widget.id,
        mode: 'continuous',
        readState: () {
          final List<dynamic>? tests = _testExamPaper?.test;
          final currentQ =
              (tests != null && _currentQuestionIndex >= 0 && _currentQuestionIndex < tests.length)
                  ? tests[_currentQuestionIndex]
                  : null;
          // Pull residual time from the existing remainingTimeNotifier
          // (set up by updateTimer). Falls back to widget input.
          int? remainingMs;
          try {
            final dur = _notifierInitialized && !_notifierDisposed
                ? remainingTimeNotifier.value
                : (_remainingTime?.value ?? Duration.zero);
            if (dur.inMilliseconds > 0) remainingMs = dur.inMilliseconds;
          } catch (_) {/* ignore */}
          return HeartbeatPayload(
            attemptId: uid,
            currentQuestionId: currentQ?.sId,
            timeRemainingMs: remainingMs,
            answers: const <AnswerPatch>[],
          );
        },
      )..attach();
    }
  }

  void init() {
    updateTimer();
    int matchingIndex = _testExamPaper?.test?.indexWhere((e) => e.questionNumber == _queNo) ?? -1;
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

  // Method to update the state variables
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

    _notifierInitialized = true;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (remainingTimeNotifier.value.inSeconds > 0) {
        remainingTimeNotifier.value = remainingTimeNotifier.value - const Duration(seconds: 1);
      } else {
        timer.cancel();
        // Don't dispose the notifier here — widget.dispose() owns its
        // lifecycle. Double-disposing a ValueNotifier throws.
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
    // if (state == AppLifecycleState.resumed) {
    //   debugPrint('app is resumed');
    //   if (remainingTimeNotifier.value.inSeconds > 0) {
    //     timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    //       if (remainingTimeNotifier.value.inSeconds > 0) {
    //         remainingTimeNotifier.value = remainingTimeNotifier.value - const Duration(seconds: 1);
    //       } else {
    //         timer.cancel();
    //         remainingTimeNotifier.dispose();
    //         BottomToast.showBottomToastOverlay(
    //           context: context,
    //           errorMessage: "Your Exam Time is Up!",
    //           backgroundColor: Theme.of(context).primaryColor,
    //         );
    //         _getCount2(_userExamId);
    //         // Navigator.of(context).pushNamed(Routes.reportsCategoryList, arguments: {
    //         //   'fromhome': true
    //         // });
    //       }
    //     });
    //   }
    // } else if (state == AppLifecycleState.paused) {
    //   timer?.cancel();
    // }
  }

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    if (_notifierInitialized && !_notifierDisposed) {
      _notifierDisposed = true;
      remainingTimeNotifier.dispose();
    }
    _att?.detach();
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
    setState(() {
      isLoading = true;
    });
    debugPrint("timeQues$time");
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.userAnswerTest(context, userExamId ?? "", questionId ?? "", selectedOption ?? "", isAttempted,
        isAttemptedAndMarkedForReview, isSkipped, isMarkedForReview, guess, time);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getSelectedAnswer(String queId) async {
    setState(() {
      isLoading = true;
    });
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.questionAnswerById(_userExamId ?? "", queId);
    setState(() {
      String? nextOption = (store.userAnswerExam.value?.guess?.isNotEmpty ?? false)
          ? store.userAnswerExam.value?.guess
          : store.userAnswerExam.value?.selectedOption;
      _selectedIndex = widget.testExamPaper?.test?[_currentQuestionIndex].optionsData
              ?.indexWhere((option) => option.value == nextOption) ??
          -1;
      guessed = (store.userAnswerExam.value?.guess?.isEmpty ?? false) ? false : true;
      print("guessed answer $guessed");
      isGuess = (store.userAnswerExam.value?.guess?.isNotEmpty ?? false) ? true : false;
      isMarkedForReview = store.userAnswerExam.value?.markedForReview ?? false;
      isAttemptedAndMarkedForReview = store.userAnswerExam.value?.attemptedMarkedForReview ?? false;
    });
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getCount(String? userExamId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.getQuestionPalleteCount(userExamId ?? "").then((_) {
      openBottomSheet(store);
    });
  }

  Future<void> _getCount2(String? userExamId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.getQuestionPalleteCount(userExamId ?? "").then((_) {
      openBottomSheet2(store);
    });
  }

  Future<void> _generateReport(String? userExamId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onReportExamApiCall(_userExamId ?? "").then((_) {
      Navigator.of(context).pushNamed(Routes.testReportScreen, arguments: {
        'report': store.reportsExam.value,
        'title': _testExamPaper?.examName,
        'userexamId': userExamId,
        'examId': _testExamPaper?.examId
      });
    });
  }

  void openBottomSheet(TestCategoryStore store) {
    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          String attempted = "0",
              markedForReview = "0",
              skipped = "0",
              attemptedandMarkedForReview = "0",
              notVisited = "0",
              guess = "0";
          attempted = store.testQuePalleteCount.value?.isAttempted.toString().padLeft(2, '0') ?? "0";
          markedForReview =
              store.testQuePalleteCount.value?.isMarkedForReview.toString().padLeft(2, '0') ?? "0";
          skipped = store.testQuePalleteCount.value?.isSkipped.toString().padLeft(2, '0') ?? "0";
          attemptedandMarkedForReview =
              store.testQuePalleteCount.value?.isAttemptedMarkedForReview.toString().padLeft(2, '0') ?? "0";
          notVisited = store.testQuePalleteCount.value?.notVisited.toString().padLeft(2, '0') ?? "0";
          guess = store.testQuePalleteCount.value?.isGuess.toString().padLeft(2, '0') ?? "0";
          return AlertDialog(
            backgroundColor: ThemeManager.mainBackground,
            actionsPadding: EdgeInsets.zero,
            actions: [
              Container(
                height: MediaQuery.of(context).size.height * 0.60,
                constraints: const BoxConstraints(maxWidth: Dimensions.WEB_MAX_WIDTH * 0.4),
                color: ThemeManager.reportContainer,
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                      bottom: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                      left: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                      right: Dimensions.PADDING_SIZE_EXTRA_LARGE),
                  child: Column(
                    children: [
                      Text(
                        "Test Submission",
                        style: interSemiBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          fontWeight: FontWeight.w600,
                          color: ThemeManager.black,
                        ),
                      ),
                      const SizedBox(
                        height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                      ),
                      Expanded(
                        child: Scrollbar(
                          controller: scrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Time Left",
                                        style: interSemiBold.copyWith(
                                          fontSize: Dimensions.fontSizeDefault,
                                          fontWeight: FontWeight.w600,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      Text(
                                        "${remainingTimeNotifier.value.inHours.toString().padLeft(2, '0')}:${remainingTimeNotifier.value.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTimeNotifier.value.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                                        style: interSemiBold.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w600,
                                          color: ThemeManager.redText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: Dimensions.PADDING_SIZE_SMALL,
                                  ),
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 5.0,
                                        backgroundColor: Colors.green,
                                      ),
                                      const SizedBox(
                                        width: Dimensions.PADDING_SIZE_SMALL,
                                      ),
                                      Text(
                                        "Attempted",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w400,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        attempted,
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeManager.black,
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    height: Dimensions.PADDING_SIZE_SMALL,
                                  ),
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 5.0,
                                        backgroundColor: Colors.blue,
                                      ),
                                      const SizedBox(
                                        width: Dimensions.PADDING_SIZE_SMALL,
                                      ),
                                      Text(
                                        "Marked for Review",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w400,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        markedForReview,
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeManager.black,
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 5.0,
                                        backgroundColor: Colors.orange,
                                      ),
                                      const SizedBox(
                                        width: Dimensions.PADDING_SIZE_SMALL,
                                      ),
                                      Text(
                                        "Attempted and Marked for Review",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w400,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        attemptedandMarkedForReview,
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeManager.black,
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 5.0,
                                        backgroundColor: Colors.red,
                                      ),
                                      const SizedBox(
                                        width: Dimensions.PADDING_SIZE_SMALL,
                                      ),
                                      Text(
                                        "Skipped",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w400,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        skipped,
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeManager.black,
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 5.0,
                                        backgroundColor: Colors.brown,
                                      ),
                                      const SizedBox(
                                        width: Dimensions.PADDING_SIZE_SMALL,
                                      ),
                                      Text(
                                        "Guess",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w400,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        guess,
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeManager.black,
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    height: Dimensions.PADDING_SIZE_SMALL,
                                  ),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 5.0,
                                        backgroundColor: ThemeManager.black,
                                      ),
                                      const SizedBox(
                                        width: Dimensions.PADDING_SIZE_SMALL,
                                      ),
                                      Text(
                                        "Not Visited",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w400,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        notVisited,
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeManager.black,
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT * 2.4),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: Dimensions.PADDING_SIZE_DEFAULT * 2,
                            right: Dimensions.PADDING_SIZE_LARGE * 2),
                        child: Text(
                          "Are you sure you want to submit the test?",
                          style: interSemiBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            fontWeight: FontWeight.w600,
                            color: ThemeManager.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // const Spacer(),
                      const SizedBox(
                        height: Dimensions.PADDING_SIZE_LARGE,
                      ),
                      // Row(
                      //   children: [
                      //     SizedBox(
                      //       width: MediaQuery.of(context).size.width * 0.4,
                      //       height: MediaQuery.of(context).size.height * 0.055,
                      //       child: ElevatedButton(
                      //           style: ElevatedButton.styleFrom(
                      //               shape: RoundedRectangleBorder(
                      //                 borderRadius: BorderRadius.circular(8),
                      //               ),
                      //               backgroundColor: ThemeManager.btnGrey
                      //           ),
                      //           onPressed: (){
                      //             Navigator.of(context).pop();
                      //           },
                      //           child: Text("Resume",
                      //             style: TextStyle(
                      //               fontSize: Dimensions.fontSizeDefault,
                      //               fontWeight: FontWeight.w400,
                      //               color: Colors.white,
                      //             ),)),
                      //     ),
                      //     const Spacer(),
                      //     SizedBox(
                      //       width: MediaQuery.of(context).size.width * 0.4,
                      //       height: MediaQuery.of(context).size.height * 0.055,
                      //       child: ElevatedButton(
                      //           style: ElevatedButton.styleFrom(
                      //               shape: RoundedRectangleBorder(
                      //                 borderRadius: BorderRadius.circular(8),
                      //               ),
                      //               backgroundColor: Theme.of(context).primaryColor
                      //           ),
                      //           onPressed: (){
                      //             remainingTimeNotifier.dispose();
                      //             _generateReport(_userExamId);
                      //           },
                      //           child: Text("Submit",
                      //             style: TextStyle(
                      //               fontSize: Dimensions.fontSizeDefault,
                      //               fontWeight: FontWeight.w400,
                      //               color: ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.white : Colors.white,
                      //             ),)),
                      //     ),
                      //   ],
                      // ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_LARGE * 1.2),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  height: Dimensions.PADDING_SIZE_LARGE * 2.7,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      border: Border.all(color: ThemeManager.mainBorder),
                                      color: ThemeManager.secondaryBlue,
                                      borderRadius: BorderRadius.circular(7),
                                      boxShadow: ThemeManager.currentTheme == AppTheme.Dark
                                          ? []
                                          : [
                                              BoxShadow(
                                                  offset: const Offset(0, 1.7733),
                                                  blurRadius: 3.5467,
                                                  spreadRadius: 0,
                                                  color: ThemeManager.dropShadow.withOpacity(0.16)),
                                              BoxShadow(
                                                  offset: const Offset(0, 0),
                                                  blurRadius: 0.8866,
                                                  spreadRadius: 0,
                                                  color: ThemeManager.dropShadow2.withOpacity(0.04)),
                                            ]),
                                  child: Text(
                                    "Cancel",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeLarge,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: Dimensions.PADDING_SIZE_SMALL * 1.6,
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  if (await Vibration.hasVibrator() ?? false) {
                                    Vibration.vibrate();
                                  }
                                  // remainingTimeNotifier.dispose();
                                  timer?.cancel();
                                  _generateReport(_userExamId);
                                },
                                child: Container(
                                  height: Dimensions.PADDING_SIZE_LARGE * 2.7,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: ThemeManager.blueprimary,
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(color: ThemeManager.buttonBorder, width: 0.89),
                                      boxShadow: [
                                        BoxShadow(
                                            offset: const Offset(0, 1.7733),
                                            blurRadius: 3.5467,
                                            spreadRadius: 0,
                                            color: ThemeManager.dropShadow.withOpacity(0.16)),
                                        BoxShadow(
                                            offset: const Offset(0, 0),
                                            blurRadius: 0.8866,
                                            spreadRadius: 0,
                                            color: ThemeManager.dropShadow2.withOpacity(0.04)),
                                      ]),
                                  child: Text(
                                    "Submit",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeLarge,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      showModalBottomSheet<void>(
        isDismissible: false,
        enableDrag: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          String attempted = "0",
              markedForReview = "0",
              skipped = "0",
              attemptedandMarkedForReview = "0",
              notVisited = "0",
              guess = "0";
          attempted = store.testQuePalleteCount.value?.isAttempted.toString().padLeft(2, '0') ?? "0";
          markedForReview =
              store.testQuePalleteCount.value?.isMarkedForReview.toString().padLeft(2, '0') ?? "0";
          skipped = store.testQuePalleteCount.value?.isSkipped.toString().padLeft(2, '0') ?? "0";
          attemptedandMarkedForReview =
              store.testQuePalleteCount.value?.isAttemptedMarkedForReview.toString().padLeft(2, '0') ?? "0";
          notVisited = store.testQuePalleteCount.value?.notVisited.toString().padLeft(2, '0') ?? "0";
          guess = store.testQuePalleteCount.value?.isGuess.toString().padLeft(2, '0') ?? "0";
          return Container(
            // height: MediaQuery.of(context).size.height * 0.60,
            color: ThemeManager.reportContainer,
            child: Padding(
              padding: const EdgeInsets.only(
                  top: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                  bottom: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                  left: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                  right: Dimensions.PADDING_SIZE_EXTRA_LARGE),
              child: Column(
                children: [
                  Text(
                    "Test Submission",
                    style: interSemiBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                      color: ThemeManager.black,
                    ),
                  ),
                  const SizedBox(
                    height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                  ),
                  Expanded(
                    child: Scrollbar(
                      controller: scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Time Left",
                                    style: interSemiBold.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                      fontWeight: FontWeight.w600,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  Text(
                                    "${remainingTimeNotifier.value.inHours.toString().padLeft(2, '0')}:${remainingTimeNotifier.value.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTimeNotifier.value.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                                    style: interSemiBold.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w600,
                                      color: ThemeManager.redText,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: Dimensions.PADDING_SIZE_SMALL,
                              ),
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 5.0,
                                    backgroundColor: Colors.green,
                                  ),
                                  const SizedBox(
                                    width: Dimensions.PADDING_SIZE_SMALL,
                                  ),
                                  Text(
                                    "Attempted",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w400,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    attempted,
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w500,
                                      color: ThemeManager.black,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(
                                height: Dimensions.PADDING_SIZE_SMALL,
                              ),
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 5.0,
                                    backgroundColor: Colors.blue,
                                  ),
                                  const SizedBox(
                                    width: Dimensions.PADDING_SIZE_SMALL,
                                  ),
                                  Text(
                                    "Marked for Review",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w400,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    markedForReview,
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w500,
                                      color: ThemeManager.black,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 5.0,
                                    backgroundColor: Colors.orange,
                                  ),
                                  const SizedBox(
                                    width: Dimensions.PADDING_SIZE_SMALL,
                                  ),
                                  Text(
                                    "Attempted and Marked for Review",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w400,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    attemptedandMarkedForReview,
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w500,
                                      color: ThemeManager.black,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 5.0,
                                    backgroundColor: Colors.red,
                                  ),
                                  const SizedBox(
                                    width: Dimensions.PADDING_SIZE_SMALL,
                                  ),
                                  Text(
                                    "Skipped",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w400,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    skipped,
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w500,
                                      color: ThemeManager.black,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 5.0,
                                    backgroundColor: Colors.brown,
                                  ),
                                  const SizedBox(
                                    width: Dimensions.PADDING_SIZE_SMALL,
                                  ),
                                  Text(
                                    "Guess",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w400,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    guess,
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w500,
                                      color: ThemeManager.black,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(
                                height: Dimensions.PADDING_SIZE_SMALL,
                              ),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 5.0,
                                    backgroundColor: ThemeManager.black,
                                  ),
                                  const SizedBox(
                                    width: Dimensions.PADDING_SIZE_SMALL,
                                  ),
                                  Text(
                                    "Not Visited",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w400,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    notVisited,
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w500,
                                      color: ThemeManager.black,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT * 2.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: Dimensions.PADDING_SIZE_DEFAULT * 2, right: Dimensions.PADDING_SIZE_LARGE * 2),
                    child: Text(
                      "Are you sure you want to submit the test?",
                      style: interSemiBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        fontWeight: FontWeight.w600,
                        color: ThemeManager.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // const Spacer(),
                  const SizedBox(
                    height: Dimensions.PADDING_SIZE_LARGE,
                  ),
                  // Row(
                  //   children: [
                  //     SizedBox(
                  //       width: MediaQuery.of(context).size.width * 0.4,
                  //       height: MediaQuery.of(context).size.height * 0.055,
                  //       child: ElevatedButton(
                  //           style: ElevatedButton.styleFrom(
                  //               shape: RoundedRectangleBorder(
                  //                 borderRadius: BorderRadius.circular(8),
                  //               ),
                  //               backgroundColor: ThemeManager.btnGrey
                  //           ),
                  //           onPressed: (){
                  //             Navigator.of(context).pop();
                  //           },
                  //           child: Text("Resume",
                  //             style: TextStyle(
                  //               fontSize: Dimensions.fontSizeDefault,
                  //               fontWeight: FontWeight.w400,
                  //               color: Colors.white,
                  //             ),)),
                  //     ),
                  //     const Spacer(),
                  //     SizedBox(
                  //       width: MediaQuery.of(context).size.width * 0.4,
                  //       height: MediaQuery.of(context).size.height * 0.055,
                  //       child: ElevatedButton(
                  //           style: ElevatedButton.styleFrom(
                  //               shape: RoundedRectangleBorder(
                  //                 borderRadius: BorderRadius.circular(8),
                  //               ),
                  //               backgroundColor: Theme.of(context).primaryColor
                  //           ),
                  //           onPressed: (){
                  //             remainingTimeNotifier.dispose();
                  //             _generateReport(_userExamId);
                  //           },
                  //           child: Text("Submit",
                  //             style: TextStyle(
                  //               fontSize: Dimensions.fontSizeDefault,
                  //               fontWeight: FontWeight.w400,
                  //               color: ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.white : Colors.white,
                  //             ),)),
                  //     ),
                  //   ],
                  // ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_LARGE * 1.2),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              height: Dimensions.PADDING_SIZE_LARGE * 2.7,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  border: Border.all(color: ThemeManager.mainBorder),
                                  color: ThemeManager.secondaryBlue,
                                  borderRadius: BorderRadius.circular(7),
                                  boxShadow: ThemeManager.currentTheme == AppTheme.Dark
                                      ? []
                                      : [
                                          BoxShadow(
                                              offset: const Offset(0, 1.7733),
                                              blurRadius: 3.5467,
                                              spreadRadius: 0,
                                              color: ThemeManager.dropShadow.withOpacity(0.16)),
                                          BoxShadow(
                                              offset: const Offset(0, 0),
                                              blurRadius: 0.8866,
                                              spreadRadius: 0,
                                              color: ThemeManager.dropShadow2.withOpacity(0.04)),
                                        ]),
                              child: Text(
                                "Cancel",
                                style: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeLarge,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: Dimensions.PADDING_SIZE_SMALL * 1.6,
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              if (await Vibration.hasVibrator() ?? false) {
                                Vibration.vibrate();
                              }
                              // remainingTimeNotifier.dispose();
                              timer?.cancel();
                              _generateReport(_userExamId);
                            },
                            child: Container(
                              height: Dimensions.PADDING_SIZE_LARGE * 2.7,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: ThemeManager.blueprimary,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(color: ThemeManager.buttonBorder, width: 0.89),
                                  boxShadow: [
                                    BoxShadow(
                                        offset: const Offset(0, 1.7733),
                                        blurRadius: 3.5467,
                                        spreadRadius: 0,
                                        color: ThemeManager.dropShadow.withOpacity(0.16)),
                                    BoxShadow(
                                        offset: const Offset(0, 0),
                                        blurRadius: 0.8866,
                                        spreadRadius: 0,
                                        color: ThemeManager.dropShadow2.withOpacity(0.04)),
                                  ]),
                              child: Text(
                                "Submit",
                                style: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeLarge,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
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
  }

  void openBottomSheet2(TestCategoryStore store) {
    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          String attempted = "0",
              markedForReview = "0",
              skipped = "0",
              attemptedandMarkedForReview = "0",
              notVisited = "0",
              guess = "0";
          attempted = store.testQuePalleteCount.value?.isAttempted.toString().padLeft(2, '0') ?? "0";
          markedForReview =
              store.testQuePalleteCount.value?.isMarkedForReview.toString().padLeft(2, '0') ?? "0";
          skipped = store.testQuePalleteCount.value?.isSkipped.toString().padLeft(2, '0') ?? "0";
          attemptedandMarkedForReview =
              store.testQuePalleteCount.value?.isAttemptedMarkedForReview.toString().padLeft(2, '0') ?? "0";
          notVisited = store.testQuePalleteCount.value?.notVisited.toString().padLeft(2, '0') ?? "0";
          guess = store.testQuePalleteCount.value?.isGuess.toString().padLeft(2, '0') ?? "0";
          return AlertDialog(
            backgroundColor: ThemeManager.mainBackground,
            actionsPadding: EdgeInsets.zero,
            actions: [
              Container(
                height: MediaQuery.of(context).size.height * 0.60,
                constraints: const BoxConstraints(maxWidth: Dimensions.WEB_MAX_WIDTH * 0.4),
                color: ThemeManager.reportContainer,
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                      bottom: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                      left: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                      right: Dimensions.PADDING_SIZE_EXTRA_LARGE),
                  child: Column(
                    children: [
                      Text(
                        "Test Submission",
                        style: interSemiBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          fontWeight: FontWeight.w600,
                          color: ThemeManager.black,
                        ),
                      ),
                      const SizedBox(
                        height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                      ),
                      Expanded(
                        child: Scrollbar(
                          controller: scrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  // Row(
                                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  //   children: [
                                  //     Text("Time Left",
                                  //       style: interSemiBold.copyWith(
                                  //         fontSize: Dimensions.fontSizeDefault,
                                  //         fontWeight: FontWeight.w600,
                                  //         color: ThemeManager.black,
                                  //       ),),
                                  //     Text("${remainingTimeNotifier.value.inHours.toString().padLeft(2, '0')}:${remainingTimeNotifier.value!.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTimeNotifier.value!.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                                  //       style: interSemiBold.copyWith(
                                  //         fontSize: Dimensions.fontSizeSmallLarge,
                                  //         fontWeight: FontWeight.w600,
                                  //         color: ThemeManager.redText,
                                  //       ),),
                                  //   ],
                                  // ),
                                  // const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 5.0,
                                        backgroundColor: Colors.green,
                                      ),
                                      const SizedBox(
                                        width: Dimensions.PADDING_SIZE_SMALL,
                                      ),
                                      Text(
                                        "Attempted",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w400,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        attempted,
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeManager.black,
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    height: Dimensions.PADDING_SIZE_SMALL,
                                  ),
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 5.0,
                                        backgroundColor: Colors.blue,
                                      ),
                                      const SizedBox(
                                        width: Dimensions.PADDING_SIZE_SMALL,
                                      ),
                                      Text(
                                        "Marked1 for Review",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w400,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        markedForReview,
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeManager.black,
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 5.0,
                                        backgroundColor: Colors.orange,
                                      ),
                                      const SizedBox(
                                        width: Dimensions.PADDING_SIZE_SMALL,
                                      ),
                                      Text(
                                        "Attempted and Marked for Review",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w400,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        attemptedandMarkedForReview,
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeManager.black,
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 5.0,
                                        backgroundColor: Colors.red,
                                      ),
                                      const SizedBox(
                                        width: Dimensions.PADDING_SIZE_SMALL,
                                      ),
                                      Text(
                                        "Skipped",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w400,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        skipped,
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeManager.black,
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 5.0,
                                        backgroundColor: Colors.brown,
                                      ),
                                      const SizedBox(
                                        width: Dimensions.PADDING_SIZE_SMALL,
                                      ),
                                      Text(
                                        "Guess",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w400,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        guess,
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeManager.black,
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    height: Dimensions.PADDING_SIZE_SMALL,
                                  ),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 5.0,
                                        backgroundColor: ThemeManager.black,
                                      ),
                                      const SizedBox(
                                        width: Dimensions.PADDING_SIZE_SMALL,
                                      ),
                                      Text(
                                        "Not Visited",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w400,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        notVisited,
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeManager.black,
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT * 2.4),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.only(left: Dimensions.PADDING_SIZE_DEFAULT * 2,
                      //       right: Dimensions.PADDING_SIZE_LARGE * 2),
                      //   child: Text("Are you sure you want to submit the test?",
                      //     style: interSemiBold.copyWith(
                      //       fontSize: Dimensions.fontSizeLarge,
                      //       fontWeight: FontWeight.w600,
                      //       color: ThemeManager.black,
                      //     ),
                      //     textAlign: TextAlign.center,),
                      // ),
                      // // const Spacer(),
                      // const SizedBox(height: Dimensions.PADDING_SIZE_LARGE,),
                      // Row(
                      //   children: [
                      //     SizedBox(
                      //       width: MediaQuery.of(context).size.width * 0.4,
                      //       height: MediaQuery.of(context).size.height * 0.055,
                      //       child: ElevatedButton(
                      //           style: ElevatedButton.styleFrom(
                      //               shape: RoundedRectangleBorder(
                      //                 borderRadius: BorderRadius.circular(8),
                      //               ),
                      //               backgroundColor: ThemeManager.btnGrey
                      //           ),
                      //           onPressed: (){
                      //             Navigator.of(context).pop();
                      //           },
                      //           child: Text("Resume",
                      //             style: TextStyle(
                      //               fontSize: Dimensions.fontSizeDefault,
                      //               fontWeight: FontWeight.w400,
                      //               color: Colors.white,
                      //             ),)),
                      //     ),
                      //     const Spacer(),
                      //     SizedBox(
                      //       width: MediaQuery.of(context).size.width * 0.4,
                      //       height: MediaQuery.of(context).size.height * 0.055,
                      //       child: ElevatedButton(
                      //           style: ElevatedButton.styleFrom(
                      //               shape: RoundedRectangleBorder(
                      //                 borderRadius: BorderRadius.circular(8),
                      //               ),
                      //               backgroundColor: Theme.of(context).primaryColor
                      //           ),
                      //           onPressed: (){
                      //             remainingTimeNotifier.dispose();
                      //             _generateReport(_userExamId);
                      //           },
                      //           child: Text("Submit",
                      //             style: TextStyle(
                      //               fontSize: Dimensions.fontSizeDefault,
                      //               fontWeight: FontWeight.w400,
                      //               color: ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.white : Colors.white,
                      //             ),)),
                      //     ),
                      //   ],
                      // ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_LARGE * 1.2),
                        child: Row(
                          children: [
                            // Expanded(
                            //   child: InkWell(
                            //     onTap: (){
                            //       Navigator.of(context).pop();
                            //     },
                            //     child: Container(
                            //       height: Dimensions.PADDING_SIZE_LARGE*2.7,
                            //       alignment: Alignment.center,
                            //       decoration: BoxDecoration(
                            //         color:ThemeManager.secondaryBlue,
                            //         borderRadius: BorderRadius.circular(7),
                            //         boxShadow: [
                            //           BoxShadow(
                            //             offset: const Offset(0, 1.7733),
                            //             blurRadius: 3.5467,
                            //             spreadRadius: 0,
                            //             color: ThemeManager.dropShadow.withOpacity(0.16)
                            //           ),
                            //           BoxShadow(
                            //               offset: const Offset(0, 0),
                            //               blurRadius: 0.8866,
                            //               spreadRadius: 0,
                            //               color: ThemeManager.dropShadow2.withOpacity(0.04)
                            //           ),
                            //         ]
                            //       ),
                            //       child: Text("Cancel",
                            //         style: interRegular.copyWith(
                            //           fontSize: Dimensions.fontSizeLarge,
                            //           fontWeight: FontWeight.w700,
                            //           color: ThemeManager.white,
                            //         ),),
                            //     ),
                            //   ),
                            // ),
                            // const SizedBox(width: Dimensions.PADDING_SIZE_SMALL*1.6,),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  // remainingTimeNotifier.dispose();
                                  timer?.cancel();
                                  _generateReport(_userExamId);
                                },
                                child: Container(
                                  height: Dimensions.PADDING_SIZE_LARGE * 2.7,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: ThemeManager.blueprimary,
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(color: ThemeManager.buttonBorder, width: 0.89),
                                      boxShadow: [
                                        BoxShadow(
                                            offset: const Offset(0, 1.7733),
                                            blurRadius: 3.5467,
                                            spreadRadius: 0,
                                            color: ThemeManager.dropShadow.withOpacity(0.16)),
                                        BoxShadow(
                                            offset: const Offset(0, 0),
                                            blurRadius: 0.8866,
                                            spreadRadius: 0,
                                            color: ThemeManager.dropShadow2.withOpacity(0.04)),
                                      ]),
                                  child: Text(
                                    "Submit",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeLarge,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      showModalBottomSheet<void>(
        isDismissible: false,
        enableDrag: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          String attempted = "0",
              markedForReview = "0",
              skipped = "0",
              attemptedandMarkedForReview = "0",
              notVisited = "0",
              guess = "0";
          attempted = store.testQuePalleteCount.value?.isAttempted.toString().padLeft(2, '0') ?? "0";
          markedForReview =
              store.testQuePalleteCount.value?.isMarkedForReview.toString().padLeft(2, '0') ?? "0";
          skipped = store.testQuePalleteCount.value?.isSkipped.toString().padLeft(2, '0') ?? "0";
          attemptedandMarkedForReview =
              store.testQuePalleteCount.value?.isAttemptedMarkedForReview.toString().padLeft(2, '0') ?? "0";
          notVisited = store.testQuePalleteCount.value?.notVisited.toString().padLeft(2, '0') ?? "0";
          guess = store.testQuePalleteCount.value?.isGuess.toString().padLeft(2, '0') ?? "0";
          return Container(
            // height: MediaQuery.of(context).size.height * 0.60,
            color: ThemeManager.reportContainer,
            child: Padding(
              padding: const EdgeInsets.only(
                  top: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                  bottom: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                  left: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                  right: Dimensions.PADDING_SIZE_EXTRA_LARGE),
              child: Column(
                children: [
                  Text(
                    "Test Submission",
                    style: interSemiBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                      color: ThemeManager.black,
                    ),
                  ),
                  const SizedBox(
                    height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                  ),
                  Expanded(
                    child: Scrollbar(
                      controller: scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              //   children: [
                              //     Text("Time Left",
                              //       style: interSemiBold.copyWith(
                              //         fontSize: Dimensions.fontSizeDefault,
                              //         fontWeight: FontWeight.w600,
                              //         color: ThemeManager.black,
                              //       ),),
                              //     Text("${remainingTimeNotifier.value.inHours.toString().padLeft(2, '0')}:${remainingTimeNotifier.value!.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTimeNotifier.value!.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                              //       style: interSemiBold.copyWith(
                              //         fontSize: Dimensions.fontSizeSmallLarge,
                              //         fontWeight: FontWeight.w600,
                              //         color: ThemeManager.redText,
                              //       ),),
                              //   ],
                              // ),
                              // const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 5.0,
                                    backgroundColor: Colors.green,
                                  ),
                                  const SizedBox(
                                    width: Dimensions.PADDING_SIZE_SMALL,
                                  ),
                                  Text(
                                    "Attempted",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w400,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    attempted,
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w500,
                                      color: ThemeManager.black,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(
                                height: Dimensions.PADDING_SIZE_SMALL,
                              ),
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 5.0,
                                    backgroundColor: Colors.blue,
                                  ),
                                  const SizedBox(
                                    width: Dimensions.PADDING_SIZE_SMALL,
                                  ),
                                  Text(
                                    "Marked1 for Review",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w400,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    markedForReview,
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w500,
                                      color: ThemeManager.black,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 5.0,
                                    backgroundColor: Colors.orange,
                                  ),
                                  const SizedBox(
                                    width: Dimensions.PADDING_SIZE_SMALL,
                                  ),
                                  Text(
                                    "Attempted and Marked for Review",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w400,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    attemptedandMarkedForReview,
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w500,
                                      color: ThemeManager.black,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 5.0,
                                    backgroundColor: Colors.red,
                                  ),
                                  const SizedBox(
                                    width: Dimensions.PADDING_SIZE_SMALL,
                                  ),
                                  Text(
                                    "Skipped",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w400,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    skipped,
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w500,
                                      color: ThemeManager.black,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 5.0,
                                    backgroundColor: Colors.brown,
                                  ),
                                  const SizedBox(
                                    width: Dimensions.PADDING_SIZE_SMALL,
                                  ),
                                  Text(
                                    "Guess",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w400,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    guess,
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w500,
                                      color: ThemeManager.black,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(
                                height: Dimensions.PADDING_SIZE_SMALL,
                              ),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 5.0,
                                    backgroundColor: ThemeManager.black,
                                  ),
                                  const SizedBox(
                                    width: Dimensions.PADDING_SIZE_SMALL,
                                  ),
                                  Text(
                                    "Not Visited",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w400,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    notVisited,
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      fontWeight: FontWeight.w500,
                                      color: ThemeManager.black,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT * 2.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.only(left: Dimensions.PADDING_SIZE_DEFAULT * 2,
                  //       right: Dimensions.PADDING_SIZE_LARGE * 2),
                  //   child: Text("Are you sure you want to submit the test?",
                  //     style: interSemiBold.copyWith(
                  //       fontSize: Dimensions.fontSizeLarge,
                  //       fontWeight: FontWeight.w600,
                  //       color: ThemeManager.black,
                  //     ),
                  //     textAlign: TextAlign.center,),
                  // ),
                  // // const Spacer(),
                  // const SizedBox(height: Dimensions.PADDING_SIZE_LARGE,),
                  // Row(
                  //   children: [
                  //     SizedBox(
                  //       width: MediaQuery.of(context).size.width * 0.4,
                  //       height: MediaQuery.of(context).size.height * 0.055,
                  //       child: ElevatedButton(
                  //           style: ElevatedButton.styleFrom(
                  //               shape: RoundedRectangleBorder(
                  //                 borderRadius: BorderRadius.circular(8),
                  //               ),
                  //               backgroundColor: ThemeManager.btnGrey
                  //           ),
                  //           onPressed: (){
                  //             Navigator.of(context).pop();
                  //           },
                  //           child: Text("Resume",
                  //             style: TextStyle(
                  //               fontSize: Dimensions.fontSizeDefault,
                  //               fontWeight: FontWeight.w400,
                  //               color: Colors.white,
                  //             ),)),
                  //     ),
                  //     const Spacer(),
                  //     SizedBox(
                  //       width: MediaQuery.of(context).size.width * 0.4,
                  //       height: MediaQuery.of(context).size.height * 0.055,
                  //       child: ElevatedButton(
                  //           style: ElevatedButton.styleFrom(
                  //               shape: RoundedRectangleBorder(
                  //                 borderRadius: BorderRadius.circular(8),
                  //               ),
                  //               backgroundColor: Theme.of(context).primaryColor
                  //           ),
                  //           onPressed: (){
                  //             remainingTimeNotifier.dispose();
                  //             _generateReport(_userExamId);
                  //           },
                  //           child: Text("Submit",
                  //             style: TextStyle(
                  //               fontSize: Dimensions.fontSizeDefault,
                  //               fontWeight: FontWeight.w400,
                  //               color: ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.white : Colors.white,
                  //             ),)),
                  //     ),
                  //   ],
                  // ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_LARGE * 1.2),
                    child: Row(
                      children: [
                        // Expanded(
                        //   child: InkWell(
                        //     onTap: (){
                        //       Navigator.of(context).pop();
                        //     },
                        //     child: Container(
                        //       height: Dimensions.PADDING_SIZE_LARGE*2.7,
                        //       alignment: Alignment.center,
                        //       decoration: BoxDecoration(
                        //         color:ThemeManager.secondaryBlue,
                        //         borderRadius: BorderRadius.circular(7),
                        //         boxShadow: [
                        //           BoxShadow(
                        //             offset: const Offset(0, 1.7733),
                        //             blurRadius: 3.5467,
                        //             spreadRadius: 0,
                        //             color: ThemeManager.dropShadow.withOpacity(0.16)
                        //           ),
                        //           BoxShadow(
                        //               offset: const Offset(0, 0),
                        //               blurRadius: 0.8866,
                        //               spreadRadius: 0,
                        //               color: ThemeManager.dropShadow2.withOpacity(0.04)
                        //           ),
                        //         ]
                        //       ),
                        //       child: Text("Cancel",
                        //         style: interRegular.copyWith(
                        //           fontSize: Dimensions.fontSizeLarge,
                        //           fontWeight: FontWeight.w700,
                        //           color: ThemeManager.white,
                        //         ),),
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(width: Dimensions.PADDING_SIZE_SMALL*1.6,),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              // remainingTimeNotifier.dispose();
                              timer?.cancel();
                              _generateReport(_userExamId);
                            },
                            child: Container(
                              height: Dimensions.PADDING_SIZE_LARGE * 2.7,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: ThemeManager.blueprimary,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(color: ThemeManager.buttonBorder, width: 0.89),
                                  boxShadow: [
                                    BoxShadow(
                                        offset: const Offset(0, 1.7733),
                                        blurRadius: 3.5467,
                                        spreadRadius: 0,
                                        color: ThemeManager.dropShadow.withOpacity(0.16)),
                                    BoxShadow(
                                        offset: const Offset(0, 0),
                                        blurRadius: 0.8866,
                                        spreadRadius: 0,
                                        color: ThemeManager.dropShadow2.withOpacity(0.04)),
                                  ]),
                              child: Text(
                                "Submit",
                                style: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeLarge,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
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
  }

  Future<void> _showNextQuestion() async {
    firstQue = false;
    guessed = false;
    String? questionId = _testExamPaper?.test?[_currentQuestionIndex].sId;

    String? selectedOption = _selectedIndex == -1
        ? ""
        : _testExamPaper?.test?[_currentQuestionIndex].optionsData?[_selectedIndex].value;
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
          usedExamTime ?? "00:00:00");
    } else {
      await _postSelectedAnswerApiCall(_userExamId, selectedOption, questionId, isAttempted,
          isAttemptedAndMarkedForReview, isSkipped, isMarkedForReview, "", usedExamTime ?? "00:00:00");
    }
    isAttempted = false;
    isSkipped = false;
    isAttemptedAndMarkedForReview = false;
    isMarkedForReview = false;
    isGuess = false;

    setState(() {
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
      _getSelectedAnswer(questionId1 ?? "");

      questionWidget = getQuestionText(context);
    });
  }

  Future<void> _saveQuestion() async {
    firstQue = false;
    guessed = false;
    String? questionId = _testExamPaper?.test?[_currentQuestionIndex].sId;

    String? selectedOption = _selectedIndex == -1
        ? ""
        : _testExamPaper?.test?[_currentQuestionIndex].optionsData?[_selectedIndex].value;
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
          usedExamTime ?? "00:00:00");
    } else {
      await _postSelectedAnswerApiCall(_userExamId, selectedOption, questionId, isAttempted,
          isAttemptedAndMarkedForReview, isSkipped, isMarkedForReview, "", usedExamTime ?? "00:00:00");
    }
    isAttempted = false;
    isSkipped = false;
    isAttemptedAndMarkedForReview = false;
    isMarkedForReview = false;
    isGuess = false;
  }

  Future<void> _NextQuestion() async {
    setState(() {
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
      _getSelectedAnswer(questionId1 ?? "");

      questionWidget = getQuestionText(context);
    });
  }

  void _showPreviousQuestion() {
    guessed = false;
    setState(() {
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
      _getSelectedAnswer(questionId ?? "");

      questionWidget = getQuestionText(context);

      // String base64String = (_testExamPaper?.test?[_currentQuestionIndex].questionImg?.isNotEmpty ?? false)
      //     ? _testExamPaper!.test![_currentQuestionIndex].questionImg![0] : "";
      // try {
      //   quesImgBytes = base64Decode(base64String);
      // } catch (e) {
      //   debugPrint("Error decoding base64 string: $e");
      // }
    });
  }

  Widget getQuestionText(BuildContext context) {
    if (_testExamPaper?.test == null ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= (_testExamPaper?.test?.length ?? 0)) {
      return Center(
        child: Text(
          "No filtered data available",
          style: interRegular.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            fontWeight: FontWeight.w400,
            color: ThemeManager.black,
          ),
        ),
      );
    }

    String questionTxt = _testExamPaper?.test?[_currentQuestionIndex].questionText ?? "";
    questionTxt =
        questionTxt.replaceAllMapped(RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    List<String> splittedText = questionTxt.split("splittedImage");
    List<Widget> columns = [];
    int index = 0;
    for (String text in splittedText) {
      List<Widget> questionImageWidget = [];
      if (_testExamPaper?.test?[_currentQuestionIndex].questionImg?.isNotEmpty ?? false) {
        for (String base64String in _testExamPaper!.test![_currentQuestionIndex].questionImg!) {
          try {
            // Uint8List quesImgBytes = base64Decode(base64String);
            questionImageWidget.add(
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        child: PhotoView(
                          // imageProvider: MemoryImage(quesImgBytes),
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
                            // width: MediaQuery.of(context).size.width,
                            // height: MediaQuery.of(context).size.height * 0.4,
                            child: Stack(
                              children: [
                                // Image.memory(quesImgBytes),
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
              text.trim().replaceAll(RegExp(r'\n{2,}'), '\n').trim().replaceAll("--", "•"),
              textAlign: TextAlign.left,
              style: interBlack.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                fontWeight: FontWeight.w500,
                color: ThemeManager.black,
              ),
            ),
            const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: questionImageWidget,
            ),
            const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
            questionImageWidget.isNotEmpty
                ? Text(
                    "Tap the image to zoom In/Out",
                    style: interBlack.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      fontWeight: FontWeight.w500,
                      color: ThemeManager.black,
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      );
      index++;
      if (index >= (_testExamPaper?.test?[_currentQuestionIndex].questionImg?.length ?? 0) - 1) {
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
        builder: (context) => CustomTestCancelDialogBox(timer, remainingTimeNotifier, false),
      );
      return confirmExit ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    String? selectedOption = _selectedIndex == -1
        ? ""
        : _testExamPaper?.test?[_currentQuestionIndex].optionsData?[_selectedIndex].value;

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
            surfaceTintColor: AppTokens.surface(context),
            title: Padding(
              padding: const EdgeInsets.only(left: Dimensions.PADDING_SIZE_DEFAULT * 1.2),
              child: Row(
                children: [
                  // Text(
                  //   _testExamPaper?.examName??"Test",
                  //   style: interRegular.copyWith(
                  //     fontSize: Dimensions.fontSizeLarge,
                  //     fontWeight: FontWeight.w500,
                  //     color: Colors.white,
                  //   ),
                  // ),
                  InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              CustomTestCancelDialogBox(timer, remainingTimeNotifier, false),
                        );
                      },
                      child: SvgPicture.asset(
                        "assets/image/arrow_back.svg",
                        color: ThemeManager.currentTheme == AppTheme.Dark ? AppColors.white : null,
                      )),
                  // const Spacer(),
                  //       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,onPressed: (){
                  //   showDialog(
                  //     context: context,
                  //     builder: (context) => CustomTestCancelDialogBox(timer,remainingTimeNotifier,false),
                  //   );
                  // }, icon: const Icon(Icons.close,color: Colors.white,)),
                  if (!(MediaQuery.of(context).size.width > 1160 && MediaQuery.of(context).size.height > 690))
                    const SizedBox(
                      width: Dimensions.RADIUS_EXTRA_LARGE * 1.1,
                    ),
                  if (!(MediaQuery.of(context).size.width > 1160 && MediaQuery.of(context).size.height > 690))
                    InkWell(
                      onTap: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      child: Image.asset(
                        "assets/image/questionplatte.png",
                        width: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                      ),
                    ),
                  const Spacer(),
                  // SvgPicture.asset(
                  //   "assets/image/testTimeIcon.svg",
                  //   color: ThemeManager.currentTheme == AppTheme.Dark
                  //       ? AppColors.white
                  //       : null,
                  // ),
                  ValueListenableBuilder<Duration>(
                    valueListenable: remainingTimeNotifier,
                    builder: (context, remainingTime, child) {
                      return Text(
                        " ${remainingTime.inHours.toString().padLeft(2, '0')}:${remainingTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTime.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          fontWeight: FontWeight.w500,
                          color: ThemeManager.black,
                        ),
                      );
                    },
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 5,
                    ),
                  if (isLoading)
                    CupertinoActivityIndicator(
                      color: ThemeManager.primaryColor,
                    ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      _getCount(_userExamId);
                    },
                    child: Container(
                      height: Dimensions.PADDING_SIZE_SMALL * 2.7,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_LARGE),
                      decoration: BoxDecoration(
                          border: Border.all(
                            color: ThemeManager.blueFinal,
                          ),
                          borderRadius: BorderRadius.circular(60)),
                      child: Text(
                        "Submit",
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          fontWeight: FontWeight.w600,
                          color: ThemeManager.blueFinal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Row(
            children: [
              if (MediaQuery.of(context).size.width > 1160 && MediaQuery.of(context).size.height > 690)
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.22,
                  child: QuestionPalletDrawer(
                    key: UniqueKey(),
                    _testExamPaper,
                    _userExamId,
                    remainingTimeNotifier,
                    _isPracticeExam,
                    timer,
                    callBack: (textExamData) {
                      _updateParameter(
                        fromPallete: textExamData.fromPallete,
                        queNo: textExamData.queNo,
                        isPracticeExam: textExamData.isPracticeExam,
                        remainingTime: textExamData.remainingTime,
                        testExamPaper: textExamData.testExamPaper,
                        userExamId: textExamData.userExamId,
                      );
                    },
                  ),
                ),
              SizedBox(
                width: (MediaQuery.of(context).size.width > 1160 && MediaQuery.of(context).size.height > 690)
                    ? MediaQuery.of(context).size.width * 0.78
                    : MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: Dimensions.PADDING_SIZE_DEFAULT,
                        right: Dimensions.PADDING_SIZE_DEFAULT,
                        top: Dimensions.PADDING_SIZE_DEFAULT,
                      ),
                      child: Row(
                        children: [
                          Text(
                            "${_testExamPaper?.test?[_currentQuestionIndex].questionNumber}.",
                            style: interRegular.copyWith(
                              fontSize: Dimensions.fontSizeOverLarge,
                              fontWeight: FontWeight.w500,
                              color: ThemeManager.black,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            height: Dimensions.PADDING_SIZE_DEFAULT * 2,
                            width: Dimensions.PADDING_SIZE_DEFAULT * 5,
                            decoration: BoxDecoration(
                                color: ThemeManager.primaryColor,
                                borderRadius: BorderRadius.circular(Dimensions.RADIUS_LARGE)),
                            child: Center(
                              child: Text(
                                "Q-${(_testExamPaper?.test?[_currentQuestionIndex].questionNumber ?? "").toString().padLeft(2, '0')}",
                                style: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: Dimensions.PADDING_SIZE_SMALL,
                          ),
                          Text(
                            "Out of ${_testExamPaper?.test?.length.toString().padLeft(2, '0') ?? 0}",
                            style: interRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              fontWeight: FontWeight.w400,
                              color: ThemeManager.textColor3,
                            ),
                          ),
                          // const Spacer(),
                          // Text("${remainingTime!.inHours.toString().padLeft(2, '0')}:${remainingTime!.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTime!.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                          //   style: interRegular.copyWith(
                          //     fontSize: Dimensions.fontSizeDefault,
                          //     fontWeight: FontWeight.w600,
                          //     color: ThemeManager.greenSuccess,
                          //   ),),
                          // ValueListenableBuilder<Duration>(
                          //   valueListenable: remainingTimeNotifier,
                          //   builder: (context, remainingTime, child) {
                          //     return Text(
                          //       "${remainingTime!.inHours.toString().padLeft(2, '0')}:${remainingTime!.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTime!.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                          //         style: interRegular.copyWith(
                          //           fontSize: Dimensions.fontSizeDefault,
                          //           fontWeight: FontWeight.w600,
                          //           color: ThemeManager.greenSuccess,
                          //         ),
                          //     );
                          //   },
                          // ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.PADDING_SIZE_DEFAULT,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text(_testExamPaper?.test?[_currentQuestionIndex].questionText??"",
                              //   style: interRegular.copyWith(
                              //     fontSize: Dimensions.fontSizeDefault,
                              //     fontWeight: FontWeight.w400,
                              //     color: ThemeManager.black,
                              //   ),),
                              // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
                              //
                              // (_testExamPaper?.test?[_currentQuestionIndex].questionImg?.isNotEmpty ?? false)?
                              // InteractiveViewer(
                              //   minScale: 1.0,
                              //   maxScale: 3.0,
                              //   child: Center(
                              //     child: SizedBox(
                              //       width: MediaQuery.of(context).size.width * 0.6,
                              //       height: 250,
                              //       child: Stack(
                              //         children: [
                              //           if (quesImgBytes != null)
                              //             Image.memory(quesImgBytes!),
                              //           Container(color: Colors.transparent),
                              //         ],
                              //       ),
                              //     ),
                              //   ),
                              // ):const SizedBox(),

                              questionWidget ?? const SizedBox(),

                              const SizedBox(
                                height: Dimensions.PADDING_SIZE_DEFAULT,
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _testExamPaper?.test?[_currentQuestionIndex].optionsData?.length,
                                itemBuilder: (BuildContext context, int index) {
                                  TestData? testExamPaper = _testExamPaper?.test?[_currentQuestionIndex];
                                  String base64String = testExamPaper?.optionsData?[index].answerImg ?? "";
                                  try {
                                    // answerImgBytes = base64Decode(base64String);
                                  } catch (e) {
                                    debugPrint("Error decoding base64 string: $e");
                                  }
                                  bool isSelected = index == _selectedIndex;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_DEFAULT),
                                    child: InkWell(
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
                                        // _showNextQuestion();
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: isSelected ? ThemeManager.blueFinal : ThemeManager.white,
                                            border: Border.all(
                                                color: isSelected
                                                    ? ThemeManager.selectedBorder.withOpacity(0.5)
                                                    : ThemeManager.grey1,
                                                width: 0.84),
                                            borderRadius: BorderRadius.circular(33.44)),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: Dimensions.PADDING_SIZE_LARGE,
                                              vertical: Dimensions.PADDING_SIZE_DEFAULT),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Container(
                                              //   height: Dimensions.PADDING_SIZE_DEFAULT * 2,
                                              //   width: Dimensions.PADDING_SIZE_DEFAULT * 2,
                                              //   decoration: BoxDecoration(
                                              //       color: ThemeManager.borderBlue,
                                              //       borderRadius: BorderRadius.circular(Dimensions.RADIUS_LARGE)
                                              //   ),
                                              //   child: Center(
                                              //     child: Text(testExamPaper?.optionsData?[index].value??"",
                                              //       style: interRegular.copyWith(
                                              //         fontSize: Dimensions.fontSizeDefault,
                                              //         fontWeight: FontWeight.w400,
                                              //         color: ThemeManager.black,
                                              //       ),
                                              //     ),
                                              //   ),
                                              // ),

                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        "${testExamPaper?.optionsData?[index].value}.",
                                                        style: interRegular.copyWith(
                                                          fontSize: Dimensions.fontSizeLarge,
                                                          fontWeight: FontWeight.w400,
                                                          color: isSelected
                                                              ? ThemeManager.white
                                                              : ThemeManager.black,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                                                      ),
                                                      SizedBox(
                                                        width: MediaQuery.of(context).size.width * 0.7,
                                                        // child: Html(
                                                        //   data: '''
                                                        //     <div style="color: ${ThemeManager.currentTheme == AppTheme.Dark ? 'white' : 'black'};">
                                                        //         ${testExamPaper?.optionsData?[index].answerTitle ?? ""}
                                                        //         </div>
                                                        //         ''',
                                                        //   // data: testExamPaper?.optionsData?[index].answerTitle??"",
                                                        //   // style: TextStyle(
                                                        //   //   fontSize: Dimensions.fontSizeDefault,
                                                        //   //   fontWeight: FontWeight.w400,
                                                        //   //   color: ThemeManager.black,
                                                        //   // ),
                                                        // ),
                                                        child: Text(
                                                          testExamPaper?.optionsData?[index].answerTitle ??
                                                              "",
                                                          style: interRegular.copyWith(
                                                            fontSize: Dimensions.fontSizeLarge,
                                                            fontWeight: FontWeight.w400,
                                                            color: isSelected
                                                                ? ThemeManager.white
                                                                : ThemeManager.black,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  testExamPaper?.optionsData?[index].answerImg != ""
                                                      ? Row(
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
                                                                      // if (answerImgBytes != null)
                                                                      //   Image.memory(answerImgBytes!),
                                                                      if (base64String != '')
                                                                        Image.network(base64String),
                                                                      Container(color: Colors.transparent),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      : const SizedBox(),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
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
                      color: ThemeManager.buttonBackground,
                      padding: const EdgeInsets.only(
                          top: Dimensions.PADDING_SIZE_DEFAULT * 1.2,
                          left: Dimensions.PADDING_SIZE_EXTRA_LARGE * 1.1,
                          right: Dimensions.PADDING_SIZE_LARGE * 1.3,
                          bottom: Dimensions.PADDING_SIZE_LARGE * 1.33),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      isGuess = false;
                                      if (selectedOption != "") {
                                        isAttemptedAndMarkedForReview = !isAttemptedAndMarkedForReview;
                                      } else {
                                        isMarkedForReview = !isMarkedForReview;
                                      }
                                    });
                                    // isMarkedForReview=true;
                                    // _showNextQuestion();
                                    // Navigator.of(context).pushNamed(Routes.questionPallet);
                                  },
                                  child: Container(
                                    height: Dimensions.PADDING_SIZE_LARGE * 2.2,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(7.91),
                                        border: Border.all(color: ThemeManager.mainBorder),
                                        color: (isMarkedForReview
                                            ? Colors.blue
                                            : (isAttemptedAndMarkedForReview
                                                ? Colors.orangeAccent
                                                : ThemeManager.buttonBackground2)),
                                        boxShadow: ThemeManager.currentTheme == AppTheme.Dark
                                            ? []
                                            : [
                                                ///first
                                                BoxShadow(
                                                    offset: const Offset(0, 0),
                                                    color: ThemeManager.black.withOpacity(0.04),
                                                    blurRadius: 0,
                                                    spreadRadius: 0),

                                                ///second
                                                BoxShadow(
                                                    offset: const Offset(0, 4.62),
                                                    color: ThemeManager.black.withOpacity(0.04),
                                                    blurRadius: 10.165,
                                                    spreadRadius: 0),

                                                ///third
                                                BoxShadow(
                                                    offset: const Offset(0, 19.40),
                                                    color: ThemeManager.black.withOpacity(0.03),
                                                    blurRadius: 19.40,
                                                    spreadRadius: 0),

                                                ///four
                                                BoxShadow(
                                                    offset: const Offset(0, 43.436),
                                                    color: ThemeManager.black.withOpacity(0.02),
                                                    blurRadius: 25.876,
                                                    spreadRadius: 0),

                                                ///five
                                                BoxShadow(
                                                    offset: const Offset(0, 76.706),
                                                    color: ThemeManager.black.withOpacity(0.01),
                                                    blurRadius: 30.497,
                                                    spreadRadius: 0),

                                                ///six
                                                BoxShadow(
                                                    offset: const Offset(0, 120.142),
                                                    color: ThemeManager.black.withOpacity(0),
                                                    blurRadius: 33.270,
                                                    spreadRadius: 0),
                                              ]),
                                    child: Text(
                                      "Mark for review",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        fontWeight: FontWeight.w500,
                                        color: (isMarkedForReview
                                            ? Colors.white
                                            : (isAttemptedAndMarkedForReview
                                                ? Colors.white
                                                : ThemeManager.buttonGuessMark)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: Dimensions.PADDING_SIZE_SMALL,
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (_selectedIndex != -1) {
                                      setState(() {
                                        isGuess = !isGuess;
                                        isAttemptedAndMarkedForReview = false;
                                        isMarkedForReview = false;
                                      });
                                      debugPrint("isGuess:$isGuess");
                                      // _showNextQuestion();
                                      // Navigator.of(context).pushNamed(Routes.questionPallet);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                        content: Text('Please Select Option'),
                                      ));
                                    }
                                  },
                                  child: Container(
                                    height: Dimensions.PADDING_SIZE_LARGE * 2.2,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        border: Border.all(color: ThemeManager.mainBorder),
                                        borderRadius: BorderRadius.circular(7.91),
                                        color:
                                            isGuess == true ? Colors.brown : ThemeManager.buttonBackground2,
                                        boxShadow: ThemeManager.currentTheme == AppTheme.Dark
                                            ? []
                                            : [
                                                ///first
                                                BoxShadow(
                                                    offset: const Offset(0, 0),
                                                    color: ThemeManager.black.withOpacity(0.04),
                                                    blurRadius: 0,
                                                    spreadRadius: 0),

                                                ///second
                                                BoxShadow(
                                                    offset: const Offset(0, 4.62),
                                                    color: ThemeManager.black.withOpacity(0.04),
                                                    blurRadius: 10.165,
                                                    spreadRadius: 0),

                                                ///third
                                                BoxShadow(
                                                    offset: const Offset(0, 19.40),
                                                    color: ThemeManager.black.withOpacity(0.03),
                                                    blurRadius: 19.40,
                                                    spreadRadius: 0),

                                                ///four
                                                BoxShadow(
                                                    offset: const Offset(0, 43.436),
                                                    color: ThemeManager.black.withOpacity(0.02),
                                                    blurRadius: 25.876,
                                                    spreadRadius: 0),

                                                ///five
                                                BoxShadow(
                                                    offset: const Offset(0, 76.706),
                                                    color: ThemeManager.black.withOpacity(0.01),
                                                    blurRadius: 30.497,
                                                    spreadRadius: 0),

                                                ///six
                                                BoxShadow(
                                                    offset: const Offset(0, 120.142),
                                                    color: ThemeManager.black.withOpacity(0),
                                                    blurRadius: 33.270,
                                                    spreadRadius: 0),
                                              ]),
                                    child: Text(
                                      "Guess",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        fontWeight: FontWeight.w500,
                                        color: isGuess == true ? Colors.white : ThemeManager.buttonGuessMark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: Dimensions.PADDING_SIZE_DEFAULT * 1.2,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: firstQue ? null : _showPreviousQuestion,
                                child: Container(
                                  height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.14,
                                  width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.14,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: firstQue
                                            ? ThemeManager.nextButtonBorder
                                            : ThemeManager.previousNextPrimary,
                                      )),
                                  child: SvgPicture.asset(
                                    "assets/image/arrow_back.svg",
                                    color: firstQue
                                        ? ThemeManager.nextButtonBorder
                                        : ThemeManager.previousNextPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: Dimensions.PADDING_SIZE_DEFAULT * 1.1,
                              ),
                              InkWell(
                                // onTap: _NextQuestion,
                                onTap: _showNextQuestion,
                                child: Container(
                                  height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.14,
                                  width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.14,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: ThemeManager.previousNextPrimary)),
                                  child: Transform.flip(
                                      flipX: true,
                                      child: SvgPicture.asset(
                                        "assets/image/arrow_back.svg",
                                        color: ThemeManager.previousNextPrimary,
                                      )),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: SizedBox(
                    //         height: Dimensions.PADDING_SIZE_EXTRA_LARGE*2,
                    //         child: ElevatedButton(
                    //           style: ElevatedButton.styleFrom(
                    //               shape: RoundedRectangleBorder(
                    //                 borderRadius: BorderRadius.circular(10),
                    //               ),
                    //             backgroundColor: Theme.of(context).primaryColor
                    //           ),
                    //             onPressed: firstQue?null:_showPreviousQuestion,
                    //             child: Text("Previous",
                    //               style: TextStyle(
                    //                 fontSize: Dimensions.fontSizeDefault,
                    //                 fontWeight: FontWeight.w400,
                    //                 color:firstQue ? ThemeManager.black : ThemeManager.home1,
                    //               ),)),
                    //       ),
                    //     ),
                    //     const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT,),
                    //     Expanded(
                    //       child: SizedBox(
                    //         height: Dimensions.PADDING_SIZE_EXTRA_LARGE*2,
                    //         child: ElevatedButton(
                    //             style: ElevatedButton.styleFrom(
                    //                 shape: RoundedRectangleBorder(
                    //                   borderRadius: BorderRadius.circular(10),
                    //                 ),
                    //                 backgroundColor: Theme.of(context).primaryColor
                    //             ),
                    //             onPressed: _showNextQuestion,
                    //             child: isLastQues==true?
                    //             Text("Submit",
                    //               style: TextStyle(
                    //                 fontSize: Dimensions.fontSizeDefault,
                    //                 fontWeight: FontWeight.w400,
                    //                 color: ThemeManager.home1,
                    //               ),):
                    //             Text("Next",
                    //               style: TextStyle(
                    //                 fontSize: Dimensions.fontSizeDefault,
                    //                 fontWeight: FontWeight.w400,
                    //                 color:ThemeManager.home1,
                    //               ),)),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: CustomButton(onPressed: (){
                    //         setState(() {
                    //           isGuess=false;
                    //           if(selectedOption!=""){
                    //             isAttemptedAndMarkedForReview=!isAttemptedAndMarkedForReview;
                    //           }else{
                    //             isMarkedForReview = !isMarkedForReview;
                    //           }
                    //         });
                    //         // isMarkedForReview=true;
                    //         // _showNextQuestion();
                    //         // Navigator.of(context).pushNamed(Routes.questionPallet);
                    //       },
                    //         buttonText: "Mark for review",
                    //         height: Dimensions.PADDING_SIZE_EXTRA_LARGE*2,
                    //         textAlign: TextAlign.center,
                    //         radius: Dimensions.RADIUS_DEFAULT,
                    //         transparent: true,
                    //         bgColor:(isMarkedForReview ?Colors.blue : ( isAttemptedAndMarkedForReview ?  Colors.orangeAccent :  Theme.of(context).primaryColor )   ),
                    //         fontSize: Dimensions.fontSizeDefault,
                    //       ),
                    //     ),
                    //     const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT,),
                    //     Expanded(
                    //       child: CustomButton(onPressed: (){
                    //         if(_selectedIndex != -1){
                    //           setState(() {
                    //             isGuess = !isGuess;
                    //             isAttemptedAndMarkedForReview=false;
                    //             isMarkedForReview=false;
                    //           });
                    //           debugPrint("isGuess:${isGuess}");
                    //           // _showNextQuestion();
                    //           // Navigator.of(context).pushNamed(Routes.questionPallet);
                    //         }else{
                    //           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    //             content: Text('Please Select Option'),
                    //           ));
                    //         }
                    //       },
                    //         buttonText: "Guess",
                    //         height: Dimensions.PADDING_SIZE_EXTRA_LARGE*2,
                    //         textAlign: TextAlign.center,
                    //         radius: Dimensions.RADIUS_DEFAULT,
                    //         transparent: true,
                    //         bgColor: isGuess == true ? Colors.brown :Theme.of(context).primaryColor,
                    //         fontSize: Dimensions.fontSizeDefault,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ],
          ),
          drawer: Drawer(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            backgroundColor: Colors.white,
            child: QuestionPallet(
              _testExamPaper,
              _userExamId,
              remainingTimeNotifier,
              _isPracticeExam,
              timer,
            ),
          )),
    );
  }
}
