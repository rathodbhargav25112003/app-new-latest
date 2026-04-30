// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names, dead_code, prefer_final_fields, use_build_context_synchronously, avoid_print, unused_element, unnecessary_string_interpolations

import 'dart:async';
import 'dart:io';
import 'package:shusruta_lms/services/daily_review_recorder.dart';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_svg/svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/comman_widget.dart';
import 'package:shusruta_lms/modules/mcq_review_v3/mcq_review_service.dart';
import 'package:shusruta_lms/modules/mcq_review_v3/reading_prefs.dart';
import 'package:shusruta_lms/modules/mcq_review_v3/widgets/bookmark_categories_sheet.dart';
import 'package:shusruta_lms/modules/mcq_review_v3/widgets/highlighter_toolbar.dart';
// MCQ Review v3 — drop-in action bar (Cortex multi-turn, mistake debrief,
// related MCQs, mnemonic, diagram, flashcards, audio, notes, highlight,
// review queue, discussion, report) + cohort time + sticky-notes upgrade
import 'package:shusruta_lms/modules/mcq_review_v3/widgets/mcq_solution_action_bar.dart';
// Existing-feature upgrades — quick font, bookmark categories, sticky-note
// multi-panel, highlighter toolbar, swipe-nav + auto-advance, smart summary
import 'package:shusruta_lms/modules/mcq_review_v3/widgets/quick_font_controls.dart';
import 'package:shusruta_lms/modules/mcq_review_v3/widgets/smart_summary_dialog.dart';
import 'package:shusruta_lms/modules/mcq_review_v3/widgets/sticky_notes_panel.dart';
import 'package:shusruta_lms/modules/mcq_review_v3/widgets/swipe_navigation_wrapper.dart';
import 'package:shusruta_lms/modules/mcq_review_v3/widgets/time_vs_avg.dart';
import 'package:shusruta_lms/modules/new_exam_component/widget/custome_exam_button.dart';
import 'package:shusruta_lms/modules/reports/explanation_common_widget.dart';
import 'package:shusruta_lms/modules/test/question_pallet.dart';
import 'package:shusruta_lms/modules/test/show_test_screen.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/widgets/bottom_raise_query_window.dart'
    show CustomBottomRaiseQueryWindow;
import 'package:shusruta_lms/modules/widgets/bottom_stick_notes_window.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:typewritertext/typewritertext.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/get_explanation_model.dart';
import '../../models/get_notes_solution_model.dart';
import '../../models/test_exampaper_list_model.dart';
import '../mcq_review_v3/widgets/confidence_rater.dart';
import '../reports/store/report_by_category_store.dart';
import '../widgets/bottom_raise_query.dart';
import '../widgets/bottom_stick_notes.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';

class PracticeTestSolutionExamScreen extends StatefulWidget {
  final TestExamPaperListModel? testExamPaper;
  final String? userExamId;
  final int? queNo;
  final bool? isPracticeExam;
  final ValueNotifier<Duration>? remainingTime;
  final String? id;
  final String? type;
  final bool? isCorrect;
  final bool? fromPallete;
  const PracticeTestSolutionExamScreen(
      {super.key,
      this.fromPallete,
      this.testExamPaper,
      this.userExamId,
      this.isPracticeExam,
      this.queNo,
      this.remainingTime,
      this.id,
      this.type,
      this.isCorrect});

  @override
  State<PracticeTestSolutionExamScreen> createState() => _PracticeTestSolutionExamScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => PracticeTestSolutionExamScreen(
        testExamPaper: arguments['testData'],
        userExamId: arguments['userexamId'],
        queNo: arguments['queNo'],
        isPracticeExam: arguments['isPracticeExam'],
        remainingTime: arguments['remainingTime'],
        id: arguments['id'],
        type: arguments['type'],
        fromPallete: arguments['fromPallete'],
        isCorrect: arguments['isCorrect'],
      ),
    );
  }
}

class _PracticeTestSolutionExamScreenState extends State<PracticeTestSolutionExamScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final QuillController _quillController = QuillController.basic();
  // Timer? timer;
  // late ValueNotifier<Duration> remainingTimeNotifier;
  // Duration? remainingTime;
  int _selectedIndex = -1;
  int _currentQuestionIndex = 0;
  bool isLastQues = false, firstQue = true;
  bool isAttempted = false;
  bool isMarkedForReview = false;
  bool isGuess = false;
  bool isAttemptedAndMarkedForReview = false;
  bool isSkipped = false;
  Uint8List? answerImgBytes;
  Uint8List? quesImgBytes;
  Uint8List? explanationImgBytes;
  List<TestData>? filterTest;
  bool isTapped = false;
  Map<int, bool> showAnswer = {}; // Changed to Map to track visibility per question
  // Duration? duration;
  // String? usedExamTime;
  Widget? explanationWidget;
  Widget? questionWidget;
  final _controller = SuperTooltipController();
  bool isbutton = false, isprocess = false;

  DateTime? _questionStartedAt;

  // ── MCQ Review v3 — local state for upgraded features ───────────────
  bool _v3HighlighterActive = false;
  String? _v3HighlightColor; // 'yellow'|'blue'|'pink'|'green' — null = use default
  bool _v3EraserMode = false;
  // Per-question multi-notes (local-only). Wire to your existing notes
  // API as a follow-up if you want server sync.
  final Map<String, List<StickyNote>> _v3MultiNotes = {};

  void _openMultiNotesPanel(String questionId) {
    final notes = List<StickyNote>.from(_v3MultiNotes[questionId] ?? []);
    StickyNotesPanel.show(
      context,
      notes: notes,
      onSave: (n) async {
        setState(() {
          final list = List<StickyNote>.from(_v3MultiNotes[questionId] ?? []);
          final i = list.indexWhere((x) => x.id == n.id);
          if (i == -1)
            list.insert(0, n);
          else
            list[i] = n;
          _v3MultiNotes[questionId] = list;
        });
      },
      onDelete: (id) async {
        setState(() {
          final list = List<StickyNote>.from(_v3MultiNotes[questionId] ?? []);
          list.removeWhere((x) => x.id == id);
          _v3MultiNotes[questionId] = list;
        });
      },
    );
  }

  Future<void> _onBookmarkTapV3(String examId, String? questionId) async {
    // Run the existing bookmark API toggle first
    await _putBookMarkApiCall(examId, questionId);
    // Then offer category + note picker (only when newly bookmarked,
    // not on un-bookmark)
    final isNowBookmarked = widget.testExamPaper?.test?[_currentQuestionIndex].bookmarks ?? false;
    if (isNowBookmarked && questionId != null && questionId.isNotEmpty && mounted) {
      await BookmarkCategoriesSheet.show(context, questionId: questionId);
    } else if (questionId != null) {
      await BookmarkMeta.remove(questionId);
    }
  }

  double _textSize = Dimensions.fontSizeDefault;
  double showfontSize = 100;

  @override
  void initState() {
    super.initState();
    // updateTimer();
    getCountReportPractice(context);
    isTapped = false;
    filterTest = widget.testExamPaper?.test;
    _questionStartedAt = DateTime.now();

    // V3 — load reading preferences (focus mode, speed reading, auto-advance,
    // dyslexia font) and rebuild whenever they change so the toggles in the
    // dedicated Reading Settings screen take effect live, even mid-attempt.
    ReadingPrefs.I.load();
    ReadingPrefs.I.addListener(_onPrefsChanged);

    // MCQ Review v3 — bulk-enroll wrong + low-confidence answers from this
    // attempt into the spaced-repetition queue. Idempotent — skips Qs
    // already enrolled. Fire-and-forget; failures don't block the UI.
    if ((widget.userExamId ?? '').isNotEmpty) {
      McqReviewService().enrollFromAttempt(widget.userExamId!).catchError((_) => 0);
    }
    if (widget.isCorrect != null) {
      filterTest = widget.testExamPaper?.test?.where((report) {
        if (widget.isCorrect == true) {
          return report.isCorrect == true;
        } else if (widget.isCorrect == false) {
          return report.isCorrect == false;
        }
        return false;
      }).toList();
    } else {
      filterTest = widget.testExamPaper?.test;
    }
    int matchingIndex = filterTest?.indexWhere((e) => e.questionNumber == widget.queNo) ?? -1;
    if (matchingIndex != -1) {
      String? matchingQueId = filterTest?[matchingIndex].sId;
      _getSelectedAnswer(matchingQueId!);
      _currentQuestionIndex = matchingIndex;
      setState(() {
        firstQue = false;
      });
    }

    _getNotesData(filterTest?[_currentQuestionIndex].sId ?? "");
  }

  Future<void> _getExplanationData(String prompt) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onGetExplanationCall(prompt);
    setState(() {
      isprocess = false;
      isbutton = true;
    });
  }

  // void updateTimer() {
  //   if(widget.testExamPaper?.timeDuration != null && widget.fromPallete!=true) {
  //     List<String>? timeParts = widget.testExamPaper?.timeDuration?.split(":");
  //     duration = Duration(
  //       hours: int.parse(timeParts![0]),
  //       minutes: int.parse(timeParts[1]),
  //       seconds: int.parse(timeParts[2]),
  //     );
  //     remainingTime = duration;
  //     remainingTimeNotifier = ValueNotifier<Duration>(remainingTime!);
  //   }
  //   else{
  //     List<String>? timeParts = widget.testExamPaper?.timeDuration?.split(":");
  //     duration = Duration(
  //       hours: int.parse(timeParts![0]),
  //       minutes: int.parse(timeParts[1]),
  //       seconds: int.parse(timeParts[2]),
  //     );
  //     remainingTime = widget.remainingTime?.value;
  //     remainingTimeNotifier = ValueNotifier<Duration>(remainingTime!);
  //   }
  //
  //   timer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     if (remainingTimeNotifier.value.inSeconds > 0) {
  //       remainingTimeNotifier.value = remainingTimeNotifier.value - const Duration(seconds: 1);
  //     } else {
  //       timer.cancel();
  //       remainingTimeNotifier.dispose();
  //       BottomToast.showBottomToastOverlay(
  //         context: context,
  //         errorMessage: "Your Exam Time is Up!",
  //         backgroundColor: Theme.of(context).primaryColor,
  //       );
  //       Navigator.of(context).pushNamed(Routes.testCategory);
  //     }
  //   });
  // }

  @override
  void dispose() {
    // timer?.cancel();
    // remainingTimeNotifier.dispose();
    ReadingPrefs.I.removeListener(_onPrefsChanged);
    super.dispose();
  }

  /// V3 — fires when ReadingPrefs change so the screen rebuilds with the new
  /// font scale / focus-mode visibility / dyslexia font etc.
  void _onPrefsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _putBookMarkApiCall(String examId, String? questionId) async {
    setState(() {
      widget.testExamPaper?.test?[_currentQuestionIndex].bookmarks =
          !(widget.testExamPaper?.test?[_currentQuestionIndex].bookmarks ?? false);
    });
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    final isBookmarkedNow =
        widget.testExamPaper?.test?[_currentQuestionIndex].bookmarks ?? false;
    store.onBookMarkQuestion(context, isBookmarkedNow, examId, questionId ?? "", "");
    final q = widget.testExamPaper?.test?[_currentQuestionIndex];
    if (q != null) {
      // ignore: discarded_futures
      DailyReviewRecorder.bookmarkToggle(q, examId, isBookmarkedNow);
    }
    BottomToast.showBottomToastOverlay(
      context: context,
      errorMessage: isBookmarkedNow
          ? "Question Bookmarked Successfully!"
          : "Bookmark Removed!",
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  // Future<void> _postSelectedAnswerApiCall(String? userExamId, String? selectedOption, String? questionId,
  //     bool isAttempted, bool isAttemptedAndMarkedForReview, bool isSkipped, bool isMarkedForReview,String guess, String time)async{
  //   final store = Provider.of<TestCategoryStore>(context, listen: false);
  //   await store.userAnswerTest(context, userExamId??"", questionId??"", selectedOption??"",isAttempted,isAttemptedAndMarkedForReview,isSkipped,isMarkedForReview,guess,time);
  // }
  //
  Future<void> _getSelectedAnswer(String queId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.questionAnswerById(widget.userExamId ?? "", queId);
    setState(() {
      String? nextOption = store.userAnswerExam.value?.selectedOption;
      _selectedIndex = filterTest?[_currentQuestionIndex]
              .optionsData
              ?.indexWhere((option) => option.value == nextOption) ??
          -1;
      if (_selectedIndex != -1) {
        isTapped = true;
      }
    });
  }

  Future<void> _getCount(String? userExamId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.getQuestionPalleteCount(userExamId ?? "").then((_) {
      openBottomSheet(store);
    });
  }

  void openBottomSheet(TestCategoryStore store) {
    getCountReportPractice(context);
    // V3 — replace the legacy "Practice Test Summary" tally dialog with the
    // SmartSummaryDialog (grade headline, per-topic strength bars, Brier
    // calibration recap, and Review-wrong / Study-plan / Trends action chips).
    final correct = store.getReportPracticeCountData.value?.correctAnswers ?? 0;
    final incorrect = store.getReportPracticeCountData.value?.incorrectAnswers ?? 0;
    final skipped = store.getReportPracticeCountData.value?.notVisited ?? 0;
    SmartSummaryDialog.show(
      context,
      correct: correct,
      incorrect: incorrect,
      skipped: skipped,
      // We don't track total elapsed time on this screen yet — leaving null
      // hides that row in the summary cleanly.
      totalSeconds: null,
      userExamId: widget.userExamId,
      onSaveAndExit: () => Navigator.of(context).pushNamed(Routes.testCategory),
    );
    return;
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
              const SizedBox(
                height: Dimensions.PADDING_SIZE_SMALL * 1.6,
              ),
              Row(
                children: [
                  Container(
                    height: Dimensions.PADDING_SIZE_LARGE * 1.1,
                    width: Dimensions.PADDING_SIZE_LARGE * 1.1,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFFFFD53F), shape: BoxShape.circle),
                    child: Icon(
                      CupertinoIcons.exclamationmark,
                      color: ThemeManager.white,
                      size: 20,
                    ),
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
            onTap: () => Navigator.of(context).pushNamed(Routes.testCategory),
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
    isbutton = false;
    firstQue = false;
    isTapped = false;
    String? questionId = filterTest?[_currentQuestionIndex].sId;
    Delta delta = _quillController.document.toDelta();
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    store.saveChangeExaplanation(
        context, {"question_id": filterTest?[_currentQuestionIndex].sId, "annotation_data": delta.toJson()});
    filterTest?[_currentQuestionIndex].isHighlight = true;
    filterTest?[_currentQuestionIndex].annotationData = delta.toJson();
    String? selectedOption =
        _selectedIndex == -1 ? "" : filterTest?[_currentQuestionIndex].optionsData?[_selectedIndex].value;
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

    // if (duration != null && remainingTimeNotifier.value != null) {
    //   Duration timeDifference = duration! - remainingTimeNotifier.value;
    //   usedExamTime = "${timeDifference.inHours.toString().padLeft(2, '0')}:${timeDifference.inMinutes.remainder(60).toString().padLeft(2, '0')}:${timeDifference.inSeconds.remainder(60).toString().padLeft(2, '0')}";
    //   debugPrint('usedtime $usedExamTime');
    // } else {
    //   debugPrint('Duration values are null.');
    // }
    // await _postSelectedAnswerApiCall(widget.userExamId, selectedOption, questionId,isAttempted,isAttemptedAndMarkedForReview,isSkipped,isMarkedForReview,selectedOption!,"");
    isAttempted = false;
    isSkipped = false;
    isAttemptedAndMarkedForReview = false;
    isMarkedForReview = false;
    isGuess = false;

    setState(() {
      _questionStartedAt = DateTime.now();
      _selectedIndex = -1;
      if (isLastQues) {
        _getCount(widget.userExamId);
      }
      _currentQuestionIndex++;
      if (_currentQuestionIndex >= (filterTest?.length ?? 0) - 1) {
        isLastQues = true;
        _currentQuestionIndex = (filterTest?.length ?? 0) - 1;
      } else {
        isLastQues = false;
      }

      String? questionId1 = filterTest?[_currentQuestionIndex].sId;
      _getSelectedAnswer(questionId1 ?? "");

      explanationWidget = getExplanationText(context);
      questionWidget = getQuestionText(context);
      _getNotesData(filterTest?[_currentQuestionIndex].sId ?? "");
      _scrollToIndex(_currentQuestionIndex);
    });
  }

  Future<void> _showPreviousQuestion() async {
    Delta delta = _quillController.document.toDelta();
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    store.saveChangeExaplanation(
        context, {"question_id": filterTest?[_currentQuestionIndex].sId, "annotation_data": delta.toJson()});
    filterTest?[_currentQuestionIndex].isHighlight = true;
    filterTest?[_currentQuestionIndex].annotationData = delta.toJson();
    setState(() {
      _questionStartedAt = DateTime.now();
      isbutton = false;
      _selectedIndex = -1;
      isTapped = false;
      isLastQues = false;
      if (filterTest?.length == 1) {
        _currentQuestionIndex = 0;
        firstQue = true;
      } else if (_currentQuestionIndex > 0) {
        _currentQuestionIndex--;
      } else {
        firstQue = true;
      }

      String? questionId = filterTest?[_currentQuestionIndex].sId;
      _getSelectedAnswer(questionId ?? "");

      explanationWidget = getExplanationText(context);
      questionWidget = getQuestionText(context);
      _getNotesData(filterTest?[_currentQuestionIndex].sId ?? "");
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

  Widget getExplanationText(BuildContext context) {
    String explanation = filterTest?[_currentQuestionIndex].explanation ?? "";
    explanation =
        explanation.replaceAllMapped(RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    List<String> splittedText = explanation.split("splittedImage");
    List<Widget> columns = [];
    int index = 0;

    for (String text in splittedText) {
      final documentContent = preprocessDocument(text);

      _quillController.document = Document.fromJson(filterTest![_currentQuestionIndex].isHighlight ?? false
          ? filterTest![_currentQuestionIndex].annotationData!.toString() == "[{}]"
              ? parseCustomSyntax("""
$documentContent""")
              : filterTest![_currentQuestionIndex].annotationData!
          : parseCustomSyntax("""
$documentContent"""));
      List<Widget> explanationImageWidget = [];
      if (filterTest?[_currentQuestionIndex].explanationImg?.isNotEmpty ?? false) {
        for (String base64String in widget.testExamPaper!.test![_currentQuestionIndex].explanationImg!) {
          try {
            // Uint8List explanationImgBytes = base64Decode(base64String);
            explanationImageWidget.add(
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: PhotoView(
                            // imageProvider: MemoryImage(explanationImgBytes),
                            imageProvider: NetworkImage(base64String),
                            minScale: PhotoViewComputedScale.covered,
                            maxScale: PhotoViewComputedScale.covered * 2,
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Row(
                  children: [
                    InteractiveViewer(
                      // minScale: 1.0,
                      // maxScale: 3.0,
                      scaleEnabled: false,
                      child: Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Stack(
                            children: [
                              // Image.memory(explanationImgBytes),
                              Image.network(base64String),
                              Container(color: Colors.transparent),
                            ],
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
            // Markdown(
            //   data: text.replaceAll("--", "•"),

            //   shrinkWrap: true,
            //   physics: const NeverScrollableScrollPhysics(),

            //   padding: const EdgeInsets.all(0),
            //   selectable: true, // Allows text selection
            //   styleSheet: MarkdownStyleSheet(
            //     p: const TextStyle(fontSize: 16),
            //   ),
            // ),
            CommonExplanationWidget(
              textPercentage: showfontSize.toInt(),
              controller: _quillController,
            ),

            const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: explanationImageWidget,
            ),
            const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
            explanationImageWidget.isNotEmpty
                ? Text(
                    "Tap the image to zoom In/Out",
                    style: interBlack.copyWith(
                      fontSize: Dimensions.fontSizeSmall * (showfontSize / 100),
                      fontWeight: FontWeight.w400,
                      color: ThemeManager.black,
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      );

      index++;

      if (index >= (filterTest?[_currentQuestionIndex].explanationImg?.length ?? 0) - 1) {
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns,
    );
  }

  Widget getQuestionText(BuildContext context) {
    if (filterTest == null ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= (filterTest?.length ?? 0)) {
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

    String questionTxt = filterTest?[_currentQuestionIndex].questionText ?? "";
    questionTxt =
        questionTxt.replaceAllMapped(RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    List<String> splittedText = questionTxt.split("splittedImage");
    List<Widget> columns = [];
    int index = 0;
    for (String text in splittedText) {
      List<Widget> questionImageWidget = [];
      if (filterTest?[_currentQuestionIndex].questionImg?.isNotEmpty ?? false) {
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
            const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
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
      if (index >= (filterTest?[_currentQuestionIndex].questionImg?.length ?? 0) - 1) {
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
    double totalWidth = (filterTest?.length ?? 0) *
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

  Future<void> getCountReportPractice(context) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onGetReportPracticeCountApiCall(widget.userExamId ?? "", widget.type ?? "", false);
  }

  void _questionChange(int index) {
    setState(() {
      _currentQuestionIndex = index;
      _questionStartedAt = DateTime.now();
      // Don't reset - each question maintains its own showAnswer state
    });
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

  @override
  Widget build(BuildContext context) {
    debugPrint("Get in screen now ");
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    final store2 = Provider.of<TestCategoryStore>(context, listen: false);
    explanationWidget = getExplanationText(context);
    questionWidget = getQuestionText(context);
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppTokens.scaffold(context),
          // appBar: AppBar(
          //   elevation: 0,
          //   automaticallyImplyLeading: false,
          //   backgroundColor: ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.white : Theme.of(context).primaryColor,
          //   title: Padding(
          //     padding: const EdgeInsets.only(left: Dimensions.PADDING_SIZE_DEFAULT),
          //     child: Row(
          //       children: [
          //         Text(
          //           widget.testExamPaper?.examName??"Test",
          //           style: interRegular.copyWith(
          //             fontSize: Dimensions.fontSizeLarge,
          //             fontWeight: FontWeight.w500,
          //             color: Colors.white,
          //           ),
          //         ),
          //         const Spacer(),
          //               IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,onPressed: (){
          //           showDialog(
          //             context: context,
          //             builder: (context) => const CustomTestCancelDialogBox(null,null,true),
          //           );
          //         }, icon: const Icon(Icons.close,color: Colors.white)),
          //         InkWell(
          //           onTap: (){
          //             _scaffoldKey.currentState?.openDrawer();
          //           },
          //           child: Image.asset("assets/image/question_palette.png",
          //             height: 30,width: 30,),
          //         )
          //       ],
          //     ),
          //   ),
          // ),
          appBar: ReadingPrefs.I.focusMode
              ? null
              : AppBar(
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  backgroundColor: AppTokens.surface(context),
                  surfaceTintColor: AppTokens.surface(context),
                  title: Row(
                    children: [
                      InkWell(
                          onTap: () {
                            Navigator.of(context).pushNamed(Routes.testCategory);
                          },
                          child: SvgPicture.asset(
                            "assets/image/arrow_back.svg",
                            color: ThemeManager.currentTheme == AppTheme.Dark ? AppColors.white : null,
                          )),
                      const SizedBox(
                        width: Dimensions.RADIUS_EXTRA_LARGE * 1.1,
                      ),
                      // InkWell(
                      //   onTap: () {
                      //     _scaffoldKey.currentState?.openDrawer();
                      //   },
                      //   child: Image.asset(
                      //     "assets/image/questionplatte.png",
                      //     height: 30,
                      //     width: 30,
                      //   ),
                      // ),
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
                      const Spacer(),

                      InkWell(
                        onTap: () {
                          // showDialog(
                          //   context: context,
                          //   builder: (context) => const CustomTestCancelDialogBox(null,null,true),
                          // );
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
                              content: Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                constraints: BoxConstraints(maxWidth: 500),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize
                                      .min, // Prevents the column from taking up all available space
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
                                            "${store2.getReportPracticeCountData.value?.correctAnswers}",
                                            "assets/image/correct.svg",
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: _buildDetail(
                                            "Incorrect",
                                            "${store2.getReportPracticeCountData.value?.incorrectAnswers}",
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
                                            "${store2.getReportPracticeCountData.value?.correctAnswers}",
                                            "assets/image/total_q.svg",
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: _buildDetail(
                                            "Unanswered",
                                            "${store2.getReportPracticeCountData.value?.incorrectAnswers}",
                                            "assets/image/skipped1.svg",
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: Dimensions.PADDING_SIZE_SMALL * 1.6),
                                    _buildDetail(
                                      "Bookmarked",
                                      "${store2.getReportPracticeCountData.value?.incorrectAnswers}",
                                      "assets/image/bookmark2.svg",
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                InkWell(
                                  onTap: () => Navigator.of(context).pushNamed(Routes.testCategory),
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
                              color: AppTokens.accentSoft(context),
                              border: Border.all(
                                color: AppTokens.accent(context).withOpacity(0.35),
                              ),
                              borderRadius: BorderRadius.circular(60)),
                          child: Text(
                            "Save & Exit",
                            style: interRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              fontWeight: FontWeight.w600,
                              color: AppTokens.accent(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          body: Column(
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
                    children: List.generate(filterTest?.length ?? 0, (index) {
                      TestData? solutionReport = filterTest?[index];
                      // String showTxt = ((solutionReport?.correctOption??"") == (solutionReport?.options?[index].value??"")) ?
                      // "Correct Answer" : ((solutionReport?.selectedOption??"") == (solutionReport?.options?[index].value??""))
                      //     ? "Incorrect Answer" : ((solutionReport?.guess??"") == (solutionReport?.options?[index].value??"")) ? "Guess" : "";

                      // Color showColor = ((solutionReport?.correctOption??"") == (solutionReport?.options?[index].value??"")) ?
                      // ThemeManager.greenBorder : ((solutionReport?.selectedOption??"") == (solutionReport?.options?[index].value??""))
                      //     ? ThemeManager.redText : ThemeManager.borderBlue;
                      // ? ThemeManager.redText : ((solutionReport?.guess??"") == (solutionReport?.options?[index].value??"")) ? (ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.black : Colors.brown) : ThemeManager.borderBlue;

                      // debugPrint("sssssssssss:${solutionReport?.correctOption}");
                      // debugPrint("aaaaaaaaaaaa:${solutionReport?.selectedOption??""}ssssss:${solutionReport?.guess}");
                      // Color showColor = ((solutionReport?.correctOption??"") == (solutionReport?.selectedOption??"")) ?
                      // ThemeManager.greenBorder : ((solutionReport?.correctOption??"") == (solutionReport?.selectedOption??""))
                      //     ? ThemeManager.redText : ThemeManager.borderBlue;

                      return GestureDetector(
                        onTap: () {
                          _questionChange(index);
                        },
                        child: Container(
                          height: Dimensions.PADDING_SIZE_SMALL * 2.675,
                          width: Dimensions.PADDING_SIZE_SMALL * 2.675,
                          margin: const EdgeInsets.only(right: Dimensions.PADDING_SIZE_SMALL * 1.7),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: _currentQuestionIndex == index
                                  ? (solutionReport?.correctOption ?? "") ==
                                          (solutionReport?.selectedOption ?? "")
                                      ? ThemeManager.greenBorder
                                      : ThemeManager.redText
                                  : ThemeManager.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (solutionReport?.correctOption ?? "") ==
                                        (solutionReport?.selectedOption ?? "")
                                    ? ThemeManager.greenBorder
                                    : ThemeManager.redText,
                              )),
                          child: Text(
                            "${index + 1}",
                            style: interRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              fontWeight: FontWeight.w500,
                              color: (solutionReport?.correctOption ?? "") ==
                                      (solutionReport?.selectedOption ?? "")
                                  ? _currentQuestionIndex == index
                                      ? ThemeManager.white
                                      : ThemeManager.greenBorder
                                  : _currentQuestionIndex == index
                                      ? ThemeManager.white
                                      : ThemeManager.redText,
                            ),
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
                  color: AppTokens.surface2(context),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Correct
                      _buildScoreItem(
                        path: "assets/image/correct_i.svg",
                        color: Colors.green,
                        label: '${calculateExamMetrics(filterTest ?? [])['attempted_correct']}',
                        label2: "",
                      ),
                      // Incorrect
                      _buildScoreItem(
                          path: 'assets/image/wrong_i.svg',
                          color: Colors.red,
                          label:
                              '${calculateExamMetrics(filterTest == null ? [] : filterTest!)['attempted_incorrect']}',
                          label2: ""),
                      // Attempted
                      _buildScoreItem(
                          path: null, // No icon for Attempted
                          color: Colors.purple,
                          label:
                              '${calculateExamMetrics(filterTest == null ? [] : filterTest!)['total_attempted']} ',
                          isTextOnly: true,
                          label2: "Attempted"),
                      // Unattempted
                      _buildScoreItem(
                          path: null, // No icon for Unattempted
                          color: Colors.blue,
                          label:
                              '${calculateExamMetrics(filterTest == null ? [] : filterTest!)['total_unattempted']} ',
                          isTextOnly: true,
                          label2: "Unattempted"),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(
                  top: Dimensions.PADDING_SIZE_LARGE * 1.4,
                  left: Dimensions.PADDING_SIZE_DEFAULT,
                  right: Dimensions.PADDING_SIZE_DEFAULT,
                  // bottom: Dimensions.PADDING_SIZE_LARGE*1.4,
                ),
                child: Row(
                  children: [
                    // Container(
                    //   height: Dimensions.PADDING_SIZE_DEFAULT * 2,
                    //   width: Dimensions.PADDING_SIZE_DEFAULT * 5,
                    //   decoration: BoxDecoration(
                    //       color: ThemeManager.borderBlue,
                    //       borderRadius: BorderRadius.circular(Dimensions.RADIUS_LARGE)
                    //   ),
                    //   child: Center(
                    //     child: Text("Q-${(filterTest?[_currentQuestionIndex].questionNumber??"").toString().padLeft(2, '0')}",
                    //       style: interRegular.copyWith(
                    //         fontSize: Dimensions.fontSizeDefault,
                    //         fontWeight: FontWeight.w400,
                    //         color: ThemeManager.black,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
                    Text(
                      "${_currentQuestionIndex + 1}.",
                      style: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraExtraLarge,
                        fontWeight: FontWeight.w500,
                        color: ThemeManager.black,
                      ),
                    ),
                    // const Spacer(),
                    const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT),
                    InkWell(
                        // V3 wire — runs the existing API toggle and, when the
                        // question is *newly* bookmarked, opens the categories +
                        // note picker sheet so the admin can tag this Q on save.
                        onTap: () => _onBookmarkTapV3(widget.testExamPaper?.examId ?? "",
                            widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? ""),
                        child: SvgPicture.asset('assets/image/bookmark1.svg')),
                    const SizedBox(
                      width: Dimensions.PADDING_SIZE_EXTRA_SMALL * 1.6,
                    ),
                    // View Ans button
                    // InkWell(
                    //   onTap: () {
                    //     setState(() {
                    //       showAnswer[_currentQuestionIndex] = !(showAnswer[_currentQuestionIndex] ?? false);
                    //     });
                    //   },
                    //   child: Container(
                    //     padding: const EdgeInsets.symmetric(
                    //       horizontal: Dimensions.PADDING_SIZE_DEFAULT,
                    //       vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                    //     ),
                    //     decoration: BoxDecoration(
                    //       color: (showAnswer[_currentQuestionIndex] ?? false)
                    //           ? ThemeManager.primaryColor
                    //           : Colors.transparent,
                    //       border: Border.all(
                    //         color: (showAnswer[_currentQuestionIndex] ?? false)
                    //             ? ThemeManager.primaryColor
                    //             : ThemeManager.grey2,
                    //       ),
                    //       borderRadius: BorderRadius.circular(4),
                    //     ),
                    //     child: Text(
                    //       'View Ans',
                    //       style: interRegular.copyWith(
                    //         fontSize: Dimensions.fontSizeSmall,
                    //         color: (showAnswer[_currentQuestionIndex] ?? false)
                    //             ? ThemeManager.white
                    //             : ThemeManager.black,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // ConfidenceRater(),

                    // View Ans button (V3 Confidence Rater)
                    Expanded(
                      child: ConfidenceRater(
                        userAnswerId: widget.userExamId ?? '',
                        questionStartedAt: _questionStartedAt ?? DateTime.now(),
                        initial: 50,
                        onReveal: () => setState(() => showAnswer[_currentQuestionIndex] = true),
                      ),
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
                                        questionId:
                                            widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "",
                                        questionText:
                                            widget.testExamPaper?.test?[_currentQuestionIndex].questionText ??
                                                '',
                                        allOptions:
                                            "a) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[0].answerTitle}\nb) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[1].answerTitle}\nc) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[2].answerTitle}\nd) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[3].answerTitle}"),
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
                                      questionText:
                                          widget.testExamPaper?.test?[_currentQuestionIndex].questionText ??
                                              '',
                                      allOptions:
                                          "a) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[0].answerTitle}\nb) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[1].answerTitle}\nc) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[2].answerTitle}\nd) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[3].answerTitle}");
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
                                        questionText:
                                            widget.testExamPaper?.test?[_currentQuestionIndex].questionText ??
                                                '',
                                        allOptions:
                                            "a) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[0].answerTitle}\nb) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[1].answerTitle}\nc) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[2].answerTitle}\nd) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[3].answerTitle}"),
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
                                      questionText:
                                          widget.testExamPaper?.test?[_currentQuestionIndex].questionText ??
                                              '',
                                      allOptions:
                                          "a) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[0].answerTitle}\nb) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[1].answerTitle}\nc) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[2].answerTitle}\nd) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[3].answerTitle}");
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
                            solutionReport?.optionsData?.indexWhere((e) => e.value == currentOption) ?? -1;
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

                    //       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,onPressed: (){
                    //   _putBookMarkApiCall(widget.testExamPaper?.examId??"",filterTest?[_currentQuestionIndex].sId??"");
                    // }, icon: Icon(filterTest?[_currentQuestionIndex].bookmarks ??false ? Icons.bookmark : Icons.bookmark_add_outlined,color: Theme.of(context).hintColor,)),
                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     TextButton(onPressed: (){
                    //       _showDialog(context,filterTest?[_currentQuestionIndex].sId??"");
                    //     },
                    //     child: Column(
                    //       children: [
                    //         Icon(Icons.question_mark, color: Theme.of(context).hintColor),
                    //         Text('Raise Query',
                    //           style: interRegular.copyWith(
                    //             fontSize: Dimensions.fontSizeDefault,
                    //             fontWeight: FontWeight.w400,
                    //             color: Theme.of(context).hintColor,
                    //           ),),
                    //       ],
                    //     )),
                    //   ],
                    // ),
                    // ValueListenableBuilder<Duration>(
                    //   valueListenable: remainingTimeNotifier,
                    //   builder: (context, remainingTime, child) {
                    //     return Text(
                    //       "${remainingTime!.inHours.toString().padLeft(2, '0')}:${remainingTime!.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTime!.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                    //       style: interRegular.copyWith(
                    //         fontSize: Dimensions.fontSizeDefault,
                    //         fontWeight: FontWeight.w600,
                    //         color: ThemeManager.greenSuccess,
                    //       ),
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
                // V3 — wrap the scrolling per-question body with the swipe
                // navigator so left/right swipes move between Qs and (when
                // the answer is revealed and ReadingPrefs.autoAdvance is on)
                // an auto-advance progress bar at the bottom moves on after
                // the configured countdown.
                child: SwipeNavigationWrapper(
                  onPrevious: () => _showPreviousQuestion(),
                  onNext: () => _showNextQuestion(),
                  answerRevealed: showAnswer[_currentQuestionIndex] ?? false,
                  canGoPrevious: _currentQuestionIndex > 0,
                  canGoNext: _currentQuestionIndex < (filterTest?.length ?? 1) - 1,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: Dimensions.PADDING_SIZE_DEFAULT,
                      right: Dimensions.PADDING_SIZE_DEFAULT,
                      // bottom: Dimensions.PADDING_SIZE_LARGE*1.4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text(
                        //   filterTest?[_currentQuestionIndex].questionText??"",
                        //   style: interRegular.copyWith(
                        //     fontSize: Dimensions.fontSizeDefault,
                        //     fontWeight: FontWeight.w400,
                        //     color: ThemeManager.black,
                        //   ),),
                        // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
                        //
                        // filterTest?[_currentQuestionIndex].questionImg?.isNotEmpty ?? false?
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

                        // questionWidget??const SizedBox(),
                        questionWidget ?? const SizedBox(),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   crossAxisAlignment: CrossAxisAlignment.start,
                        //   children: [
                        //     Expanded(child: questionWidget??const SizedBox()),
                        //           IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,onPressed: (){
                        //       _putBookMarkApiCall(widget.testExamPaper?.examId??"",filterTest?[_currentQuestionIndex].sId??"");
                        //     }, icon: Icon(filterTest?[_currentQuestionIndex].bookmarks??false ? Icons.bookmark : Icons.bookmark_border,color: Theme.of(context).hintColor,)),
                        //   ],
                        // ),
                        const SizedBox(
                          height: Dimensions.PADDING_SIZE_DEFAULT,
                        ),

                        ListView.builder(
                          shrinkWrap: true,
                          // padding: EdgeInsets.zero,
                          physics: const BouncingScrollPhysics(),
                          itemCount: filterTest?[_currentQuestionIndex].optionsData?.length,
                          itemBuilder: (BuildContext context, int index) {
                            TestData? testExamPaper = filterTest?[_currentQuestionIndex];
                            String base64String = testExamPaper?.optionsData?[index].answerImg ?? "";

                            String? correctPercentage = testExamPaper?.correctPercentage;

                            try {
                              // answerImgBytes = base64Decode(base64String);
                            } catch (e) {
                              debugPrint("Error decoding base64 string: $e");
                            }

                            bool isSelected = index == _selectedIndex;
                            String showTxt = "";
                            Color showColor = ThemeManager.borderBlue;
                            Color showColor2 = ThemeManager.black;
                            Color showColorBorder = ThemeManager.grey1;

                            if (_selectedIndex >= 0 &&
                                _selectedIndex < (testExamPaper?.optionsData?.length ?? 0)) {
                              showTxt = ((testExamPaper?.correctOption ?? "") ==
                                      (testExamPaper?.optionsData?[index].value ?? ""))
                                  ? "Correct Answer"
                                  : ((testExamPaper?.optionsData?[_selectedIndex].value ?? "") ==
                                          (testExamPaper?.optionsData?[index].value ?? ""))
                                      ? "Incorrect Answer"
                                      : "";

                              showColor = ((testExamPaper?.correctOption ?? "") ==
                                      (testExamPaper?.optionsData?[index].value ?? ""))
                                  ? ThemeManager.greenSuccess
                                  : ((testExamPaper?.optionsData?[_selectedIndex].value ?? "") ==
                                          (testExamPaper?.optionsData?[index].value ?? ""))
                                      ? ThemeManager.redAlert
                                      : ThemeManager.white;

                              showColor2 = ((testExamPaper?.correctOption ?? "") ==
                                      (testExamPaper?.optionsData?[index].value ?? ""))
                                  ? ThemeManager.greenSuccess
                                  : ((testExamPaper?.optionsData?[_selectedIndex].value ?? "") ==
                                          (testExamPaper?.optionsData?[index].value ?? ""))
                                      ? ThemeManager.redAlert
                                      : ThemeManager.black;

                              showColorBorder = ((testExamPaper?.correctOption ?? "") ==
                                      (testExamPaper?.optionsData?[index].value ?? ""))
                                  ? ThemeManager.correctChart
                                  : ((testExamPaper?.optionsData?[_selectedIndex].value ?? "") ==
                                          (testExamPaper?.optionsData?[index].value ?? ""))
                                      ? ThemeManager.evolveRed
                                      : ThemeManager.grey1;
                            }

                            // debugPrint("selectedndex $_selectedIndex");
                            // return Padding(
                            //   padding: const EdgeInsets.only(top: Dimensions.PADDING_SIZE_DEFAULT),
                            //   child: InkWell(
                            //     onTap: (){
                            //       setState(() {
                            //         if(widget.isPracticeExam==true) {
                            //           if (!isTapped) {
                            //             isTapped = true;
                            //             _selectedIndex = index;
                            //           }
                            //         }
                            //         else {
                            //           if (isSelected) {
                            //             _selectedIndex = -1;
                            //           } else {
                            //             _selectedIndex = index;
                            //           }
                            //         }
                            //       });
                            //     },
                            //     child: Column(
                            //       crossAxisAlignment: CrossAxisAlignment.end,
                            //       children: [
                            //         Container(
                            //           decoration: BoxDecoration(
                            //               border: Border.all(color: isTapped ? showColor : ThemeManager.borderBlue),
                            //               borderRadius: BorderRadius.circular(Dimensions.RADIUS_DEFAULT)
                            //           ),
                            //           child: Padding(
                            //             padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                            //             child: Row(
                            //               crossAxisAlignment: CrossAxisAlignment.start,
                            //               children: [
                            //                 Container(
                            //                   height: Dimensions.PADDING_SIZE_DEFAULT * 2,
                            //                   width: Dimensions.PADDING_SIZE_DEFAULT * 2,
                            //                   decoration: BoxDecoration(
                            //                       color: ThemeManager.borderBlue,
                            //                       borderRadius: BorderRadius.circular(Dimensions.RADIUS_LARGE)
                            //                   ),
                            //                   child: Center(
                            //                     child: Text(testExamPaper?.optionsData?[index].value??"",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeDefault,
                            //                         fontWeight: FontWeight.w400,
                            //                         color: ThemeManager.black,
                            //                       ),
                            //                     ),
                            //                   ),
                            //                 ),
                            //                 const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT,),
                            //                 Column(
                            //                   children: [
                            //                     SizedBox(
                            //                       width: MediaQuery.of(context).size.width * 0.6,
                            //                       child: Html(
                            //                         data: '''
                            //                         <div style="color: ${ThemeManager.currentTheme == AppTheme.Dark ? 'white' : 'black'};">
                            //                         ${testExamPaper?.optionsData?[index].answerTitle ?? ""}
                            //                         </div>
                            //                         ''',
                            //                         // data: testExamPaper?.optionsData?[index].answerTitle??"",
                            //                         // style: TextStyle(
                            //                         //   fontSize: Dimensions.fontSizeDefault,
                            //                         //   fontWeight: FontWeight.w400,
                            //                         //   color: ThemeManager.black,
                            //                         // ),
                            //                       ),
                            //                     ),
                            //                     testExamPaper?.optionsData?[index].answerImg!=""?
                            //                     InteractiveViewer(
                            //                       minScale: 1.0,
                            //                       maxScale: 3.0,
                            //                       child: Center(
                            //                         child: SizedBox(
                            //                           width: MediaQuery.of(context).size.width * 0.6,
                            //                           height: 250,
                            //                           child: Stack(
                            //                             children: [
                            //                               if (answerImgBytes != null)
                            //                                 Image.memory(answerImgBytes!),
                            //                               Container(color: Colors.transparent),
                            //                             ],
                            //                           ),
                            //                         ),
                            //                       ),
                            //                     ):const SizedBox(),
                            //                   ],
                            //                 )
                            //               ],
                            //             ),
                            //           ),
                            //         ),
                            //         const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL,),
                            //         ((testExamPaper?.correctOption??"") == (testExamPaper?.optionsData?[index].value??"")) ||
                            //             (_selectedIndex >= 0 && _selectedIndex < (testExamPaper?.optionsData?.length??0) &&
                            //                 (testExamPaper?.optionsData?[_selectedIndex].value??"") == (testExamPaper?.optionsData?[index].value??"")) ?
                            //         (isTapped == true && widget.isPracticeExam == true) ?
                            //         Text(
                            //             showTxt,
                            //             style: TextStyle(
                            //                 fontSize: Dimensions.fontSizeSmall,
                            //                 fontWeight: FontWeight.w400,
                            //                 color: showColor
                            //             )):const SizedBox():const SizedBox()
                            //       ],
                            //     ),
                            //   ),
                            // );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_DEFAULT),
                              child: InkWell(
                                onTap: () {
                                  // setState(() {
                                  //   if(widget.isPracticeExam==true) {
                                  //     if (!isTapped) {
                                  //       isTapped = true;
                                  //       _selectedIndex = index;
                                  //     }
                                  //   }
                                  //   else {
                                  //     if (isSelected) {
                                  //       _selectedIndex = -1;
                                  //     } else {
                                  //       _selectedIndex = index;
                                  //     }
                                  //   }
                                  // });
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: (showAnswer[_currentQuestionIndex] ?? false)
                                                ? ((testExamPaper?.correctOption ?? "") ==
                                                        (testExamPaper?.optionsData?[index].value ?? ""))
                                                    ? ThemeManager.correctChart
                                                    : ((testExamPaper?.selectedOption ?? "") ==
                                                            (testExamPaper?.optionsData?[index].value ?? ""))
                                                        ? ThemeManager.evolveRed
                                                        : ThemeManager.grey1
                                                : ThemeManager.grey1,
                                            width: 0.84),
                                        borderRadius: BorderRadius.circular(8),
                                        color: (showAnswer[_currentQuestionIndex] ?? false)
                                            ? ((testExamPaper?.correctOption ?? "") ==
                                                    (testExamPaper?.optionsData?[index].value ?? ""))
                                                ? ThemeManager.greenSuccess.withOpacity(0.1)
                                                : ((testExamPaper?.selectedOption ?? "") ==
                                                        (testExamPaper?.optionsData?[index].value ?? ""))
                                                    ? ThemeManager.redAlert.withOpacity(0.1)
                                                    : ThemeManager.white
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
                                                        color: (showAnswer[_currentQuestionIndex] ?? false)
                                                            ? ((testExamPaper?.correctOption ?? "") ==
                                                                    (testExamPaper
                                                                            ?.optionsData?[index].value ??
                                                                        ""))
                                                                ? ThemeManager.greenSuccess
                                                                : ((testExamPaper?.selectedOption ?? "") ==
                                                                        (testExamPaper
                                                                                ?.optionsData?[index].value ??
                                                                            ""))
                                                                    ? ThemeManager.redAlert
                                                                    : ThemeManager.black
                                                            : ThemeManager.black,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: MediaQuery.of(context).size.width * 0.6,
                                                      child: Text(
                                                        testExamPaper?.optionsData?[index].answerTitle ?? "",
                                                        style: TextStyle(
                                                          fontSize: Dimensions.fontSizeLarge,
                                                          fontWeight: FontWeight.w400,
                                                          color: (showAnswer[_currentQuestionIndex] ?? false)
                                                              ? ((testExamPaper?.correctOption ?? "") ==
                                                                      (testExamPaper
                                                                              ?.optionsData?[index].value ??
                                                                          ""))
                                                                  ? ThemeManager.greenSuccess
                                                                  : ((testExamPaper?.selectedOption ?? "") ==
                                                                          (testExamPaper?.optionsData?[index]
                                                                                  .value ??
                                                                              ""))
                                                                      ? ThemeManager.redAlert
                                                                      : ThemeManager.black
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
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    if ((showAnswer[_currentQuestionIndex] ?? false) &&
                                        (testExamPaper?.correctOption ?? "") ==
                                            (testExamPaper?.optionsData?[index].value ?? ""))
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                                        child: Text(
                                          "${testExamPaper?.optionsData?[index].percentage ?? "0"}% Got this answer correct",
                                          style: TextStyle(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: (testExamPaper?.correctOption ?? "") ==
                                                    (testExamPaper?.optionsData?[index].value ?? "")
                                                ? ThemeManager.greenSuccess
                                                : ThemeManager.orangeColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                    else if ((showAnswer[_currentQuestionIndex] ?? false) &&
                                        ((testExamPaper?.selectedOption ?? "") ==
                                            (testExamPaper?.optionsData?[index].value ?? "")))
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                                        child: Text(
                                          "${testExamPaper?.optionsData?[index].percentage ?? "0"}% Marked this incorrect",
                                          style: TextStyle(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: ThemeManager.redAlert,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                    else if ((showAnswer[_currentQuestionIndex] ?? false) &&
                                        ((testExamPaper?.correctOption ?? "") !=
                                            (testExamPaper?.optionsData?[index].value ?? "")) &&
                                        !((testExamPaper?.selectedOption ?? "") ==
                                            (testExamPaper?.optionsData?[index].value ?? "")))
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                                        child: Text(
                                          "${testExamPaper?.optionsData?[index].percentage ?? "0"}% Marked this",
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
                        // (isTapped==true&&widget.isPracticeExam==true)?
                        Observer(
                          builder: (BuildContext context) {
                            GetNotesSolutionModel? noteModel = store.notesData.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  height: Dimensions.PADDING_SIZE_DEFAULT,
                                ),
                                //Solution Explanation - Show only when showAnswer is true
                                (showAnswer[_currentQuestionIndex] ?? false)
                                    ? Column(
                                        children: [
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
                                              //     _showNotesDialog(context, filterTest?[_currentQuestionIndex].sId ?? "", noteModel?.notes??"");
                                              //   },
                                              //   child: SvgPicture.asset("assets/image/penIcon.svg"),
                                              // ),
                                              //       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,onPressed: (){
                                              //   _showNotesDialog(context, filterTest?[_currentQuestionIndex].sId ?? "", noteModel?.notes??"");
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
                                              // InkWell(
                                              //   onTap: () {
                                              //     _showNotesDialog(
                                              //         context,
                                              //         filterTest?[_currentQuestionIndex]
                                              //                 .sId ??
                                              //             "",
                                              //         noteModel?.notes ?? "");
                                              //   },
                                              //   child: Container(
                                              //     padding: const EdgeInsets.symmetric(
                                              //         horizontal: 17, vertical: 6),
                                              //     decoration: BoxDecoration(
                                              //         color: ThemeManager.whiteTrans,
                                              //         borderRadius:
                                              //             BorderRadius.circular(18.71),
                                              //         border: Border.all(
                                              //             color: ThemeManager.blueFinal)),
                                              //     child: Text(
                                              //       "Stick Notes",
                                              //       style: interBlack.copyWith(
                                              //         fontSize: Dimensions.fontSizeSmall,
                                              //         fontWeight: FontWeight.w400,
                                              //         color: AppColors.black,
                                              //       ),
                                              //     ),
                                              //   ),
                                              // ),
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
                                              const SizedBox(width: 10),
                                              // ── Multi-note panel (v3 upgrade)
                                              GestureDetector(
                                                onTap: () => _openMultiNotesPanel(
                                                  widget.testExamPaper?.test?[_currentQuestionIndex].sId ??
                                                      '',
                                                ),
                                                child:
                                                    const Icon(Icons.list_alt, size: 22, color: Colors.amber),
                                              ),
                                              const SizedBox(width: 10),
                                              // ── Highlighter toggle (activates dormant
                                              //    isHighlight + annotationData paths)
                                              GestureDetector(
                                                onTap: () => setState(() {
                                                  _v3HighlighterActive = !_v3HighlighterActive;
                                                }),
                                                child: Icon(
                                                  Icons.format_color_fill,
                                                  size: 22,
                                                  color: _v3HighlighterActive
                                                      ? Theme.of(context).colorScheme.primary
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withOpacity(0.5),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              // Legacy "Open Font Size dialog" — kept as fallback
                                              GestureDetector(
                                                onTap: () {
                                                  _showBottomSheet(context);
                                                },
                                                child: SvgPicture.asset(
                                                  "assets/image/atoz.svg",
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              // ── Quick A+/A-/A reset (no dialog)
                                              QuickFontControls(
                                                onChanged: (pct) {
                                                  setState(() {
                                                    // Wires to the existing showfontSize / textPercentage variables.
                                                    // Uncomment if your screen uses them:
                                                    // showfontSize = pct.toDouble();
                                                  });
                                                },
                                              ),

                                              // const SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_LARGE,),
                                              // if((noteModel?.notes??"") !="")
                                              //   GestureDetector(
                                              //     onTap: () async {
                                              //       await _controller.showTooltip();
                                              //     },
                                              //     child: SuperTooltip(
                                              //       showBarrier: true,
                                              //       controller: _controller,
                                              //       content: Text(
                                              //         noteModel?.notes??"",
                                              //         softWrap: true,
                                              //         style: TextStyle(
                                              //           fontSize: Dimensions.fontSizeDefault,
                                              //           fontWeight: FontWeight.w400,
                                              //           color: Theme.of(context).primaryColor,
                                              //         ),
                                              //       ),
                                              //       child: SvgPicture.asset("assets/image/messageIcon.svg"),
                                              //     ),
                                              //   ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: Dimensions.PADDING_SIZE_DEFAULT,
                                          ),

                                          // ── v3 Highlighter toolbar overlay ──
                                          // Renders when _v3HighlighterActive is true.
                                          // Selecting a color tells the existing Quill
                                          // editor to apply that color to selected text
                                          // (the editor already supports the
                                          // 'background' attribute via dormant code).
                                          if (_v3HighlighterActive)
                                            HighlighterToolbar(
                                              activeColor: _v3HighlightColor,
                                              eraserMode: _v3EraserMode,
                                              onSelectColor: (c) => setState(() {
                                                _v3HighlightColor = c;
                                                _v3EraserMode = false;
                                              }),
                                              onToggleEraser: () =>
                                                  setState(() => _v3EraserMode = !_v3EraserMode),
                                              onClose: () => setState(() {
                                                _v3HighlighterActive = false;
                                                _v3HighlightColor = null;
                                                _v3EraserMode = false;
                                              }),
                                            ),

                                          // Show explanation only when showAnswer is true
                                          explanationWidget ?? const SizedBox(),
                                        ],
                                      )
                                    : const SizedBox(),

                                const SizedBox(
                                  height: Dimensions.PADDING_SIZE_DEFAULT,
                                ),

                                // ── MCQ Review v3 — drop-in action bar + cohort time
                                // Renders only after the student has revealed the
                                // answer. Bundles: Highlight · Notes · Ask Cortex
                                // (multi-turn) · Why-was-I-wrong (when wrong) ·
                                // Listen (audio) · Mnemonic · Diagram · Review later
                                // (SR queue) · Discuss · Report. Plus chips at top:
                                // Difficulty / Q-type / Topic (tap → deep-dive).
                                if ((showAnswer[_currentQuestionIndex] ?? false)) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Dimensions.PADDING_SIZE_LARGE,
                                    ),
                                    child: McqSolutionActionBar(
                                      questionId: filterTest?[_currentQuestionIndex].sId ?? '',
                                      selectedOption: filterTest?[_currentQuestionIndex].selectedOption,
                                      correctOption: filterTest?[_currentQuestionIndex].correctOption,
                                      examId: filterTest?[_currentQuestionIndex].examId,
                                      userExamId: widget.userExamId,
                                      examType: 'regular',
                                      questionText: filterTest?[_currentQuestionIndex].questionText,
                                      options: filterTest?[_currentQuestionIndex].optionsData,
                                      briefExplanation: filterTest?[_currentQuestionIndex].explanation,
                                      wasWrong: (filterTest?[_currentQuestionIndex].selectedOption != null) &&
                                          (filterTest?[_currentQuestionIndex].selectedOption !=
                                              filterTest?[_currentQuestionIndex].correctOption),
                                      // topic/subtopic/difficulty/questionType not on the
                                      // current ExamPaperData model — pass through if you
                                      // add them later. Chips will simply not render.
                                      // UPDATE THESE TWO LINES:
                                      onOpenNotes: () =>
                                          _openMultiNotesPanel(filterTest?[_currentQuestionIndex].sId ?? ''),
                                      onToggleHighlighter: () =>
                                          setState(() => _v3HighlighterActive = !_v3HighlighterActive),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Dimensions.PADDING_SIZE_LARGE,
                                      vertical: 8,
                                    ),
                                    child: TimeVsAvg(
                                      questionId: filterTest?[_currentQuestionIndex].sId ?? '',
                                    ),
                                  ),
                                ],

                                // Show AI explanation only when showAnswer is true
                                ((showAnswer[_currentQuestionIndex] ?? false) && isbutton == true)
                                    ? Observer(
                                        builder: (BuildContext context) {
                                          GetExplanationModel? getExplainModel =
                                              store.getExplanationText.value;
                                          // debugPrint("store.getExplanationText.value.text: ${store.getExplanationText.value?.text}");
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: Dimensions.PADDING_SIZE_LARGE,
                                                vertical: Dimensions.PADDING_SIZE_LARGE),
                                            decoration: BoxDecoration(
                                                color: ThemeManager.explainContainer,
                                                borderRadius:
                                                    BorderRadius.circular(Dimensions.RADIUS_DEFAULT)),
                                            child: Column(
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      width: Dimensions.PADDING_SIZE_DEFAULT * 2.4,
                                                      height: Dimensions.PADDING_SIZE_DEFAULT * 2.4,
                                                      alignment: Alignment.center,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: ThemeManager.whitePrimary,
                                                      ),
                                                      child: Text(
                                                        "AI",
                                                        style: interBlack.copyWith(
                                                          fontSize: Dimensions.fontSizeLarge,
                                                          fontWeight: FontWeight.w700,
                                                          color: ThemeManager.primaryWhite,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: Dimensions.PADDING_SIZE_SMALL,
                                                    ),
                                                    Text(
                                                      "Cortex.AI ",
                                                      style: interBlack.copyWith(
                                                        fontSize: Dimensions.fontSizeExtraLarge,
                                                        fontWeight: FontWeight.w500,
                                                        color: AppColors.white,
                                                      ),
                                                    ),
                                                    Text(
                                                      "Explains",
                                                      style: interBlack.copyWith(
                                                        fontSize: Dimensions.fontSizeExtraLarge,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: Dimensions.PADDING_SIZE_DEFAULT,
                                                ),
                                                TypeWriterText(
                                                  text: Text(
                                                    getExplainModel?.text ?? '',
                                                    style: interBlack.copyWith(
                                                      fontSize: Dimensions.fontSizeDefault,
                                                      fontWeight: FontWeight.w400,
                                                      color: AppColors.white,
                                                    ),
                                                  ),
                                                  maintainSize: false,
                                                  duration: const Duration(milliseconds: 10),
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
                            );
                          },
                        )
                        // :const SizedBox()
                      ],
                    ),
                  ),
                ), // close SwipeNavigationWrapper (V3 — wraps SingleChildScrollView)
              ),

              const SizedBox(
                height: Dimensions.PADDING_SIZE_DEFAULT,
              ),
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
                        text: "Next",
                      ),
                    ),
                  ],
                ),
              ),
              // Row(
              //   children: [
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
              //             onPressed:isprocess == true ? null : (firstQue?null:_showPreviousQuestion),
              //             child: Text("Previous",
              //               style: TextStyle(
              //                 fontSize: Dimensions.fontSizeDefault,
              //                 fontWeight: FontWeight.w400,
              //                 color: firstQue ? ThemeManager.black : ThemeManager.home1,
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
              //             onPressed:isprocess == true ? null : _showNextQuestion,
              //             child: isLastQues==true?
              //             Text("End Practice",
              //               style: TextStyle(
              //                 fontSize: Dimensions.fontSizeDefault,
              //                 fontWeight: FontWeight.w400,
              //                 color:ThemeManager.home1
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
              // CustomButton(onPressed: (){
              //   isMarkedForReview=true;
              //   _showNextQuestion();
              //   // Navigator.of(context).pushNamed(Routes.questionPallet);
              // },
              //   buttonText: "Mark for review",
              //   height: Dimensions.PADDING_SIZE_EXTRA_LARGE*2,
              //   textAlign: TextAlign.center,
              //   radius: Dimensions.RADIUS_DEFAULT,
              //   transparent: true,
              //   bgColor: Theme.of(context).primaryColor,
              //   fontSize: Dimensions.fontSizeDefault,
              // ),
            ],
          ),
          drawer: Drawer(
            backgroundColor: Colors.white,
            child: QuestionPallet(widget.testExamPaper, widget.userExamId, null, widget.isPracticeExam, null),
          )),
    );
  }

  // void _showNotesDialog(BuildContext context, String questionId, String notes) {
  //   // showDialog(
  //   //   context: context,
  //   //   barrierDismissible: false,
  //   //   builder: (BuildContext context) {
  //   //     TextEditingController queryController = TextEditingController();
  //   //     queryController.text = notes;
  //   //     return AlertDialog(
  //   //       title: Text('Add Notes',
  //   //         style: interRegular.copyWith(
  //   //           fontSize: Dimensions.fontSizeExtraLarge,
  //   //           fontWeight: FontWeight.w500,
  //   //           color: ThemeManager.black,
  //   //         ),),
  //   //       content: Form(
  //   //         child: SizedBox(
  //   //           width: MediaQuery.of(context).size.width * 0.9,
  //   //           height: MediaQuery.of(context).size.height * 0.2,
  //   //           child: TextFormField(
  //   //             cursorColor: Theme.of(context).primaryColor,
  //   //             controller: queryController,
  //   //             maxLines: 50,
  //   //             keyboardType: TextInputType.multiline,
  //   //             decoration: InputDecoration(
  //   //               enabledBorder: UnderlineInputBorder(
  //   //                 borderSide: BorderSide(color: Theme.of(context).primaryColor),
  //   //               ),
  //   //               focusedBorder: UnderlineInputBorder(
  //   //                 borderSide: BorderSide(color:Theme.of(context).primaryColor),
  //   //               ),
  //   //               hintText: 'Enter your notes...',
  //   //               hintStyle: interRegular.copyWith(
  //   //                 fontSize: Dimensions.fontSizeLarge,
  //   //                 fontWeight: FontWeight.w400,
  //   //                 color: Theme.of(context).hintColor,
  //   //               ),
  //   //             ),
  //   //             style: interRegular.copyWith(
  //   //               fontSize: Dimensions.fontSizeLarge,
  //   //               fontWeight: FontWeight.w400,
  //   //               color: ThemeManager.black,
  //   //             ),
  //   //           ),
  //   //         ),
  //   //       ),
  //   //       actions: [
  //   //         Row(
  //   //           mainAxisAlignment: MainAxisAlignment.center,
  //   //           children: [
  //   //             SizedBox(
  //   //               height: Dimensions.PADDING_SIZE_LARGE * 2,
  //   //               child: ElevatedButton(
  //   //                 onPressed: () {
  //   //                   Navigator.of(context).pop();
  //   //                 },
  //   //                 style: ElevatedButton.styleFrom(
  //   //                     shape: RoundedRectangleBorder(
  //   //                       borderRadius: BorderRadius.circular(8),
  //   //                     ),
  //   //                     backgroundColor: Theme.of(context).hintColor
  //   //                 ),
  //   //                 child: Text('Cancel',
  //   //                   style: interRegular.copyWith(
  //   //                     fontSize: Dimensions.fontSizeLarge,
  //   //                     fontWeight: FontWeight.w400,
  //   //                     color: Colors.white,
  //   //                   ),),
  //   //               ),
  //   //             ),
  //   //             const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT,),
  //   //             SizedBox(
  //   //               height: Dimensions.PADDING_SIZE_LARGE * 2,
  //   //               child: ElevatedButton(
  //   //                 style: ElevatedButton.styleFrom(
  //   //                     shape: RoundedRectangleBorder(
  //   //                       borderRadius: BorderRadius.circular(8),
  //   //                     ),
  //   //                     backgroundColor: Theme.of(context).primaryColor
  //   //                 ),
  //   //                 onPressed: () {
  //   //                   String notes = queryController.text;
  //   //                   debugPrint('enterTxt$notes');
  //   //                   addNotes(filterTest?[_currentQuestionIndex].sId,notes);
  //   //                   Navigator.of(context).pop();
  //   //                 },
  //   //                 child: Text('Submit',
  //   //                   style: interRegular.copyWith(
  //   //                     fontSize: Dimensions.fontSizeLarge,
  //   //                     fontWeight: FontWeight.w400,
  //   //                     color: Colors.white,
  //   //                   ),),
  //   //               ),
  //   //             ),
  //   //           ],
  //   //         ),
  //   //         const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
  //   //       ],
  //   //     );
  //   //   },
  //   // );
  //   if (Platform.isWindows || Platform.isMacOS) {
  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           backgroundColor: ThemeManager.mainBackground,
  //           actionsPadding: EdgeInsets.zero,
  //           insetPadding: const EdgeInsets.symmetric(horizontal: 250),
  //           actions: [
  //             CustomBottomStickNotesWindow(questionId: questionId, notes: notes),
  //           ],
  //         );
  //       },
  //     );
  //   } else {
  //     // Old bottom sheet implementation retained for reference.
  //     // showModalBottomSheet<String>(
  //     //     isScrollControlled: true,
  //     //     shape: const RoundedRectangleBorder(
  //     //       borderRadius: BorderRadius.vertical(
  //     //         top: Radius.circular(25),
  //     //       ),
  //     //     ),
  //     //     clipBehavior: Clip.antiAliasWithSaveLayer,
  //     //     context: context,
  //     //     builder: (BuildContext context) {
  //     //       return CustomBottomStickNotes(questionId: questionId, notes: notes);
  //     //     });
  //     showDialog(
  //       context: context,
  //       barrierDismissible: true,
  //       builder: (BuildContext context) {
  //         return CustomBottomStickNotes(
  //           questionId: questionId,
  //           notes: notes,
  //         );
  //       },
  //     );
  //   }
  // }

  void _showNotesDialog(BuildContext context, String questionId, String notes) {
    // V3 Upgrade - Route to the new StickyNotesPanel instead of the old dialog boxes
    _openMultiNotesPanel(questionId);
  }

  Future<void> addNotes(String? questionId, String? notes) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onCreateNotes(context, questionId ?? "", notes ?? "");
    _getNotesData(filterTest?[_currentQuestionIndex].sId ?? "");
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

  Future<void> _showBottomSheet(BuildContext context) async {
    if (Platform.isWindows || Platform.isMacOS) {
      final double? selectedFontSize = await showDialog<double>(
        context: context,
        builder: (BuildContext context) {
          double currentFontSize = _textSize;
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
                            Navigator.pop(context, currentFontSize);
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
          showfontSize = (100 + ((selectedFontSize - Dimensions.fontSizeDefault) * 10));
        });
      }
    } else {
      final double? selectedFontSize = await showDialog<double>(
        context: context,
        builder: (BuildContext context) {
          double currentFontSize = _textSize;
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
                                    showCurrFontSize += 10;
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
                                Navigator.pop(context, currentFontSize); // Return the updated font size
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
          _textSize = selectedFontSize;
          showfontSize = (100 + ((selectedFontSize - Dimensions.fontSizeDefault) * 10));
        });
      }
    }
  }

  Widget _buildScoreItem({
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
