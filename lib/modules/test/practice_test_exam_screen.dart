import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_svg/svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/comman_widget.dart';
import 'package:shusruta_lms/modules/masterTest/time_traker.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/store/new_bookmark_store.dart';
import 'package:shusruta_lms/modules/new_exam_component/model/exam_ans_model.dart';
import 'package:shusruta_lms/modules/new_exam_component/widget/custome_exam_button.dart';
import 'package:shusruta_lms/modules/new_exam_component/widget/loading_box.dart';
import 'package:shusruta_lms/modules/notes/mobilehelper.dart';
import 'package:shusruta_lms/modules/reports/explanation_common_widget.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/widgets/bottom_stick_notes_window.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:typewritertext/typewritertext.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../app/routes.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/haptics.dart';
import '../../helpers/styles.dart';
import '../../services/daily_review_recorder.dart';
import '../../services/smart_resume_service.dart';
import '../../models/get_explanation_model.dart';
import '../../models/get_notes_solution_model.dart';
import '../../models/test_exampaper_list_model.dart';
import '../reports/store/report_by_category_store.dart';
import '../widgets/bottom_raise_query.dart';
import '../widgets/bottom_stick_notes.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';

class PracticeTestExamScreen extends StatefulWidget {
  final TestExamPaperListModel? testExamPaper;
  final String? userExamId;
  final int? queNo;
  final bool? isPracticeExam;
  final ValueNotifier<Duration>? remainingTime;
  final String? id;
  final String? mainId;
  final String? type;
  final bool? isCorrect;
  final bool? isAll;
  final bool isCustom;
  final bool? fromPallete;
  const PracticeTestExamScreen(
      {super.key,
      this.fromPallete,
      this.testExamPaper,
      this.userExamId,
      this.isPracticeExam,
      this.queNo,
      this.remainingTime,
      this.mainId,
      this.id,
      this.isAll,
      this.type,
      this.isCorrect,
      this.isCustom = false});

  @override
  State<PracticeTestExamScreen> createState() => _PracticeTestExamScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => PracticeTestExamScreen(
        testExamPaper: arguments['testData'],
        userExamId: arguments['userexamId'],
        queNo: arguments['queNo'],
        isPracticeExam: arguments['isPracticeExam'],
        remainingTime: arguments['remainingTime'],
        id: arguments['id'],
        mainId: arguments['mainId'] ?? "",
        isAll: arguments['isAll'] ?? false,
        type: arguments['type'],
        fromPallete: arguments['fromPallete'],
        isCorrect: arguments['isCorrect'],
        isCustom: arguments['isCustom'] ?? false,
      ),
    );
  }
}

class _PracticeTestExamScreenState extends State<PracticeTestExamScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late QuillController _quillController = QuillController.basic();

  // Timer? timer;
  // late ValueNotifier<Duration> remainingTimeNotifier;
  // Duration? remainingTime;
  int _selectedIndex = -1;
  int _currentQuestionIndex = 0;
  double _textSizePercent = 100;
  final int _horizontalQuestionIndex = 0;
  bool isLastQues = false, firstQue = true;
  bool isAttempted = false;
  bool isMarkedForReview = false;
  bool isGuess = false;
  bool isAttemptedAndMarkedForReview = false;
  bool isSkipped = false;
  final ScrollController scrollController = ScrollController();
  Uint8List? answerImgBytes;
  Uint8List? quesImgBytes;
  Uint8List? explanationImgBytes;
  bool isButtonVisible = true;
  bool isButtonVisible2 = true;
  bool isTapped = false;
  // Duration? duration;
  // String? usedExamTime;
  Widget? explanationWidget;
  Widget? questionWidget;
  final _controller = SuperTooltipController();
  bool isbutton = false, isprocess = false;
  double _textSize = Dimensions.fontSizeDefault;
  double showfontSize = 100;
  late TimeTracker _questionTracker;

  @override
  void initState() {
    super.initState();
    _quillController.readOnly = true;
    _quillController.addListener(_onTextChanged);
    _questionTracker = TimeTracker(previousTime: '00:00:00');
    _questionTracker.start();
    final store2 = Provider.of<TestCategoryStore>(context, listen: false);
    store2.startTimer();
    // updateTimer();
    isTapped = false;
    int matchingIndex = widget.testExamPaper?.test?.indexWhere((e) => e.questionNumber == widget.queNo) ?? -1;
    if (matchingIndex != -1) {
      String? matchingQueId = store2.qutestionList.value[matchingIndex].sId;
      _currentQuestionIndex = matchingIndex;
      setState(() {
        firstQue = false;
      });
    }

    _getNotesData(store2.qutestionList.value[_currentQuestionIndex].sId ?? "");

    // Smart Resume hook — push this in-progress practice test into
    // SmartResumeService so the home banner can offer a 1-tap
    // resume. Use recordMockExam since this is a non-custom test.
    final userExamId = widget.userExamId ?? '';
    final examName = widget.testExamPaper?.examName ?? 'Practice test';
    final totalQs = widget.testExamPaper?.test?.length ?? 0;
    if (userExamId.isNotEmpty) {
      // ignore: discarded_futures
      SmartResumeService.instance.recordMockExam(
        userExamId: userExamId,
        examName: examName,
        currentQuestion: _currentQuestionIndex + 1,
        totalQuestions: totalQs,
        examId: widget.testExamPaper?.examId,
      );
    }
  }

  Future<void> _getExplanationData(String prompt) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onGetExplanationCall(prompt);
    setState(() {
      isprocess = false;
      isbutton = true;
    });
  }

  @override
  void dispose() async {
    final store2 = Provider.of<TestCategoryStore>(context, listen: false);
    await store2.disposeStore();
    _quillController.dispose();
    _questionTracker.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    print('Editor content changed');

    // Perform any other actions you need when the content changes
  }

  Future<void> _putBookMarkApiCall(String examId, String? questionId) async {
    Haptics.medium();
    final store2 = Provider.of<TestCategoryStore>(context, listen: false);
    setState(() {
      store2.qutestionList.value[_currentQuestionIndex].bookmarks =
          !(store2.qutestionList.value[_currentQuestionIndex].bookmarks ?? false);
    });
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    final isBookmarkedNow =
        store2.qutestionList.value[_currentQuestionIndex].bookmarks ?? false;
    store.onBookMarkQuestion(context, isBookmarkedNow, examId, questionId ?? "", "");
    // Push (or pull) into the daily-review bookmark pool. Fire-and-
    // forget — failures don't block the user's flow.
    // ignore: discarded_futures
    DailyReviewRecorder.bookmarkToggle(
      store2.qutestionList.value[_currentQuestionIndex],
      examId,
      isBookmarkedNow,
    );
    BottomToast.showBottomToastOverlay(
      context: context,
      errorMessage: isBookmarkedNow
          ? "Question Bookmarked Successfully!"
          : "Bookmark Removed!",
      backgroundColor: Theme.of(context).primaryColor,
    );
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
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onAns(ExamAnsModel(
        userExamId: userExamId!,
        questionId: questionId!,
        selectedOption: selectedOption!,
        attempted: isAttempted,
        attemptedMarkedForReview: isAttemptedAndMarkedForReview,
        skipped: isSkipped,
        guess: guess,
        markedForReview: isMarkedForReview,
        time: time,
        timePerQuestion: _questionTracker.getCurrentTime()));
    // await store.userAnswerTest(
    //     context,
    //     userExamId ?? "",
    //     questionId ?? "",
    //     selectedOption ?? "",
    //     isAttempted,
    //     isAttemptedAndMarkedForReview,
    //     isSkipped,
    //     isMarkedForReview,
    //     guess,
    //     time);
  }

  Future<void> _getCount(String? userExamId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.getQuestionPalleteCount(userExamId ?? "").then((_) {
      openBottomSheet(store);
    });
  }

  Future<void> _postPracticeData() async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    final question = store.qutestionList.value[_currentQuestionIndex];
    String? questionId = question.sId;

    String? selectedOption = _selectedIndex == -1
        ? ""
        : question.optionsData?[_selectedIndex].value;

    // Daily-review pool sync — if the user picked an option, judge it
    // against the correct answer and push to the incorrect pool when
    // wrong, or pull from it when right (e.g. retake).
    final correctValue = question.correctOption ?? '';
    if (selectedOption != null &&
        selectedOption.isNotEmpty &&
        correctValue.isNotEmpty) {
      if (selectedOption != correctValue) {
        // ignore: discarded_futures
        DailyReviewRecorder.recordWrong(question, question.examId, selectedOption);
      } else {
        // ignore: discarded_futures
        DailyReviewRecorder.recordCorrect(question);
      }
    }

    if (selectedOption == "" && !isMarkedForReview) {
      isSkipped = true;
      isAttempted = false;
      isAttemptedAndMarkedForReview = false;
      isMarkedForReview = false;
      isGuess = false;
    } else if (selectedOption != "" && isMarkedForReview) {
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
    } else if (selectedOption == "" && isGuess) {
      isMarkedForReview = true;
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
    await _postSelectedAnswerApiCall(widget.userExamId, selectedOption, questionId, isAttempted,
        isAttemptedAndMarkedForReview, isSkipped, isMarkedForReview, selectedOption!, "");
  }

  void openBottomSheet(TestCategoryStore store) {
    getCountReportPractice(context, widget.type ?? "", widget.isCustom);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeManager.white,
        surfaceTintColor: ThemeManager.white,
        contentPadding: const EdgeInsets.only(
            top: Dimensions.PADDING_SIZE_LARGE * 1.1,
            left: Dimensions.PADDING_SIZE_DEFAULT * 2,
            right: Dimensions.PADDING_SIZE_DEFAULT * 2,
            bottom: Dimensions.PADDING_SIZE_SMALL * 2.3),
        alignment: Alignment.center,
        actionsPadding: const EdgeInsets.only(
            left: Dimensions.PADDING_SIZE_LARGE,
            right: Dimensions.PADDING_SIZE_LARGE,
            bottom: Dimensions.PADDING_SIZE_EXTRA_LARGE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: FittedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Practice Test Summary',
                style: interRegular.copyWith(
                  fontSize: Dimensions.fontSizeExtraLarge,
                  fontWeight: FontWeight.w500,
                  color: ThemeManager.black,
                ),
              ),
              const SizedBox(
                height: Dimensions.PADDING_SIZE_SMALL * 3.2,
              ),
              Row(
                children: [
                  Container(
                    height: Dimensions.PADDING_SIZE_LARGE * 1.1,
                    width: Dimensions.PADDING_SIZE_LARGE * 1.1,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFF329B62), shape: BoxShape.circle),
                    child: Icon(
                      Icons.check,
                      color: ThemeManager.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
                  Text(
                    'Correct - ',
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefaultLarge,
                      fontWeight: FontWeight.w400,
                      color: ThemeManager.black,
                    ),
                  ),
                  Text(
                    '${store.getReportPracticeCountData.value?.correctAnswers}',
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefaultLarge,
                      fontWeight: FontWeight.w700,
                      color: ThemeManager.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: Dimensions.PADDING_SIZE_SMALL * 1.6,
              ),
              Row(
                children: [
                  Container(
                    height: Dimensions.PADDING_SIZE_LARGE * 1.1,
                    width: Dimensions.PADDING_SIZE_LARGE * 1.1,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFFFF0000), shape: BoxShape.circle),
                    child: Icon(
                      Icons.close,
                      color: ThemeManager.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
                  Text(
                    'Incorrect - ',
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefaultLarge,
                      fontWeight: FontWeight.w400,
                      color: ThemeManager.black,
                    ),
                  ),
                  Text(
                    '${store.getReportPracticeCountData.value?.incorrectAnswers}',
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefaultLarge,
                      fontWeight: FontWeight.w700,
                      color: ThemeManager.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.PADDING_SIZE_SMALL * 1.6),
              Row(
                children: [
                  Container(
                    height: Dimensions.PADDING_SIZE_LARGE * 1.1,
                    width: Dimensions.PADDING_SIZE_LARGE * 1.1,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFFFFD53F), shape: BoxShape.circle),
                    child: Icon(CupertinoIcons.exclamationmark, color: ThemeManager.white, size: 20),
                  ),
                  const SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
                  Text(
                    'Unanswered - ',
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefaultLarge,
                      fontWeight: FontWeight.w400,
                      color: ThemeManager.black,
                    ),
                  ),
                  Text(
                    '${store.getReportPracticeCountData.value?.notVisited}',
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefaultLarge,
                      fontWeight: FontWeight.w700,
                      color: ThemeManager.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          InkWell(
            onTap: () async {
              store.disposeStore();
              Navigator.of(context).pushNamed(Routes.testCategory);
            },
            child: Container(
              height: Dimensions.PADDING_SIZE_DEFAULT * 3,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ThemeManager.primaryColor,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
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
                ],
              ),
              child: Text('Save & Exit',
                  style: interRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNextQuestion() async {
    scrollToTop(scrollController);
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    _questionTracker.stop();
    _questionTracker = TimeTracker(previousTime: '00:00:00');
    _questionTracker.start();
    isbutton = false;
    firstQue = false;
    isTapped = false;
    String? questionId = store.qutestionList.value[_currentQuestionIndex].sId;

    Delta delta = _quillController.document.toDelta();
    store.saveChangeExaplanation(context, {"question_id": questionId, "annotation_data": delta.toJson()});
    store.qutestionList.value[_currentQuestionIndex].isHighlight = true;
    store.qutestionList.value[_currentQuestionIndex].annotationData = delta.toJson();
    String? selectedOption = _selectedIndex == -1
        ? ""
        : store.qutestionList.value[_currentQuestionIndex].optionsData?[_selectedIndex].value;
    if (selectedOption == "" && !isMarkedForReview) {
      store.qutestionList.value[_currentQuestionIndex].skipped = true;
      isSkipped = true;
      isAttempted = false;
      isAttemptedAndMarkedForReview = false;
      isMarkedForReview = false;
      isGuess = false;
    } else if (selectedOption != "" && isMarkedForReview) {
      store.qutestionList.value[_currentQuestionIndex].skipped = false;
      isAttemptedAndMarkedForReview = true;
      isSkipped = false;
      isAttempted = false;
      isMarkedForReview = false;
      isGuess = false;
    } else if (selectedOption == "" && isMarkedForReview) {
      store.qutestionList.value[_currentQuestionIndex].skipped = false;
      isMarkedForReview = true;
      isAttemptedAndMarkedForReview = false;
      isSkipped = false;
      isAttempted = false;
      isGuess = false;
    } else if (selectedOption == "" && isGuess) {
      store.qutestionList.value[_currentQuestionIndex].skipped = false;
      isMarkedForReview = true;
      isAttemptedAndMarkedForReview = false;
      isSkipped = false;
      isAttempted = false;
      isGuess = true;
    } else if (selectedOption != "") {
      store.qutestionList.value[_currentQuestionIndex].skipped = false;
      isAttempted = true;
      isAttemptedAndMarkedForReview = false;
      isSkipped = false;
      isMarkedForReview = false;
      isGuess = false;
    }

    // if (duration != null && remainingTimeNotifier.value != null) {
    //   Duration timeDifference = duration! - remainingTimeNotifier.value;
    //   usedExamTime = "${timeDifference.inHours.toString().padLeft(2, '0')}:${timeDifference.inMinutes.remainder(60).toString().padLeft(2, '0')}:${timeDifference.inSeconds.remainder(60).toString().padLeft(2, '0')}";
    //   debugPrint('usedtime $usedExamTime');
    // } else {
    //   debugPrint('Duration values are null.');
    // }
    await _postSelectedAnswerApiCall(widget.userExamId, selectedOption, questionId, isAttempted,
        isAttemptedAndMarkedForReview, isSkipped, isMarkedForReview, selectedOption!, "");
    isAttempted = false;
    isSkipped = false;
    isAttemptedAndMarkedForReview = false;
    isMarkedForReview = false;
    isGuess = false;
    _selectedIndex = -1;
    if (_currentQuestionIndex == (store.qutestionList.value.length ?? 0) - 1) {
      final store2 = Provider.of<TestCategoryStore>(context, listen: false);
      showLoadingDialog(context);
      await store2.triggerAction();

      // showDialog(
      //   context: context,
      //   builder: (context) => const CustomTestCancelDialogBox(null,null,true),
      // );
      await getCountReportPractice(context, widget.type ?? "", widget.isCustom);
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: ThemeManager.white,
          surfaceTintColor: ThemeManager.white,
          alignment: Alignment.center,
          actionsPadding: const EdgeInsets.only(
            left: Dimensions.PADDING_SIZE_LARGE,
            right: Dimensions.PADDING_SIZE_LARGE,
            bottom: Dimensions.PADDING_SIZE_EXTRA_LARGE,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Observer(builder: (_) {
            return Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Prevents the column from taking up all available space
                children: [
                  Center(
                    child: Text(
                      'Practice Test\nSummary',
                      textAlign: TextAlign.center,
                      style: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraLarge,
                        fontWeight: FontWeight.w500,
                        color: ThemeManager.black,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: Dimensions.PADDING_SIZE_SMALL * 3.2,
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: _buildDetail(
                          "Correct",
                          "${store2.getReportPracticeCountData.value?.correctAnswers ?? 0}",
                          "assets/image/correct.svg",
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _buildDetail(
                          "Incorrect",
                          "${store2.getReportPracticeCountData.value?.incorrectAnswers ?? 0}",
                          "assets/image/incorrect.svg",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.PADDING_SIZE_SMALL * 1.6),
                  Row(
                    children: [
                      Flexible(
                        child: _buildDetail(
                          "Total Questions",
                          "${store2.getReportPracticeCountData.value?.totalQuestions ?? 0}",
                          "assets/image/total_q.svg",
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _buildDetail(
                          "Unanswered",
                          "${store2.getReportPracticeCountData.value?.notVisited ?? 0}",
                          "assets/image/skipped1.svg",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.PADDING_SIZE_SMALL * 1.6),
                  _buildDetail(
                    "Bookmarked",
                    "${store2.getReportPracticeCountData.value?.bookmarkCount ?? 0}",
                    "assets/image/bookmark2.svg",
                  ),
                ],
              ),
            );
          }),
          actions: [
            InkWell(
              onTap: () async {
                showLoadingDialog(context);
                await store2.triggerAction();
                if (widget.type != "McqBookmark" && widget.type != "MockBookmark") {
                  await store2.onExamAttemptList(widget.testExamPaper!.sid!);
                } else {
                  final store = Provider.of<BookmarkNewStore>(context, listen: false);
                  store.ongetCustomAnalysisApiCall(
                      widget.type!, widget.mainId ?? "67c70853be4a8ac3c2761910", widget.isAll ?? false);
                }
                await store2.disposeStore();
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Container(
                height: Dimensions.PADDING_SIZE_DEFAULT * 3,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ThemeManager.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 0),
                      color: ThemeManager.black.withOpacity(0.04),
                      blurRadius: 0,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      offset: const Offset(0, 4.62),
                      color: ThemeManager.black.withOpacity(0.04),
                      blurRadius: 10.165,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      offset: const Offset(0, 19.40),
                      color: ThemeManager.black.withOpacity(0.03),
                      blurRadius: 19.40,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      offset: const Offset(0, 43.436),
                      color: ThemeManager.black.withOpacity(0.02),
                      blurRadius: 25.876,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      offset: const Offset(0, 76.706),
                      color: ThemeManager.black.withOpacity(0.01),
                      blurRadius: 30.497,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      offset: const Offset(0, 120.142),
                      color: ThemeManager.black.withOpacity(0),
                      blurRadius: 33.270,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  'Save & Exit',
                  style: interRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    setState(() {
      _currentQuestionIndex++;
      if (_currentQuestionIndex >= (store.qutestionList.value.length ?? 0) - 1) {
        isLastQues = true;
        _currentQuestionIndex = (store.qutestionList.value.length ?? 0) - 1;
      } else {
        isLastQues = false;
      }
      // _getSelectedAnswer(questionId1 ?? "");
      if (store.qutestionList.value[_currentQuestionIndex].selectedOption != null &&
          store.qutestionList.value[_currentQuestionIndex].selectedOption!.isNotEmpty) {
        _selectedIndex = store.qutestionList.value[_currentQuestionIndex].optionsData!
            .indexWhere((e) => e.value == store.qutestionList.value[_currentQuestionIndex].selectedOption);
      }
      explanationWidget = getExplanationText(context);
      questionWidget = getQuestionText(context);
      _getNotesData(store.qutestionList.value[_currentQuestionIndex].sId ?? "");

      _scrollToIndex(_currentQuestionIndex);
    });
  }

  Future<void> _showPreviousQuestion() async {
    scrollToTop(scrollController);
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    _questionTracker.stop();
    _questionTracker = TimeTracker(previousTime: '00:00:00');
    _questionTracker.start();
    setState(() {
      isbutton = false;
      _selectedIndex = -1;
      isLastQues = false;
      if (store.qutestionList.value.length == 1) {
        _currentQuestionIndex = 0;
        firstQue = true;
      } else if (_currentQuestionIndex > 0) {
        _currentQuestionIndex--;
      } else {
        firstQue = true;
      }

      // String? questionId = store.qutestionList.value[_currentQuestionIndex].sId;
      // // _getSelectedAnswer(questionId ?? "");
      if (store.qutestionList.value[_currentQuestionIndex].selectedOption != null &&
          store.qutestionList.value[_currentQuestionIndex].selectedOption!.isNotEmpty) {
        _selectedIndex = store.qutestionList.value[_currentQuestionIndex].optionsData!
            .indexWhere((e) => e.value == store.qutestionList.value[_currentQuestionIndex].selectedOption);
      }
      explanationWidget = getExplanationText(context);
      questionWidget = getQuestionText(context);
      _getNotesData(store.qutestionList.value[_currentQuestionIndex].sId ?? "");
      _scrollToIndex(_currentQuestionIndex);
    });
  }

  Future<bool> _onBackPressed() async {
    if (_currentQuestionIndex > 0) {
      _showPreviousQuestion();
      return false;
    } else {
      // bool confirmExit = await showDialog(
      //   context: context,
      //   builder: (context) => CustomTestCancelDialogBox(timer,remainingTimeNotifier),
      // );
      // return confirmExit;
      return true;
    }
  }

//   Widget getExplanationText(BuildContext context) {
//     final store = Provider.of<TestCategoryStore>(context, listen: false);
//
//     String explanation =
//         store.qutestionList.value[_currentQuestionIndex].explanation ?? "";
//     explanation = explanation.replaceAllMapped(
//         RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
//     List<String> splittedText = explanation.split("splittedImage");
//     List<Widget> columns = [];
//     int index = 0;
//
//     for (String text in splittedText) {
//       final documentContent = preprocessDocument(text);
//       _quillController.document = Document.fromJson(store
//                   .qutestionList.value[_currentQuestionIndex].isHighlight ??
//               false
//           ? store.qutestionList.value[_currentQuestionIndex].annotationData!
//                       .toString() ==
//                   "[{}]"
//               ? parseCustomSyntax("""
// $documentContent""")
//               : store.qutestionList.value[_currentQuestionIndex].annotationData!
//           : parseCustomSyntax("""
// $documentContent
// """));
//
//       List<Widget> explanationImageWidget = [];
//       if (store.qutestionList.value[_currentQuestionIndex].explanationImg
//               ?.isNotEmpty ??
//           false) {
//         for (String base64String in store
//             .qutestionList.value[_currentQuestionIndex].explanationImg!) {
//           try {
//             // Uint8List explanationImgBytes = base64Decode(base64String);
//             explanationImageWidget.add(
//               GestureDetector(
//                 onTap: () {
//                   showDialog(
//                     context: context,
//                     builder: (context) {
//                       return Dialog(
//                         child: PhotoView(
//                           // imageProvider: MemoryImage(explanationImgBytes),
//                           imageProvider: NetworkImage(base64String),
//                           minScale: PhotoViewComputedScale.contained,
//                           maxScale: PhotoViewComputedScale.covered * 2,
//                         ),
//                       );
//                     },
//                   );
//                 },
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: InteractiveViewer(
//                         // minScale: 1.0,
//                         // maxScale: 3.0,
//                         scaleEnabled: false,
//                         child: Center(
//                           child: Container(
//                             padding: const EdgeInsets.only(bottom: 8.0),
//                             // width: MediaQuery.of(context).size.width,
//                             // height: MediaQuery.of(context).size.height * 0.3,
//                             child: Stack(
//                               children: [
//                                 // Image.memory(explanationImgBytes),
//                                 Image.network(base64String, fit: BoxFit.cover),
//                                 Container(color: Colors.transparent),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           } catch (e) {
//             debugPrint("Error decoding base64 string: $e");
//           }
//         }
//       }
//       columns.add(
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Markdown(
//             //   data: text.replaceAll("--", "•"),
//
//             //   shrinkWrap: true,
//             //   physics: const NeverScrollableScrollPhysics(),
//
//             //   padding: const EdgeInsets.all(0),
//             //   selectable: true, // Allows text selection
//             //   styleSheet: MarkdownStyleSheet(
//             //     p: const TextStyle(fontSize: 16),
//             //   ),
//             // ),
//             CommonExplanationWidget(
//               textPercentage: _textSizePercent.toInt(),
//               controller: _quillController,
//             ),
//             // Text(
//             //   text
//             //       .trim()
//             //       .replaceAll("			--", "                 •")
//             //       .replaceAll("		--", "           •")
//             //       .replaceAll("	--", "     •")
//             //       .replaceAll("--", "•"),
//             //   textAlign: TextAlign.justify,
//             //   style: interBlack.copyWith(
//             //     fontSize: _textSize,
//             //     fontWeight: FontWeight.w400,
//             //     color: ThemeManager.black,
//             //   ),
//             // ),
//             // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: explanationImageWidget,
//             ),
//             const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
//             explanationImageWidget.isNotEmpty
//                 ? Text(
//                     "Tap the image to zoom In/Out",
//                     style: interBlack.copyWith(
//                       fontSize: Dimensions.fontSizeSmall * (_textSizePercent / 100),
//                       fontWeight: FontWeight.w400,
//                       color: ThemeManager.black,
//                     ),
//                   )
//                 : const SizedBox(),
//           ],
//         ),
//       );
//       index++;
//
//       if (index >=
//           (store.qutestionList.value[_currentQuestionIndex].explanationImg
//                       ?.length ??
//                   0) -
//               1) {
//         break;
//       }
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: columns,
//     );
//   }

  Widget getExplanationText(BuildContext context) {
    final store = Provider.of<TestCategoryStore>(context, listen: false);

    if (store.qutestionList.value == null ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= store.qutestionList.value!.length) {
      return const Center(
        child: Text("No data available"),
      );
    }

    final currentData = store.qutestionList.value![_currentQuestionIndex];

    List<Widget> columns = [];

    /// TEXT
    String explanation = currentData.explanation ?? "";
    final documentContent = preprocessDocument(explanation);

    Document document;

    /// ✅ ⭐ MOST IMPORTANT PART
    if (currentData.annotationData != null &&
        currentData.annotationData!.isNotEmpty &&
        currentData.annotationData.toString() != "[{}]") {
      try {
        document = Document.fromJson(currentData.annotationData!);
        debugPrint("✅ Loaded SAVED annotation");
      } catch (e) {
        debugPrint("❌ Error loading annotation: $e");

        final parsed = parseCustomSyntax(documentContent);
        document = parsed.isEmpty
            ? (Document()..insert(0, "No explanation available\n"))
            : Document.fromJson(parsed);
      }
    } else {
      final parsed = documentContent.trim().isEmpty ? null : parseCustomSyntax(documentContent);

      document = (parsed == null || parsed.isEmpty)
          ? (Document()..insert(0, "No explanation available\n"))
          : Document.fromJson(parsed);

      debugPrint("⚪ Loaded ORIGINAL content");
    }

    /// ✅ IMPORTANT: recreate controller with document

    _quillController = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    columns.add(
      CommonExplanationWidget(
        textPercentage: _textSizePercent.toInt(),
        controller: _quillController,
      ),
    );

    /// IMAGES
    if (currentData.explanationImg != null && currentData.explanationImg!.isNotEmpty) {
      columns.add(const SizedBox(height: 12));

      columns.add(
        Column(
          children: currentData.explanationImg!.map<Widget>((imageUrl) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: PhotoView(
                        imageProvider: NetworkImage(imageUrl),
                      ),
                    ),
                  );
                },
                child: Image.network(imageUrl),
              ),
            );
          }).toList(),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(children: columns),
    );
  }

  Map<String, int> calculateExamMetrics(List<TestData> questions) {
    int attemptedCorrect = 0;
    int attemptedIncorrect = 0;
    int totalAttempted = 0;
    int totalUnattempted = 0;

    for (var question in questions) {
      bool isAttempted = question.selectedOption != null && question.selectedOption!.isNotEmpty;

      if (isAttempted) {
        totalAttempted++;
        bool isCorrect = (question.correctOption ?? "") == (question.selectedOption ?? "");
        if (isCorrect) {
          attemptedCorrect++;
        } else {
          attemptedIncorrect++;
        }
      } else {
        totalUnattempted++;
      }
    }

    return {
      "attempted_correct": attemptedCorrect,
      "attempted_incorrect": attemptedIncorrect,
      "total_attempted": totalAttempted,
      "total_unattempted": totalUnattempted,
    };
  }

  Widget getQuestionText(BuildContext context) {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    if (_currentQuestionIndex < 0 || _currentQuestionIndex >= (store.qutestionList.value.length ?? 0)) {
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
    if (store.qutestionList.value[_currentQuestionIndex].selectedOption != null &&
        store.qutestionList.value[_currentQuestionIndex].selectedOption!.isNotEmpty) {
      log(store.qutestionList.value[_currentQuestionIndex].selectedOption.toString());
      isTapped = true;
    } else {
      isTapped = false;
    }
    String questionTxt = store.qutestionList.value[_currentQuestionIndex].questionText ?? "";
    questionTxt =
        questionTxt.replaceAllMapped(RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    List<String> splittedText = questionTxt.split("splittedImage");
    List<Widget> columns = [];
    int index = 0;
    for (String text in splittedText) {
      List<Widget> questionImageWidget = [];
      if (store.qutestionList.value[_currentQuestionIndex].questionImg?.isNotEmpty ?? false) {
        for (String base64String in widget.testExamPaper!.test![_currentQuestionIndex].questionImg!) {
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
              text
                  .trim()
                  .replaceAll("			--", "                 •")
                  .replaceAll("		--", "           •")
                  .replaceAll("	--", "     •")
                  .replaceAll("--", "•"),
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
            questionImageWidget.isNotEmpty
                ? Text(
                    "Tap the image to zoom In/Out",
                    style: interBlack.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      fontWeight: FontWeight.w400,
                      color: ThemeManager.black,
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      );
      index++;
      if (index >= (store.qutestionList.value[_currentQuestionIndex].questionImg?.length ?? 0) - 1) {
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns,
    );
  }

  final ScrollController _scrollController = ScrollController();

  void _scrollToIndex(int index) {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    double totalWidth = (store.qutestionList.value.length ?? 0) *
        (Dimensions.PADDING_SIZE_SMALL * 2.675 + Dimensions.PADDING_SIZE_SMALL * 1.7);

    // Get the viewport width
    double viewportWidth = MediaQuery.of(context).size.width;
    double maxScrollExtent = totalWidth - viewportWidth;
    maxScrollExtent = maxScrollExtent.clamp(0.0, double.infinity);
    double targetScrollPosition =
        index * (Dimensions.PADDING_SIZE_SMALL * 2.675 + Dimensions.PADDING_SIZE_SMALL * 1.7);
    targetScrollPosition = targetScrollPosition.clamp(0.0, maxScrollExtent);

    _scrollController.animateTo(
      targetScrollPosition, // Adjust this value as per your requirement
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> getCountReportPractice(context, String type, bool isCustom) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onGetReportPracticeCountApiCall(widget.userExamId ?? "", type, isCustom);
  }

  void _questionChange(int index) {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    Delta delta = _quillController.document.toDelta();
    store.saveChangeExaplanation(context, {
      "question_id": store.qutestionList.value?[_currentQuestionIndex].sId,
      "annotation_data": delta.toJson()
    });
    store.qutestionList.value?[_currentQuestionIndex].isHighlight = true;
    store.qutestionList.value?[_currentQuestionIndex].annotationData = delta.toJson();
    setState(() {
      _selectedIndex = -1;
      isTapped = false;
      store.qutestionList.value[index].sId;
      if (store.qutestionList.value[index].selectedOption != null &&
          store.qutestionList.value[index].selectedOption!.isNotEmpty) {
        _selectedIndex = store.qutestionList.value[index].optionsData!
            .indexWhere((e) => e.value == store.qutestionList.value[index].selectedOption);
      }
      _currentQuestionIndex = index;
      isbutton = false;
      isprocess = false;
      firstQue = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    final store2 = Provider.of<TestCategoryStore>(context, listen: false);
    explanationWidget = getExplanationText(context);
    questionWidget = getQuestionText(context);
    print(widget.type);
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: ThemeManager.white,
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: ThemeManager.white,
          title: Row(
            children: [
              // InkWell(
              //     onTap: () async {
              //       showLoadingDialog(context);
              //       await store2.triggerAction();
              //       await store2.onExamAttemptList(widget.testExamPaper!.sid!);
              //       await store2.disposeStore();
              //       Navigator.pop(context);
              //       Navigator.pop(context);
              //       Navigator.pop(context);
              //     },
              //     child: SvgPicture.asset(
              //       "assets/image/arrow_back.svg",
              //       color: ThemeManager.currentTheme == AppTheme.Dark
              //           ? AppColors.white
              //           : null,
              //     )),

              // if (!(MediaQuery.of(context).size.width > 1160 &&
              //     MediaQuery.of(context).size.height > 690))
              // const SizedBox(
              //   width: Dimensions.RADIUS_EXTRA_LARGE * 1.1,
              // ),
              Text(
                "${widget.testExamPaper?.examName}",
                style: interRegular.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: ThemeManager.black,
                    // decoration: TextDecoration.underline,
                    decorationColor: ThemeManager.black),
              ),
              Spacer(),
              /*
                if (!(MediaQuery.of(context).size.width > 1160 &&
                    MediaQuery.of(context).size.height > 690))
                  InkWell(
                    onTap: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    child: Image.asset(
                      "assets/image/questionplatte.png",
                      color: ThemeManager.currentTheme == AppTheme.Dark
                          ? AppColors.white
                          : null,
                    ),
                  ),
                  */
              // const Spacer(),
              // SvgPicture.asset("assets/image/testTimeIcon.svg",color: ThemeManager.currentTheme == AppTheme.Dark ? AppColors.white : null,),
              // const SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL,),
              // Text(
              //   "09:05",
              //   style: interRegular.copyWith(
              //     fontSize: Dimensions.fontSizeDefault,
              //     fontWeight: FontWeight.w500,
              //     color: ThemeManager.black,
              //   ),
              // ),

              InkWell(
                onTap: () async {
                  showLoadingDialog(context);
                  await store2.triggerAction();

                  // showDialog(
                  //   context: context,
                  //   builder: (context) => const CustomTestCancelDialogBox(null,null,true),
                  // );
                  await getCountReportPractice(context, widget.type ?? "", widget.isCustom ?? false);
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: ThemeManager.white,
                      surfaceTintColor: ThemeManager.white,
                      alignment: Alignment.center,
                      actionsPadding: const EdgeInsets.only(
                        left: Dimensions.PADDING_SIZE_LARGE,
                        right: Dimensions.PADDING_SIZE_LARGE,
                        bottom: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      content: Observer(builder: (_) {
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize:
                                MainAxisSize.min, // Prevents the column from taking up all available space
                            children: [
                              Center(
                                child: Text(
                                  'Practice Test\nSummary',
                                  textAlign: TextAlign.center,
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeExtraLarge,
                                    fontWeight: FontWeight.w500,
                                    color: ThemeManager.black,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: Dimensions.PADDING_SIZE_SMALL * 3.2,
                              ),
                              Row(
                                children: [
                                  Flexible(
                                    child: _buildDetail(
                                      "Correct",
                                      "${store2.getReportPracticeCountData.value?.correctAnswers ?? 0}",
                                      "assets/image/correct.svg",
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: _buildDetail(
                                      "Incorrect",
                                      "${store2.getReportPracticeCountData.value?.incorrectAnswers ?? 0}",
                                      "assets/image/incorrect.svg",
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Dimensions.PADDING_SIZE_SMALL * 1.6),
                              Row(
                                children: [
                                  Flexible(
                                    child: _buildDetail(
                                      "Total Questions",
                                      "${store2.getReportPracticeCountData.value?.totalQuestions ?? 0}",
                                      "assets/image/total_q.svg",
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: _buildDetail(
                                      "Unanswered",
                                      "${store2.getReportPracticeCountData.value?.notVisited ?? 0}",
                                      "assets/image/skipped1.svg",
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Dimensions.PADDING_SIZE_SMALL * 1.6),
                              _buildDetail(
                                "Bookmarked",
                                "${store2.getReportPracticeCountData.value?.bookmarkCount ?? 0}",
                                "assets/image/bookmark2.svg",
                              ),
                            ],
                          ),
                        );
                      }),
                      actions: [
                        InkWell(
                          onTap: () async {
                            showLoadingDialog(context);
                            await store2.triggerAction();
                            if (widget.type != "McqBookmark" &&
                                widget.type != "MockBookmark" &&
                                widget.type != "Custom") {
                              await store2.onExamAttemptList(widget.testExamPaper!.sid!);
                            } else {
                              final store = Provider.of<BookmarkNewStore>(context, listen: false);
                              store.ongetCustomAnalysisApiCall(widget.type!,
                                  widget.mainId ?? "67c70853be4a8ac3c2761910", widget.isAll ?? false);
                            }
                            await store2.disposeStore();
                            Navigator.pop(context);
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: Dimensions.PADDING_SIZE_DEFAULT * 3,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: ThemeManager.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  offset: const Offset(0, 0),
                                  color: ThemeManager.black.withOpacity(0.04),
                                  blurRadius: 0,
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  offset: const Offset(0, 4.62),
                                  color: ThemeManager.black.withOpacity(0.04),
                                  blurRadius: 10.165,
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  offset: const Offset(0, 19.40),
                                  color: ThemeManager.black.withOpacity(0.03),
                                  blurRadius: 19.40,
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  offset: const Offset(0, 43.436),
                                  color: ThemeManager.black.withOpacity(0.02),
                                  blurRadius: 25.876,
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  offset: const Offset(0, 76.706),
                                  color: ThemeManager.black.withOpacity(0.01),
                                  blurRadius: 30.497,
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  offset: const Offset(0, 120.142),
                                  color: ThemeManager.black.withOpacity(0),
                                  blurRadius: 33.270,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Text(
                              'Save & Exit',
                              style: interRegular.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                fontWeight: FontWeight.w500,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  height: Dimensions.PADDING_SIZE_SMALL * 2.7,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_LARGE),
                  decoration: BoxDecoration(
                      color: ThemeManager.transPrimary,
                      border: Border.all(
                        color: ThemeManager.blueFinalTrans,
                      ),
                      borderRadius: BorderRadius.circular(60)),
                  child: Text(
                    "Save & Exit",
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
        body: Row(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: Dimensions.PADDING_SIZE_LARGE * 1.4,
                              left: Dimensions.PADDING_SIZE_SMALL * 1.6,
                              right: Dimensions.PADDING_SIZE_SMALL * 1.4,
                              // bottom: Dimensions.PADDING_SIZE_LARGE*1.4,
                            ),
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(store2.qutestionList.value.length ?? 0, (index) {
                                  TestData? solutionReport = store2.qutestionList.value[index];

                                  // Determine the background color for each question
                                  Color determineBorderColor() {
                                    if (solutionReport.selectedOption != null &&
                                        solutionReport.selectedOption!.isNotEmpty) {
                                      bool isCorrect = (solutionReport.correctOption ?? "") ==
                                          solutionReport.selectedOption;

                                      return isCorrect ? ThemeManager.greenBorder : ThemeManager.redText;
                                    } else {
                                      print(solutionReport.selectedOption.toString());
                                      return solutionReport.skipped == true
                                          ? ThemeManager.evolveYellow
                                          : _currentQuestionIndex == index
                                              ? ThemeManager.primaryColor
                                              : ThemeManager.black;
                                    }
                                  }

                                  return GestureDetector(
                                    onTap: () {
                                      _questionChange(index);
                                    },
                                    child: Container(
                                      height: Dimensions.PADDING_SIZE_SMALL * 2.675,
                                      width: Dimensions.PADDING_SIZE_SMALL * 2.675,
                                      margin:
                                          const EdgeInsets.only(right: Dimensions.PADDING_SIZE_SMALL * 1.7),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        // color: determineBackgroundColor(),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: determineBorderColor(),
                                        ),
                                      ),
                                      child: Text(
                                        "${index + 1}",
                                        style: interRegular.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            fontWeight: FontWeight.w500,
                                            color: determineBorderColor()),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: ThemeManager.currentTheme == AppTheme.Dark
                                  ? Colors.transparent
                                  : const Color(0xFFF2F8FF),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Correct
                                  buildScoreItem(
                                    path: "assets/image/correct_i.svg",
                                    color: Colors.green,
                                    label:
                                        '${calculateExamMetrics(widget.testExamPaper == null ? [] : store2.qutestionList.value)['attempted_correct']}',
                                    label2: "",
                                  ),
                                  // Incorrect
                                  buildScoreItem(
                                      path: 'assets/image/wrong_i.svg',
                                      color: Colors.red,
                                      label:
                                          '${calculateExamMetrics(widget.testExamPaper == null ? [] : store2.qutestionList.value)['attempted_incorrect']}',
                                      label2: ""),
                                  // Attempted
                                  buildScoreItem(
                                      path: null, // No icon for Attempted
                                      color: Colors.purple,
                                      label:
                                          '${calculateExamMetrics(widget.testExamPaper == null ? [] : store2.qutestionList.value)['total_attempted']} ',
                                      isTextOnly: true,
                                      label2: "Attempted"),
                                  // Unattempted
                                  buildScoreItem(
                                      path: null, // No icon for Unattempted
                                      color: Colors.blue,
                                      label:
                                          '${calculateExamMetrics(widget.testExamPaper == null ? [] : store2.qutestionList.value)['total_unattempted']} ',
                                      isTextOnly: true,
                                      label2: "Unattempted"),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: Dimensions.PADDING_SIZE_LARGE * 0.8,
                              left: Dimensions.PADDING_SIZE_DEFAULT,
                              right: Dimensions.PADDING_SIZE_DEFAULT,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  "${_currentQuestionIndex + 1}.",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeExtraExtraLarge,
                                    fontWeight: FontWeight.w500,
                                    color: ThemeManager.black,
                                  ),
                                ),
                                const Spacer(),
                                VisibilityDetector(
                                  key: Key('button-key2'),
                                  onVisibilityChanged: (info) {
                                    setState(() {
                                      isButtonVisible2 = info.visibleFraction > 0;
                                    });
                                  },
                                  child: InkWell(
                                      onTap: () {
                                        _putBookMarkApiCall(widget.testExamPaper?.examId ?? "",
                                            store2.qutestionList.value[_currentQuestionIndex].sId ?? "");
                                      },
                                      child: BookmarkWidget(
                                        isSelected:
                                            store2.qutestionList.value[_currentQuestionIndex].bookmarks ??
                                                false,
                                      )),
                                ),
                                const SizedBox(
                                  width: Dimensions.PADDING_SIZE_EXTRA_SMALL * 1.6,
                                ),
                                InkWell(
                                    onTap: () {
                                      if (Platform.isWindows || Platform.isMacOS) {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              backgroundColor: ThemeManager.mainBackground,
                                              actionsPadding: EdgeInsets.zero,
                                              actions: [
                                                CustomBottomAskFaculty(
                                                    questionId: widget.testExamPaper
                                                            ?.test?[_currentQuestionIndex].sId ??
                                                        "",
                                                    questionText: widget.testExamPaper
                                                            ?.test?[_currentQuestionIndex].questionText ??
                                                        '',
                                                    allOptions:
                                                        "a) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[0].answerTitle}\nb) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[1].answerTitle}\nc) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[2].answerTitle}\nd) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[3].answerTitle}"),
                                              ],
                                            );
                                          },
                                        );
                                      } else {
                                        showModalBottomSheet<String>(
                                            isScrollControlled: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(25),
                                              ),
                                            ),
                                            clipBehavior: Clip.antiAliasWithSaveLayer,
                                            context: context,
                                            builder: (BuildContext context) {
                                              // return CustomBottomRaiseQuery(questionId: questionId);
                                              return CustomBottomAskFaculty(
                                                  questionId: widget
                                                          .testExamPaper?.test?[_currentQuestionIndex].sId ??
                                                      "",
                                                  questionText: widget.testExamPaper
                                                          ?.test?[_currentQuestionIndex].questionText ??
                                                      '',
                                                  allOptions:
                                                      "a) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[0].answerTitle}\nb) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[1].answerTitle}\nc) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[2].answerTitle}\nd) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[3].answerTitle}");
                                            });
                                      }
                                    },
                                    child: SvgPicture.asset('assets/image/support.svg')),
                                const SizedBox(
                                  width: Dimensions.PADDING_SIZE_EXTRA_SMALL * 1.6,
                                ),
                                InkWell(
                                    onTap: () {
                                      if (Platform.isWindows || Platform.isMacOS) {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              backgroundColor: ThemeManager.mainBackground,
                                              actionsPadding: EdgeInsets.zero,
                                              actions: [
                                                CustomBottomReportIssue(
                                                    questionId: widget.testExamPaper
                                                            ?.test?[_currentQuestionIndex].sId ??
                                                        "",
                                                    questionText: widget.testExamPaper
                                                            ?.test?[_currentQuestionIndex].questionText ??
                                                        '',
                                                    allOptions:
                                                        "a) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[0].answerTitle}\nb) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[1].answerTitle}\nc) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[2].answerTitle}\nd) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[3].answerTitle}"),
                                              ],
                                            );
                                          },
                                        );
                                      } else {
                                        showModalBottomSheet<String>(
                                            isScrollControlled: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(25),
                                              ),
                                            ),
                                            clipBehavior: Clip.antiAliasWithSaveLayer,
                                            context: context,
                                            builder: (BuildContext context) {
                                              // return CustomBottomRaiseQuery(questionId: questionId);
                                              return CustomBottomReportIssue(
                                                  questionId: widget
                                                          .testExamPaper?.test?[_currentQuestionIndex].sId ??
                                                      "",
                                                  questionText: widget.testExamPaper
                                                          ?.test?[_currentQuestionIndex].questionText ??
                                                      '',
                                                  allOptions:
                                                      "a) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[0].answerTitle}\nb) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[1].answerTitle}\nc) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[2].answerTitle}\nd) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[3].answerTitle}");
                                            });
                                      }
                                    },
                                    child: SvgPicture.asset('assets/image/message.svg')),
                                const SizedBox(
                                  width: Dimensions.PADDING_SIZE_EXTRA_SMALL * 1.6,
                                ),
                                InkWell(
                                  onTap: () async {
                                    if (!isbutton) {
                                      setState(() {
                                        isprocess = true;
                                      });
                                    }
                                    TestData? solutionReport =
                                        widget.testExamPaper?.test?[_currentQuestionIndex];

                                    final questionText = solutionReport?.questionText;
                                    final currentOption = solutionReport?.correctOption;

                                    final answerTitle =
                                        solutionReport?.optionsData?.map((e) => e.answerTitle);

                                    int currentIndex = solutionReport?.optionsData
                                            ?.indexWhere((e) => e.value == currentOption) ??
                                        -1;
                                    String? currentAnswerTitle = answerTitle?.elementAt(currentIndex);

                                    List<String?> notMatchingAnswerTitles =
                                        answerTitle?.where((title) => title != currentAnswerTitle).toList() ??
                                            [];
                                    String concatenatedTitles =
                                        notMatchingAnswerTitles.where((title) => title != null).join(", ");

                                    String question =
                                        "Explain why $currentAnswerTitle is the answer to the Question $questionText and why the remaining $concatenatedTitles are not correct answer";
                                    debugPrint("question12 :$question");
                                    isbutton == false ? await _getExplanationData(question) : null;
                                  },
                                  child: isprocess
                                      ? CupertinoActivityIndicator(
                                          color: ThemeManager.black,
                                        )
                                      : SvgPicture.asset('assets/image/ai.svg'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: Dimensions.PADDING_SIZE_DEFAULT,
                              right: Dimensions.PADDING_SIZE_DEFAULT,
                              // bottom: Dimensions.PADDING_SIZE_LARGE*1.4,
                            ),
                            child: GestureDetector(
                              onHorizontalDragEnd: (DragEndDetails details) {
                                final questionsLength = store2.qutestionList.value.length ?? 0;
                                if (questionsLength == 0) return;

                                // Swipe left: next question (velocity > 300)
                                if (details.velocity.pixelsPerSecond.dx < -300) {
                                  if (_currentQuestionIndex < questionsLength - 1) {
                                    _showNextQuestion();
                                  }
                                }
                                // Swipe right: previous question (velocity < -300)
                                else if (details.velocity.pixelsPerSecond.dx > 300) {
                                  if (_currentQuestionIndex > 0) {
                                    _showPreviousQuestion();
                                  }
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  questionWidget ?? const SizedBox(),
                                  const SizedBox(
                                    height: Dimensions.PADDING_SIZE_DEFAULT,
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.only(),
                                    // padding: EdgeInsets.zero,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount:
                                        store2.qutestionList.value[_currentQuestionIndex].optionsData?.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      TestData? testExamPaper =
                                          store2.qutestionList.value[_currentQuestionIndex];
                                      String base64String = testExamPaper.optionsData?[index].answerImg ?? "";
                                      bool isSelected = index == _selectedIndex;
                                      String showTxt = "";
                                      Color showColor = ThemeManager.borderBlue;
                                      Color showColor2 = ThemeManager.black;
                                      Color showColorBorder = ThemeManager.grey1;

                                      if (_selectedIndex >= 0 &&
                                          _selectedIndex < (testExamPaper.optionsData?.length ?? 0)) {
                                        showTxt = ((testExamPaper.correctOption ?? "") ==
                                                (testExamPaper.optionsData?[index].value ?? ""))
                                            ? "Correct Answer"
                                            : ((testExamPaper.optionsData?[_selectedIndex].value ?? "") ==
                                                    (testExamPaper.optionsData?[index].value ?? ""))
                                                ? "Incorrect Answer"
                                                : "";

                                        showColor = ((testExamPaper.correctOption ?? "") ==
                                                (testExamPaper.optionsData?[index].value ?? ""))
                                            ? ThemeManager.greenSuccess
                                            : ((testExamPaper.optionsData?[_selectedIndex].value ?? "") ==
                                                    (testExamPaper.optionsData?[index].value ?? ""))
                                                ? ThemeManager.redAlert
                                                : ThemeManager.white;

                                        showColor2 = ((testExamPaper.correctOption ?? "") ==
                                                (testExamPaper.optionsData?[index].value ?? ""))
                                            ? ThemeManager.greenSuccess
                                            : ((testExamPaper.optionsData?[_selectedIndex].value ?? "") ==
                                                    (testExamPaper.optionsData?[index].value ?? ""))
                                                ? ThemeManager.redAlert
                                                : ThemeManager.black;

                                        showColorBorder = ((testExamPaper.correctOption ?? "") ==
                                                (testExamPaper.optionsData?[index].value ?? ""))
                                            ? ThemeManager.correctChart
                                            : ((testExamPaper.optionsData?[_selectedIndex].value ?? "") ==
                                                    (testExamPaper.optionsData?[index].value ?? ""))
                                                ? ThemeManager.evolveRed
                                                : ThemeManager.grey1;
                                      }
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_DEFAULT),
                                        child: InkWell(
                                          onTap: () {
                                            Haptics.selection();
                                            setState(() {
                                              if (widget.isPracticeExam == true) {
                                                if (!isTapped) {
                                                  isTapped = true;
                                                  _selectedIndex = index;
                                                  store2.qutestionList.value[_currentQuestionIndex]
                                                          .selectedOption =
                                                      testExamPaper.optionsData?[index].value;
                                                  _postPracticeData();
                                                }
                                              } else {
                                                if (isSelected) {
                                                  _selectedIndex = -1;
                                                } else {
                                                  _selectedIndex = index;
                                                  store2.qutestionList.value[_currentQuestionIndex]
                                                          .selectedOption =
                                                      testExamPaper.optionsData?[index].value;
                                                }
                                              }
                                            });
                                          },
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: isTapped ? showColorBorder : ThemeManager.grey1,
                                                      width: 0.84),
                                                  borderRadius: BorderRadius.circular(8),
                                                  color: isTapped
                                                      ? showColor.withOpacity(0.1)
                                                      : ThemeManager.white,
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: Dimensions.PADDING_SIZE_LARGE,
                                                    vertical: Dimensions.PADDING_SIZE_SMALL * 1.5,
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
                                                                "${testExamPaper?.optionsData?[index].value ?? ""}.  ",
                                                                style: TextStyle(
                                                                  fontSize: Dimensions.fontSizeLarge,
                                                                  fontWeight: FontWeight.w400,
                                                                  color: showColor2,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width:
                                                                    MediaQuery.of(context).size.width * 0.6,
                                                                child: Text(
                                                                  testExamPaper
                                                                          .optionsData?[index].answerTitle ??
                                                                      "",
                                                                  style: TextStyle(
                                                                    fontSize: Dimensions.fontSizeLarge,
                                                                    fontWeight: FontWeight.w400,
                                                                    color: showColor2,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          testExamPaper.optionsData?[index].answerImg != ""
                                                              ? Row(
                                                                  children: [
                                                                    InteractiveViewer(
                                                                      minScale: 1.0,
                                                                      maxScale: 3.0,
                                                                      child: Center(
                                                                        child: SizedBox(
                                                                          width: MediaQuery.of(context)
                                                                                  .size
                                                                                  .width *
                                                                              0.6,
                                                                          height: 250,
                                                                          child: Stack(
                                                                            children: [
                                                                              // if (answerImgBytes != null)
                                                                              //   Image.memory(answerImgBytes!),
                                                                              if (base64String != '')
                                                                                Image.network(base64String),
                                                                              Container(
                                                                                  color: Colors.transparent),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                )
                                                              : const SizedBox(),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              if ((testExamPaper.correctOption ?? "") ==
                                                      (testExamPaper.optionsData?[index].value ?? "") &&
                                                  (isTapped == true && widget.isPracticeExam == true))
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                                                  child: Text(
                                                    "${testExamPaper.optionsData?[index].percentage ?? "0"}% Got this answer correct",
                                                    style: TextStyle(
                                                      fontSize: Dimensions.fontSizeSmall,
                                                      color: (testExamPaper.correctOption ?? "") ==
                                                              (testExamPaper.optionsData?[index].value ?? "")
                                                          ? ThemeManager.greenSuccess
                                                          : ThemeManager.orangeColor,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                )
                                              else if (((testExamPaper.selectedOption ?? "") ==
                                                      (testExamPaper.optionsData?[index].value ?? "")) &&
                                                  (isTapped == true && widget.isPracticeExam == true))
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                                                  child: Text(
                                                    "${testExamPaper.optionsData?[index].percentage ?? "0"}% Marked this incorrect",
                                                    style: TextStyle(
                                                      fontSize: Dimensions.fontSizeSmall,
                                                      color: ThemeManager.redAlert,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                )
                                              else if (((testExamPaper.correctOption ?? "") !=
                                                      (testExamPaper.optionsData?[index].value ?? "")) &&
                                                  !((testExamPaper.selectedOption ?? "") ==
                                                      (testExamPaper.optionsData?[index].value ?? "")) &&
                                                  (isTapped == true && widget.isPracticeExam == true))
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                                                  child: Text(
                                                    "${testExamPaper.optionsData?[index].percentage ?? "0"}% Marked this",
                                                    style: TextStyle(
                                                      fontSize: Dimensions.fontSizeSmall,
                                                      color: ThemeManager.orangeColor,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              // const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL,),
                                              // ((solutionReport?.correctOption??"") == (solutionReport?.options?[index].value??"")) ||
                                              //     ((solutionReport?.selectedOption??"") == (solutionReport?.options?[index].value??"")) || ((solutionReport?.guess??"") == (solutionReport?.options?[index].value??"")) ?
                                              // Text(
                                              //   showTxt,
                                              //   style: TextStyle(
                                              //       fontSize: Dimensions.fontSizeSmall,
                                              //       fontWeight: FontWeight.w400,
                                              //       color: showColor
                                              //   ),):const SizedBox()
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  (isTapped == true && widget.isPracticeExam == true)
                                      ? Observer(
                                          builder: (BuildContext context) {
                                            GetNotesSolutionModel? noteModel = store.notesData.value;
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                //Solution Explanation
                                                Row(
                                                  children: [
                                                    // Text("Explanation",
                                                    //   style: interBlack.copyWith(
                                                    //     fontSize: Dimensions.fontSizeLarge,
                                                    //     fontWeight: FontWeight.w500,
                                                    //     color: ThemeManager.black,
                                                    //   ),),
                                                    // const Spacer(),
                                                    // InkWell(
                                                    //   onTap: (){
                                                    //     _showNotesDialog(context, store.qutestionList.value[_currentQuestionIndex].sId ?? "", noteModel?.notes??"");
                                                    //   },
                                                    //   child: SvgPicture.asset("assets/image/penIcon.svg"),
                                                    // ),
                                                    //       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,onPressed: (){
                                                    //   _showNotesDialog(context, store.qutestionList.value[_currentQuestionIndex].sId ?? "", noteModel?.notes??"");
                                                    // }, icon: Icon(Icons.edit_note_sharp,color: Theme.of(context).hintColor,)),
                                                    Text(
                                                      "Explanation:",
                                                      style: interBlack.copyWith(
                                                        fontSize: Dimensions.fontSizeLarge,
                                                        fontWeight: FontWeight.w700,
                                                        color: ThemeManager.black,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    VisibilityDetector(
                                                      key: Key('button-key'),
                                                      onVisibilityChanged: (info) {
                                                        setState(() {
                                                          isButtonVisible = info.visibleFraction > 0;
                                                        });

                                                        if (info.visibleFraction == 0) {
                                                          print('Button is out of view');
                                                        } else {
                                                          print('Button is visible');
                                                        }
                                                      },
                                                      child: CommonTool(
                                                        onTap: () {
                                                          final store = Provider.of<TestCategoryStore>(
                                                              context,
                                                              listen: false);
                                                          isbutton = false;
                                                          firstQue = false;
                                                          isTapped = false;
                                                          String? questionId = store
                                                              .qutestionList.value[_currentQuestionIndex].sId;

                                                          Delta delta = _quillController.document.toDelta();
                                                          store.saveChangeExaplanation(context, {
                                                            "question_id": questionId,
                                                            "annotation_data": delta.toJson()
                                                          });
                                                          store.qutestionList.value[_currentQuestionIndex]
                                                              .isHighlight = true;
                                                          store.qutestionList.value[_currentQuestionIndex]
                                                              .annotationData = delta.toJson();
                                                        },
                                                        controller: _quillController,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 10,
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        _showNotesDialog(
                                                            context,
                                                            widget.testExamPaper?.test?[_currentQuestionIndex]
                                                                    .sId ??
                                                                "",
                                                            noteModel?.notes ?? "");
                                                      },
                                                      child: SvgPicture.asset(
                                                        "assets/image/notes1.svg",
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 10,
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        _showBottomSheet(context);
                                                      },
                                                      child: SvgPicture.asset(
                                                        "assets/image/atoz.svg",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                // const SizedBox(
                                                //   height:
                                                //       Dimensions.PADDING_SIZE_DEFAULT,
                                                // ),
                                                SingleChildScrollView(
                                                  child: Column(
                                                    children: [
                                                      explanationWidget ?? const SizedBox(),
                                                      const SizedBox(
                                                        height: Dimensions.PADDING_SIZE_DEFAULT,
                                                      ),
                                                      isbutton == true
                                                          ? Observer(
                                                              builder: (BuildContext context) {
                                                                GetExplanationModel? getExplainModel =
                                                                    store.getExplanationText.value;
                                                                // debugPrint("store.getExplanationText.value.text: ${store.getExplanationText.value?.text}");
                                                                return Container(
                                                                  padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          Dimensions.PADDING_SIZE_LARGE,
                                                                      vertical:
                                                                          Dimensions.PADDING_SIZE_LARGE),
                                                                  decoration: BoxDecoration(
                                                                      color: ThemeManager.explainContainer,
                                                                      borderRadius: BorderRadius.circular(
                                                                          Dimensions.RADIUS_DEFAULT)),
                                                                  child: Column(
                                                                    children: [
                                                                      Row(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children: [
                                                                          Container(
                                                                            width: Dimensions
                                                                                    .PADDING_SIZE_DEFAULT *
                                                                                2.4,
                                                                            height: Dimensions
                                                                                    .PADDING_SIZE_DEFAULT *
                                                                                2.4,
                                                                            alignment: Alignment.center,
                                                                            decoration: BoxDecoration(
                                                                              shape: BoxShape.circle,
                                                                              color:
                                                                                  ThemeManager.whitePrimary,
                                                                            ),
                                                                            child: Text(
                                                                              "AI",
                                                                              style: interBlack.copyWith(
                                                                                fontSize:
                                                                                    Dimensions.fontSizeLarge,
                                                                                fontWeight: FontWeight.w700,
                                                                                color:
                                                                                    ThemeManager.primaryWhite,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                            width:
                                                                                Dimensions.PADDING_SIZE_SMALL,
                                                                          ),
                                                                          Text(
                                                                            "Cortex.AI ",
                                                                            style: interBlack.copyWith(
                                                                              fontSize: Dimensions
                                                                                  .fontSizeExtraLarge,
                                                                              fontWeight: FontWeight.w500,
                                                                              color: AppColors.white,
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            "Explains",
                                                                            style: interBlack.copyWith(
                                                                              fontSize: Dimensions
                                                                                  .fontSizeExtraLarge,
                                                                              fontWeight: FontWeight.w700,
                                                                              color: AppColors.white,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            Dimensions.PADDING_SIZE_DEFAULT,
                                                                      ),
                                                                      TypeWriterText(
                                                                        text: Text(
                                                                          getExplainModel?.text ?? '',
                                                                          style: interBlack.copyWith(
                                                                            fontSize:
                                                                                Dimensions.fontSizeDefault,
                                                                            fontWeight: FontWeight.w400,
                                                                            color: AppColors.white,
                                                                          ),
                                                                        ),
                                                                        maintainSize: false,
                                                                        duration:
                                                                            const Duration(milliseconds: 10),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                            )
                                                          : const SizedBox(),
                                                      const SizedBox(
                                                        height: Dimensions.PADDING_SIZE_DEFAULT,
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            );
                                          },
                                        )
                                      : const SizedBox()
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: Dimensions.PADDING_SIZE_DEFAULT,
                  ),
                  if (!isButtonVisible2) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isButtonVisible && (isTapped == true && widget.isPracticeExam == true)) ...[
                          CommonTool(
                            onTap: () {
                              final store = Provider.of<TestCategoryStore>(context, listen: false);
                              isbutton = false;
                              firstQue = false;
                              isTapped = false;
                              String? questionId = store.qutestionList.value[_currentQuestionIndex].sId;

                              Delta delta = _quillController.document.toDelta();
                              store.saveChangeExaplanation(
                                  context, {"question_id": questionId, "annotation_data": delta.toJson()});
                              store.qutestionList.value[_currentQuestionIndex].isHighlight = true;
                              store.qutestionList.value[_currentQuestionIndex].annotationData =
                                  delta.toJson();
                            },
                            controller: _quillController,
                          ),
                          const SizedBox(
                            width: 0,
                          ),
                        ],
                        InkWell(
                            onTap: () {
                              _putBookMarkApiCall(widget.testExamPaper?.examId ?? "",
                                  store2.qutestionList.value[_currentQuestionIndex].sId ?? "");
                            },
                            child: BookmarkWidget(
                              isSelected:
                                  store2.qutestionList.value[_currentQuestionIndex].bookmarks ?? false,
                            )),
                        const SizedBox(
                          width: Dimensions.PADDING_SIZE_EXTRA_SMALL * 1.6,
                        ),
                        InkWell(
                            onTap: () {
                              if (Platform.isWindows || Platform.isMacOS) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: ThemeManager.mainBackground,
                                      actionsPadding: EdgeInsets.zero,
                                      actions: [
                                        CustomBottomAskFaculty(
                                            questionId:
                                                widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "",
                                            questionText: widget.testExamPaper?.test?[_currentQuestionIndex]
                                                    .questionText ??
                                                '',
                                            allOptions:
                                                "a) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[0].answerTitle}\nb) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[1].answerTitle}\nc) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[2].answerTitle}\nd) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[3].answerTitle}"),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                showModalBottomSheet<String>(
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(25),
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    context: context,
                                    builder: (BuildContext context) {
                                      // return CustomBottomRaiseQuery(questionId: questionId);
                                      return CustomBottomAskFaculty(
                                          questionId:
                                              widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "",
                                          questionText: widget
                                                  .testExamPaper?.test?[_currentQuestionIndex].questionText ??
                                              '',
                                          allOptions:
                                              "a) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[0].answerTitle}\nb) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[1].answerTitle}\nc) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[2].answerTitle}\nd) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[3].answerTitle}");
                                    });
                              }
                            },
                            child: SvgPicture.asset('assets/image/support.svg')),
                        const SizedBox(
                          width: Dimensions.PADDING_SIZE_EXTRA_SMALL * 1.6,
                        ),
                        InkWell(
                            onTap: () {
                              if (Platform.isWindows || Platform.isMacOS) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: ThemeManager.mainBackground,
                                      actionsPadding: EdgeInsets.zero,
                                      actions: [
                                        CustomBottomReportIssue(
                                            questionId:
                                                widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "",
                                            questionText: widget.testExamPaper?.test?[_currentQuestionIndex]
                                                    .questionText ??
                                                '',
                                            allOptions:
                                                "a) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[0].answerTitle}\nb) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[1].answerTitle}\nc) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[2].answerTitle}\nd) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[3].answerTitle}"),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                showModalBottomSheet<String>(
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(25),
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    context: context,
                                    builder: (BuildContext context) {
                                      // return CustomBottomRaiseQuery(questionId: questionId);
                                      return CustomBottomReportIssue(
                                          questionId:
                                              widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "",
                                          questionText: widget
                                                  .testExamPaper?.test?[_currentQuestionIndex].questionText ??
                                              '',
                                          allOptions:
                                              "a) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[0].answerTitle}\nb) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[1].answerTitle}\nc) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[2].answerTitle}\nd) ${store2.qutestionList.value[_currentQuestionIndex].optionsData?[3].answerTitle}");
                                    });
                              }
                            },
                            child: SvgPicture.asset('assets/image/message.svg')),
                        const SizedBox(
                          width: Dimensions.PADDING_SIZE_EXTRA_SMALL * 1.6,
                        ),
                        InkWell(
                          onTap: () async {
                            if (!isbutton) {
                              setState(() {
                                isprocess = true;
                              });
                            }
                            TestData? solutionReport = widget.testExamPaper?.test?[_currentQuestionIndex];

                            final questionText = solutionReport?.questionText;
                            final currentOption = solutionReport?.correctOption;

                            final answerTitle = solutionReport?.optionsData?.map((e) => e.answerTitle);

                            int currentIndex =
                                solutionReport?.optionsData?.indexWhere((e) => e.value == currentOption) ??
                                    -1;
                            String? currentAnswerTitle = answerTitle?.elementAt(currentIndex);

                            List<String?> notMatchingAnswerTitles =
                                answerTitle?.where((title) => title != currentAnswerTitle).toList() ?? [];
                            String concatenatedTitles =
                                notMatchingAnswerTitles.where((title) => title != null).join(", ");

                            String question =
                                "Explain why $currentAnswerTitle is the answer to the Question $questionText and why the remaining $concatenatedTitles are not correct answer";
                            debugPrint("question12 :$question");
                            isbutton == false ? await _getExplanationData(question) : null;
                          },
                          child: isprocess
                              ? CupertinoActivityIndicator(
                                  color: ThemeManager.black,
                                )
                              : SvgPicture.asset('assets/image/ai.svg'),
                        ),
                        if (!isButtonVisible && (isTapped == true && widget.isPracticeExam == true)) ...[
                          const SizedBox(
                            width: 10,
                          ),
                          GestureDetector(
                            onTap: () {
                              GetNotesSolutionModel? noteModel = store.notesData.value;
                              _showNotesDialog(
                                  context,
                                  widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "",
                                  noteModel?.notes ?? "");
                            },
                            child: SvgPicture.asset(
                              "assets/image/notes1.svg",
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          GestureDetector(
                            onTap: () {
                              _showBottomSheet(context);
                            },
                            child: SvgPicture.asset(
                              "assets/image/atoz.svg",
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                        ]
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                  ],
                  Container(
                    color: ThemeManager.buttonBackground,
                    padding: const EdgeInsets.only(
                        top: Dimensions.PADDING_SIZE_DEFAULT * 1.2,
                        left: Dimensions.PADDING_SIZE_EXTRA_LARGE * 1.1,
                        right: Dimensions.PADDING_SIZE_LARGE * 1.3,
                        bottom: Dimensions.PADDING_SIZE_LARGE * 1.33),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: CustomPreviewBox(
                            onTap: isprocess == true ? null : (firstQue ? null : _showPreviousQuestion),
                            text: "Previous",
                          ),
                        ),
                        const SizedBox(
                          width: Dimensions.PADDING_SIZE_DEFAULT * 1.1,
                        ),
                        Expanded(
                          child: CustomPreviewBox(
                            textColor: ThemeManager.white,
                            bgColor: ThemeManager.blueFinal,
                            borderColor: Colors.transparent,
                            onTap: isprocess == true ? null : _showNextQuestion,
                            text: (_currentQuestionIndex == (store2.qutestionList.value.length ?? 0) - 1)
                                ? "Save"
                                : "Next",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotesDialog(BuildContext context, String questionId, String notes) {
    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: ThemeManager.mainBackground,
            actionsPadding: EdgeInsets.zero,
            insetPadding: const EdgeInsets.symmetric(horizontal: 250),
            actions: [
              CustomBottomStickNotesWindow(questionId: questionId, notes: notes),
            ],
          );
        },
      );
    } else {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black.withOpacity(0.35),
          barrierDismissible: true,
          pageBuilder:
              (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: Center(
                child: CustomBottomStickNotes(
                  questionId: questionId,
                  notes: notes,
                ),
              ),
            );
          },
        ),
      );
    }
  }

  Future<void> _showBottomSheet(BuildContext context) async {
    if (Platform.isWindows || Platform.isMacOS) {
      final double? selectedFontSize = await showDialog<double>(
        context: context,
        builder: (BuildContext context) {
          double currentFontSize = _textSize;
          double currentPercentFontSize = _textSizePercent;
          double showCurrFontSize = showfontSize;

          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 250),
            backgroundColor: ThemeManager.mainBackground,
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Sample Text',
                          style: interBlack.copyWith(
                            fontSize: currentFontSize,
                            fontWeight: FontWeight.w400,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Font size',
                          style: interBlack.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            fontWeight: FontWeight.w400,
                            color: AppColors.black,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setModalState(() {
                                  if (showCurrFontSize > 50) {
                                    showCurrFontSize -= 10;
                                    currentPercentFontSize -= 10;
                                    currentFontSize -= 1;
                                  }
                                });
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.grey[600],
                            ),
                            Text(
                              '$showCurrFontSize',
                              style: const TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              onPressed: () {
                                setModalState(() {
                                  showCurrFontSize += 10;
                                  currentPercentFontSize += 10;
                                  currentFontSize += 1;
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          buttonText: "Cancel",
                          width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 6,
                          height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                          textAlign: TextAlign.center,
                          radius: Dimensions.RADIUS_DEFAULT,
                          transparent: true,
                          bgColor: ThemeManager.btnGrey,
                          fontSize: Dimensions.fontSizeDefault,
                        ),
                        CustomButton(
                          onPressed: () {
                            Navigator.pop(context, currentPercentFontSize);
                          },
                          buttonText: "Apply",
                          width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 6,
                          height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                          textAlign: TextAlign.center,
                          radius: Dimensions.RADIUS_DEFAULT,
                          transparent: true,
                          bgColor: Theme.of(context).primaryColor,
                          fontSize: Dimensions.fontSizeDefault,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        },
      );

      if (selectedFontSize != null) {
        setState(() {
          _textSize = selectedFontSize;
          _textSizePercent = selectedFontSize;
          print(selectedFontSize);
          showfontSize = (100 + ((selectedFontSize - Dimensions.fontSizeDefault) * 10));
        });
      }
    } else {
      final dynamic? selectedFontSize = await showDialog<dynamic>(
        context: context,
        builder: (BuildContext context) {
          double currentFontSize = _textSize;
          double currentPercentFontSize = _textSizePercent;
          double showCurrFontSize = showfontSize;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // More pronounced rounded corners
            ),
            elevation: 10, // Added elevation for a shadow effect
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 40), // Horizontal padding for better alignment
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Padding(
                  padding: const EdgeInsets.all(16.0), // Added more padding for a spacious look
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Section with a soft divider
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                        ),
                        child: Text(
                          'Adjust Font Size',
                          style: interBlack.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600, // More prominent title
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Font Size Preview Box with rounded corners
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Sample Text',
                            style: interBlack.copyWith(
                              fontSize: currentFontSize,
                              fontWeight: FontWeight.w400,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Font Size Adjuster
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Font Size',
                            style: interBlack.copyWith(
                              fontSize: Dimensions.fontSizeDefault + 2, // Slightly larger for visibility
                              fontWeight: FontWeight.w500,
                              color: AppColors.black,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  setModalState(() {
                                    if (showCurrFontSize > 50) {
                                      showCurrFontSize -= 10;
                                      currentPercentFontSize -= 10;
                                      currentFontSize -= 1;
                                    }
                                  });
                                },
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.grey[600],
                              ),
                              Text(
                                '$showCurrFontSize',
                                style: const TextStyle(fontSize: 18),
                              ),
                              IconButton(
                                onPressed: () {
                                  setModalState(() {
                                    print(currentPercentFontSize);
                                    showCurrFontSize += 10;
                                    currentPercentFontSize += 10;
                                    currentFontSize += 1;
                                  });
                                },
                                icon: const Icon(Icons.add_circle_outline),
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Divider for separation
                      const Divider(height: 2, color: Colors.grey),

                      const SizedBox(height: 20),

                      // Buttons Row with cleaner spacing
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: CustomButton(
                              onPressed: () {
                                Navigator.pop(context); // Close dialog
                              },
                              buttonText: "Cancel",
                              height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                              radius: Dimensions.RADIUS_DEFAULT,
                              transparent: true,
                              bgColor: ThemeManager.btnGrey,
                              fontSize: Dimensions.fontSizeDefault,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomButton(
                              onPressed: () {
                                Navigator.pop(context, {
                                  "currentPercentFontSize": currentPercentFontSize,
                                  "currentFontSize": currentFontSize
                                }); // Return the updated font size
                              },
                              buttonText: "Apply",
                              height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                              radius: Dimensions.RADIUS_DEFAULT,
                              transparent: true,
                              bgColor: Theme.of(context).primaryColor,
                              fontSize: Dimensions.fontSizeDefault,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );

      if (selectedFontSize != null) {
        setState(() {
          _textSize = selectedFontSize["currentFontSize"];
          _textSizePercent = selectedFontSize["currentPercentFontSize"];
          print(selectedFontSize["currentPercentFontSize"]);
          showfontSize =
              (100 + ((selectedFontSize["currentFontSize"] - Dimensions.fontSizeDefault) * 10)) as double;
        });
      }
    }
  }

  Widget buildScoreItem({
    String? path,
    required Color color,
    required String label,
    required String label2,
    bool isTextOnly = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!isTextOnly && path != null) ...[
          SvgPicture.asset(
            path,
          ),
          const SizedBox(width: 4),
        ],
        Row(
          children: [
            if (label2 != "") ...[
              Container(
                height: 20,
                width: 2,
                color: color,
              ),
              const SizedBox(
                width: 5,
              )
            ],
            Text(
              label,
              style: interSemiBold.copyWith(
                color: color,
                fontSize: 15,
              ),
            ),
            Text(
              label2,
              style: interRegular.copyWith(
                color: ThemeManager.grey4,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> addNotes(String? questionId, String? notes) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    final store2 = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onCreateNotes(context, questionId ?? "", notes ?? "");
    _getNotesData(store2.qutestionList.value[_currentQuestionIndex].sId ?? "");
    BottomToast.showBottomToastOverlay(
      context: context,
      errorMessage: "Notes Added Successfully!",
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  Future<void> _getNotesData(String queId) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onGetNotesData(queId);
    debugPrint('queIdbookmark$queId');
  }

  void _showDialog(BuildContext context, String questionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        TextEditingController queryController = TextEditingController();
        String errorText = '';

        return AlertDialog(
          title: Text(
            'Have a Query?',
            style: interRegular.copyWith(
              fontSize: Dimensions.fontSizeExtraLarge,
              fontWeight: FontWeight.w500,
              color: ThemeManager.black,
            ),
          ),
          content: Form(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.2,
              child: TextFormField(
                cursorColor: Theme.of(context).primaryColor,
                controller: queryController,
                maxLines: 7,
                decoration: InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  hintText: 'Enter your query...',
                  hintStyle: interRegular.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).hintColor,
                  ),
                  errorText: 'Please enter your query',
                  errorStyle: interRegular.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                style: interRegular.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  fontWeight: FontWeight.w400,
                  color: ThemeManager.black,
                ),
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: Dimensions.PADDING_SIZE_LARGE * 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Theme.of(context).hintColor),
                    child: Text(
                      'Cancel',
                      style: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: Dimensions.PADDING_SIZE_DEFAULT,
                ),
                SizedBox(
                  height: Dimensions.PADDING_SIZE_LARGE * 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Theme.of(context).primaryColor),
                    onPressed: () {
                      String enteredText = queryController.text;
                      if (enteredText.isEmpty) {
                        setState(() {
                          errorText = 'Please enter your query';
                        });
                      } else {
                        // addQuery(questionId, enteredText,context);
                      }
                    },
                    child: Text(
                      'Submit',
                      style: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: Dimensions.PADDING_SIZE_DEFAULT,
            ),
          ],
        );
      },
    );
  }

  // Future<void> addQuery(String questionId, String queryTxt, BuildContext context) async {
  //   final store = Provider.of<ReportsCategoryStore>(context, listen: false);
  //   await store.onCreateQuerySolutionReport(context, questionId, queryTxt);
  //   BottomToast.showBottomToastOverlay(
  //     context: context,
  //     errorMessage: "Query Successfully Submitted",
  //     backgroundColor: Theme.of(context).primaryColor,
  //   );
  //   Navigator.of(context).pop();
  // }
}

Widget _buildDetail(String label, String value, String path) {
  return Container(
    decoration: BoxDecoration(border: Border.all(color: ThemeManager.grey2)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            path,
            height: 32,
            width: 32,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: interMedium.copyWith(
                  fontSize: 16,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: ThemeManager.black,
                ),
              ),
              Text(
                label,
                style: interRegular.copyWith(
                  fontSize: 8,
                  height: 1,
                  color: ThemeManager.grey4,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
