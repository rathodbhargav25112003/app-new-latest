// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, unused_local_variable, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names, dead_null_aware_expression, dead_code

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/test/question_pallet.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/widgets/bottom_raise_query_window.dart'
    show CustomBottomRaiseQueryWindow;
import 'package:shusruta_lms/modules/widgets/bottom_stick_notes_window.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:typewritertext/typewritertext.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
// Wave-2 post-attempt analytics drop-in (heatmap + time-pressure +
// calibration + cohort %ile + Claude pattern summary + remediation).
import 'package:shusruta_lms/modules/new_exam_component/widgets/post_attempt_analytics_panel.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/get_all_my_custom_test_model.dart';
import '../../models/get_explanation_model.dart';
import '../../models/get_notes_solution_model.dart';
import '../customtests/custom_question_pallet.dart';
import '../customtests/custom_test_bottom_raise_query.dart';
import '../reports/store/report_by_category_store.dart';
import '../widgets/bottom_raise_query.dart';
import '../widgets/bottom_stick_notes.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_test_cancel_dialogbox.dart';

/// Custom-test solution runner (review mode) — redesigned with AppTokens.
/// Preserves every public API surface the rest of the app depends on:
///   • Constructor `PracticeCustomTestSolutionExamScreen({super.key,
///     fromPallete, testExamPaper, userExamId, isPracticeExam, queNo,
///     remainingTime, id, type, isCorrect})`
///   • Static `route(RouteSettings)` factory (CupertinoPageRoute) with args:
///     testData / userexamId / queNo / isPracticeExam / remainingTime / id /
///     type / fromPallete / isCorrect
///   • State fields: _scaffoldKey, _selectedIndex (=-1),
///     _currentQuestionIndex (=0), isLastQues / firstQue, isAttempted /
///     isMarkedForReview / isGuess / isAttemptedAndMarkedForReview /
///     isSkipped, answerImgBytes / quesImgBytes / explanationImgBytes,
///     filterTest, isTapped, explanationWidget / questionWidget, _controller
///     (SuperTooltipController), isbutton / isprocess, _textSize
///     (=Dimensions.fontSizeDefault), showfontSize (=100), _scrollController
///   • Lifecycle: initState → getCountReportPractice(context); isTapped=false;
///     filterTest set from testExamPaper.test filtered by isCorrect when
///     supplied; resolve matchingIndex by questionNumber == queNo and if found
///     call _getSelectedAnswer + move _currentQuestionIndex + firstQue=false;
///     finally _getNotesData on the first question
///   • All helper methods with the exact same names & signatures:
///     _getExplanationData(prompt), _putBookMarkApiCall(examId, questionId),
///     _getSelectedAnswer(queId), _getCount(userExamId),
///     openBottomSheet(store), _showNextQuestion(), _showPreviousQuestion(),
///     _onBackPressed(), getExplanationText(context),
///     getQuestionText(context), _scrollToIndex(index),
///     getCountReportPractice(context), _questionChange(index),
///     _showNotesDialog(context, questionId, notes),
///     addNotes(questionId, notes), _getNotesData(queId),
///     _showDialog(context, questionId), _showBottomSheet(context)
///   • TestCategoryStore APIs retained: questionAnswerByIdCustomTest,
///     getCustomTestQuestionPalleteCount, onGetCustomReportPracticeCountApiCall,
///     getCustomReportPracticeCountData.value
///   • ReportsCategoryStore APIs retained: onGetExplanationCall,
///     onBookMarkQuestion, onGetNotesData, onCreateNotes,
///     onCreateQuerySolutionReport, notesData.value,
///     getExplanationText.value
///   • Back arrow pushNamed Routes.testCategory (intentionally pushes, not
///     pops — matches legacy)
///   • Save & Exit dialog button pushNamed Routes.testCategory
///   • Drawer hosts `CustomTestQuestionPallet(testExamPaper, userExamId,
///     null, isPracticeExam, null)` (5-positional API preserved)
///   • Raise Query → desktop `CustomBottomRaiseQueryWindow` (AlertDialog) /
///     mobile `CustomBottomRaiseQuery` (bottom sheet) with preserved
///     questionId / questionText / allOptions payload (a-d joined)
///   • Stick Notes → desktop `CustomBottomStickNotesWindow` dialog /
///     mobile `CustomBottomStickNotes` dialog with questionId + notes
///   • Ask Cortex.AI prompt: "Explain why {correct} is the answer to the
///     Question {questionText} and why the remaining {others} are not
///     correct answer"
///   • Cortex.AI explains panel rendered with TypeWriterText (10ms cadence)
///     when isbutton==true; shown inside Observer watching
///     getExplanationText.value
///   • Explanation/question text mapping: split on splittedImage and
///     `NetworkImage(base64String)` → PhotoView on tap; bullet rewrites:
///     `\t\t\t--` → 17-space bullet, `\t\t--` → 11-space bullet, `\t--` →
///     5-space bullet, `--` → `•`
///   • Scroll strip coloured by correctOption==selectedOption: greenBorder
///     match / redText mismatch (ThemeManager values preserved)
class PracticeCustomTestSolutionExamScreen extends StatefulWidget {
  final Data? testExamPaper;
  final String? userExamId;
  final int? queNo;
  final bool? isPracticeExam;
  final ValueNotifier<Duration>? remainingTime;
  final String? id;
  final String? type;
  final bool? isCorrect;
  final bool? fromPallete;

  const PracticeCustomTestSolutionExamScreen({
    super.key,
    this.fromPallete,
    this.testExamPaper,
    this.userExamId,
    this.isPracticeExam,
    this.queNo,
    this.remainingTime,
    this.id,
    this.type,
    this.isCorrect,
  });

  @override
  State<PracticeCustomTestSolutionExamScreen> createState() =>
      _PracticeCustomTestSolutionExamScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => PracticeCustomTestSolutionExamScreen(
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

class _PracticeCustomTestSolutionExamScreenState
    extends State<PracticeCustomTestSolutionExamScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  Widget? explanationWidget;
  Widget? questionWidget;

  final _controller = SuperTooltipController();
  bool isbutton = false, isprocess = false;

  double _textSize = Dimensions.fontSizeDefault;
  double showfontSize = 100;

  final ScrollController _scrollController = ScrollController();

  // ==========================================================================
  // Lifecycle
  // ==========================================================================

  @override
  void initState() {
    super.initState();
    getCountReportPractice(context);
    isTapped = false;
    filterTest = widget.testExamPaper?.test;
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

    int matchingIndex =
        filterTest?.indexWhere((e) => e.questionNumber == widget.queNo) ?? -1;
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

  @override
  void dispose() {
    super.dispose();
  }

  // ==========================================================================
  // Store glue (preserved signatures)
  // ==========================================================================

  Future<void> _getExplanationData(String prompt) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onGetExplanationCall(prompt);
    setState(() {
      isprocess = false;
      isbutton = true;
    });
  }

  Future<void> _putBookMarkApiCall(String examId, String? questionId) async {
    setState(() {
      widget.testExamPaper?.test?[_currentQuestionIndex].bookmarks =
          !(widget.testExamPaper?.test?[_currentQuestionIndex].bookmarks ??
              false);
    });
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    store.onBookMarkQuestion(
      context,
      widget.testExamPaper?.test?[_currentQuestionIndex].bookmarks ?? false,
      examId,
      questionId ?? "",
      "",
    );
    BottomToast.showBottomToastOverlay(
      context: context,
      errorMessage:
          widget.testExamPaper?.test?[_currentQuestionIndex].bookmarks ?? false
              ? "Question Bookmarked Successfully!"
              : "Bookmark Removed!",
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  Future<void> _getSelectedAnswer(String queId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.questionAnswerByIdCustomTest(widget.userExamId ?? "", queId);
    setState(() {
      String? nextOption = store.userCustomAnswerExam.value?.selectedOption;
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
    await store.getCustomTestQuestionPalleteCount(userExamId ?? "").then((_) {
      openBottomSheet(store);
    });
  }

  Future<void> getCountReportPractice(context) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onGetCustomReportPracticeCountApiCall(widget.userExamId ?? "");
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

  // ==========================================================================
  // Summary sheet (Save & Exit)
  // ==========================================================================

  void openBottomSheet(TestCategoryStore store) {
    getCountReportPractice(context);
    _showSummaryDialog(store);
  }

  void _showSummaryDialog(TestCategoryStore store) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTokens.surface(ctx),
        surfaceTintColor: AppTokens.surface(ctx),
        shape: RoundedRectangleBorder(borderRadius: AppTokens.radius20),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTokens.accentSoft(ctx),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.summarize_rounded,
                      color: AppTokens.accent(ctx),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: Text(
                      "Practice Test Summary",
                      style: AppTokens.titleMd(ctx),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s16),
              _SummaryStat(
                icon: Icons.check_rounded,
                tone: _StatTone.success,
                label: "Correct",
                value:
                    "${store.getCustomReportPracticeCountData.value?.correctAnswers ?? 0}",
              ),
              const SizedBox(height: AppTokens.s8),
              _SummaryStat(
                icon: Icons.close_rounded,
                tone: _StatTone.danger,
                label: "Incorrect",
                value:
                    "${store.getCustomReportPracticeCountData.value?.incorrectAnswers ?? 0}",
              ),
              const SizedBox(height: AppTokens.s8),
              _SummaryStat(
                icon: Icons.priority_high_rounded,
                tone: _StatTone.warning,
                label: "Unanswered",
                value:
                    "${store.getCustomReportPracticeCountData.value?.notVisited ?? 0}",
              ),
              const SizedBox(height: AppTokens.s20),
              SizedBox(
                width: double.infinity,
                child: _PrimaryBtn(
                  label: "Save & Exit",
                  onTap: () =>
                      Navigator.of(ctx).pushNamed(Routes.testCategory),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // Navigation (prev / next / back)
  // ==========================================================================

  Future<void> _showNextQuestion() async {
    isbutton = false;
    firstQue = false;
    isTapped = false;
    String? questionId = filterTest?[_currentQuestionIndex].sId;

    String? selectedOption = _selectedIndex == -1
        ? ""
        : filterTest?[_currentQuestionIndex]
            .optionsData?[_selectedIndex]
            .value;
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
    setState(() {
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
      return true;
    }
  }

  void _questionChange(int index) {
    setState(() {
      _currentQuestionIndex = index;
    });
  }

  void _scrollToIndex(int index) {
    final tile = 40.0 + AppTokens.s8; // matches chip width + spacing below
    double totalWidth = (filterTest?.length ?? 0) * tile;
    double viewportWidth = MediaQuery.of(context).size.width;
    double maxScrollExtent =
        (totalWidth - viewportWidth).clamp(0.0, double.infinity);
    double targetScrollPosition = (index * tile).clamp(0.0, maxScrollExtent);

    _scrollController.animateTo(
      targetScrollPosition,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // ==========================================================================
  // Preserved rich-text builders
  // ==========================================================================

  Widget getExplanationText(BuildContext context) {
    String explanation = filterTest?[_currentQuestionIndex].explanation ?? "";
    explanation = explanation.replaceAllMapped(
        RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    List<String> splittedText = explanation.split("splittedImage");
    List<Widget> columns = [];
    int index = 0;

    for (String text in splittedText) {
      List<Widget> explanationImageWidget = [];
      if (filterTest?[_currentQuestionIndex].explanationImg?.isNotEmpty ??
          false) {
        for (String base64String in widget
            .testExamPaper!.test![_currentQuestionIndex].explanationImg!) {
          try {
            explanationImageWidget.add(
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
                child: InteractiveViewer(
                  scaleEnabled: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ClipRRect(
                      borderRadius: AppTokens.radius12,
                      child: Image.network(base64String, fit: BoxFit.cover),
                    ),
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
                  .replaceAll("\t\t\t--", "                 •")
                  .replaceAll("\t\t--", "           •")
                  .replaceAll("\t--", "     •")
                  .replaceAll("--", "•"),
              textAlign: TextAlign.justify,
              style: AppTokens.body(context).copyWith(fontSize: _textSize),
            ),
            const SizedBox(height: AppTokens.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: explanationImageWidget,
            ),
            const SizedBox(height: AppTokens.s8),
            if (explanationImageWidget.isNotEmpty)
              Text(
                "Tap the image to zoom In/Out",
                style: AppTokens.caption(context)
                    .copyWith(color: AppTokens.ink2(context)),
              ),
          ],
        ),
      );
      index++;

      if (index >=
          (filterTest?[_currentQuestionIndex].explanationImg?.length ?? 0) -
              1) {
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
          style: AppTokens.body(context),
        ),
      );
    }

    String questionTxt = filterTest?[_currentQuestionIndex].questionText ?? "";
    questionTxt = questionTxt.replaceAllMapped(
        RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    List<String> splittedText = questionTxt.split("splittedImage");
    List<Widget> columns = [];
    int index = 0;
    for (String text in splittedText) {
      List<Widget> questionImageWidget = [];
      if (filterTest?[_currentQuestionIndex].questionImg?.isNotEmpty ?? false) {
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
                child: InteractiveViewer(
                  scaleEnabled: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ClipRRect(
                      borderRadius: AppTokens.radius12,
                      child: Image.network(base64String, fit: BoxFit.cover),
                    ),
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
                  .replaceAll("\t\t\t--", "                 •")
                  .replaceAll("\t\t--", "           •")
                  .replaceAll("\t--", "     •")
                  .replaceAll("--", "•"),
              textAlign: TextAlign.left,
              style: AppTokens.bodyLg(context),
            ),
            const SizedBox(height: AppTokens.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: questionImageWidget,
            ),
            const SizedBox(height: AppTokens.s8),
            if (questionImageWidget.isNotEmpty)
              Text(
                "Tap the image to zoom In/Out",
                style: AppTokens.caption(context)
                    .copyWith(color: AppTokens.ink2(context)),
              ),
          ],
        ),
      );
      index++;
      if (index >=
          (filterTest?[_currentQuestionIndex].questionImg?.length ?? 0) - 1) {
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns,
    );
  }

  // ==========================================================================
  // Build
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    final store2 = Provider.of<TestCategoryStore>(context, listen: false);
    explanationWidget = getExplanationText(context);
    questionWidget = getQuestionText(context);

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppTokens.scaffold(context),
        appBar: _buildAppBar(context, store2),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIndexStrip(),
            _buildCurrentQuestionHeader(),
            const SizedBox(height: AppTokens.s12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s16,
                  0,
                  AppTokens.s16,
                  AppTokens.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    questionWidget ?? const SizedBox(),
                    const SizedBox(height: AppTokens.s12),
                    _buildOptionsList(),
                    if (isTapped == true && widget.isPracticeExam == true)
                      _buildExplanationPanel(store),
                  ],
                ),
              ),
            ),
            _buildNavBar(),
          ],
        ),
        drawer: Drawer(
          backgroundColor: AppTokens.surface(context),
          child: CustomTestQuestionPallet(
            widget.testExamPaper,
            widget.userExamId,
            null,
            widget.isPracticeExam,
            null,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, TestCategoryStore store2) {
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: AppTokens.surface(context),
      title: Row(
        children: [
          _CircleIconBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).pushNamed(Routes.testCategory),
          ),
          const SizedBox(width: AppTokens.s12),
          _CircleIconBtn(
            icon: Icons.grid_view_rounded,
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const Spacer(),
          // Wave-2 Insights button — opens PostAttemptAnalyticsPanel.
          if ((widget.userExamId ?? '').isNotEmpty) ...[
            _CircleIconBtn(
              icon: Icons.insights_rounded,
              onTap: () => _openInsights(context),
            ),
            const SizedBox(width: AppTokens.s12),
          ],
          InkWell(
            borderRadius: AppTokens.radius28,
            onTap: () => _showSummaryDialog(store2),
            child: Container(
              height: 36,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTokens.accent(context)),
              ),
              child: Text(
                "Save & Exit",
                style: AppTokens.titleSm(context)
                    .copyWith(color: AppTokens.accent(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Wave-2 fullscreen insights sheet — bundles heatmap +
  /// time-pressure + calibration + cohort percentile + Claude
  /// pattern summary + remediation CTA.
  void _openInsights(BuildContext context) {
    if ((widget.userExamId ?? '').isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Performance insights'),
          backgroundColor: AppTokens.surface(context),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: PostAttemptAnalyticsPanel(
            userExamId: widget.userExamId!,
            onRemediationCreated: (newId, count) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  'Remediation set ready ($count Qs). Find it in In-progress attempts.',
                ),
              ));
            },
          ),
        ),
      ),
    ));
  }

  Widget _buildIndexStrip() {
    final length = filterTest?.length ?? 0;
    if (length == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s16,
        AppTokens.s16,
        AppTokens.s16,
        AppTokens.s8,
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(length, (index) {
            final TestData? solutionReport = filterTest?[index];
            final bool match = (solutionReport?.correctOption ?? "") ==
                (solutionReport?.selectedOption ?? "");
            final bool active = _currentQuestionIndex == index;
            final Color tint = match
                ? AppTokens.success(context)
                : AppTokens.danger(context);
            return Padding(
              padding: const EdgeInsets.only(right: AppTokens.s8),
              child: GestureDetector(
                onTap: () => _questionChange(index),
                child: Container(
                  height: 36,
                  width: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? tint : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: tint),
                  ),
                  child: Text(
                    "${index + 1}",
                    style: AppTokens.titleSm(context).copyWith(
                      color: active ? Colors.white : tint,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentQuestionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s16,
        AppTokens.s8,
        AppTokens.s16,
        AppTokens.s4,
      ),
      child: Row(
        children: [
          Text(
            "${_currentQuestionIndex + 1}.",
            style: AppTokens.displayMd(context),
          ),
          const Spacer(),
          _ActionPill(
            onTap: () async {
              if (!isbutton) {
                setState(() {
                  isprocess = true;
                });
              }
              final TestData? solutionReport =
                  filterTest?[_currentQuestionIndex];
              final questionText = solutionReport?.questionText;
              final currentOption = solutionReport?.correctOption;
              final answerTitle =
                  solutionReport?.optionsData?.map((e) => e.answerTitle);
              int currentIndex = solutionReport?.optionsData
                      ?.indexWhere((e) => e.value == currentOption) ??
                  -1;
              String? currentAnswerTitle = answerTitle?.elementAt(currentIndex);
              List<String?> notMatchingAnswerTitles = answerTitle
                      ?.where((title) => title != currentAnswerTitle)
                      .toList() ??
                  [];
              String concatenatedTitles = notMatchingAnswerTitles
                  .where((title) => title != null)
                  .join(", ");
              String question =
                  "Explain why $currentAnswerTitle is the answer to the Question $questionText and why the remaining $concatenatedTitles are not correct answer";
              debugPrint("question12 :$question");
              if (isbutton == false) {
                await _getExplanationData(question);
              }
            },
            tone: _ActionTone.brand,
            child: isprocess
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.0,
                    ),
                  )
                : const Text("Ask Cortex.AI"),
          ),
          const SizedBox(width: AppTokens.s8),
          _ActionPill(
            tone: _ActionTone.outline,
            onTap: () {
              if (Platform.isWindows || Platform.isMacOS) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: AppTokens.surface(context),
                      actionsPadding: EdgeInsets.zero,
                      actions: [
                        CustomBottomRaiseQueryWindow(
                          questionId:
                              filterTest?[_currentQuestionIndex].sId ?? "",
                          questionText:
                              filterTest?[_currentQuestionIndex].questionText ??
                                  '',
                          allOptions: _allOptionsPayload(),
                        ),
                      ],
                    );
                  },
                );
              } else {
                showModalBottomSheet<String>(
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  context: context,
                  builder: (BuildContext context) {
                    return CustomBottomRaiseQuery(
                      questionId:
                          filterTest?[_currentQuestionIndex].sId ?? "",
                      questionText:
                          filterTest?[_currentQuestionIndex].questionText ??
                              '',
                      allOptions: _allOptionsPayload(),
                    );
                  },
                );
              }
            },
            child: const Text("Raise Query"),
          ),
        ],
      ),
    );
  }

  String _allOptionsPayload() {
    final opts = filterTest?[_currentQuestionIndex].optionsData;
    String pick(int i) {
      if (opts == null || opts.length <= i) return "";
      return opts[i].answerTitle ?? "";
    }

    return "a) ${pick(0)}\nb) ${pick(1)}\nc) ${pick(2)}\nd) ${pick(3)}";
  }

  Widget _buildOptionsList() {
    final TestData? testExamPaper = filterTest?[_currentQuestionIndex];
    final int count = testExamPaper?.optionsData?.length ?? 0;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, index) {
        final optionValue = testExamPaper?.optionsData?[index].value ?? "";
        final optionTitle =
            testExamPaper?.optionsData?[index].answerTitle ?? "";
        final String answerImg =
            testExamPaper?.optionsData?[index].answerImg ?? "";

        final bool isCorrect =
            (testExamPaper?.correctOption ?? "") == optionValue;
        final bool isSelected =
            (testExamPaper?.selectedOption ?? "") == optionValue;

        Color borderColor = AppTokens.border(context);
        Color fillColor = AppTokens.surface(context);
        Color textColor = AppTokens.ink(context);

        if (isCorrect) {
          borderColor = AppTokens.success(context);
          fillColor = AppTokens.successSoft(context);
          textColor = AppTokens.success(context);
        } else if (isSelected) {
          borderColor = AppTokens.danger(context);
          fillColor = AppTokens.dangerSoft(context);
          textColor = AppTokens.danger(context);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.s8),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(28),
              color: fillColor,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s16,
              vertical: AppTokens.s12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$optionValue.  ",
                      style: AppTokens.titleSm(context)
                          .copyWith(color: textColor),
                    ),
                    Expanded(
                      child: Text(
                        optionTitle,
                        style: AppTokens.body(context)
                            .copyWith(color: textColor),
                      ),
                    ),
                    if (isCorrect || isSelected) ...[
                      const SizedBox(width: AppTokens.s8),
                      Icon(
                        isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: textColor,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                if (answerImg.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.s8),
                  InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.0,
                    child: ClipRRect(
                      borderRadius: AppTokens.radius12,
                      child: Image.network(
                        answerImg,
                        fit: BoxFit.cover,
                        height: 200,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExplanationPanel(ReportsCategoryStore store) {
    return Observer(builder: (BuildContext context) {
      final GetNotesSolutionModel? noteModel = store.notesData.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTokens.s12),
          Row(
            children: [
              Text(
                "Explanation",
                style: AppTokens.titleMd(context),
              ),
              const Spacer(),
              IconButton(
                tooltip: "Sticky note",
                icon: Icon(
                  Icons.sticky_note_2_rounded,
                  color: AppTokens.accent(context),
                ),
                onPressed: () => _showNotesDialog(
                  context,
                  filterTest?[_currentQuestionIndex].sId ?? "",
                  noteModel?.notes ?? "",
                ),
              ),
              IconButton(
                tooltip: "Text size",
                icon: Icon(
                  Icons.text_fields_rounded,
                  color: AppTokens.accent(context),
                ),
                onPressed: () => _showBottomSheet(context),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          explanationWidget ?? const SizedBox(),
          const SizedBox(height: AppTokens.s12),
          if (isbutton == true)
            Observer(builder: (BuildContext context) {
              final GetExplanationModel? getExplainModel =
                  store.getExplanationText.value;
              return Container(
                padding: const EdgeInsets.all(AppTokens.s16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTokens.brand, AppTokens.brand2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppTokens.radius16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: const Text(
                            "AI",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.s8),
                        const Text(
                          "Cortex.AI Explains",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.s12),
                    TypeWriterText(
                      text: Text(
                        getExplainModel?.text ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      maintainSize: false,
                      duration: const Duration(milliseconds: 10),
                    ),
                  ],
                ),
              );
            }),
        ],
      );
    });
  }

  Widget _buildNavBar() {
    return Container(
      color: AppTokens.surface2(context),
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s24,
        AppTokens.s16,
        AppTokens.s24,
        AppTokens.s20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NavCircleBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            enabled: !firstQue && !isprocess,
            onTap: () {
              if (!firstQue && !isprocess) {
                _showPreviousQuestion();
              }
            },
          ),
          const SizedBox(width: AppTokens.s16),
          _NavCircleBtn(
            icon: Icons.arrow_forward_ios_rounded,
            enabled: !isprocess,
            onTap: () {
              if (!isprocess) {
                _showNextQuestion();
              }
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Legacy preserved dialog helpers
  // ==========================================================================

  void _showNotesDialog(BuildContext context, String questionId, String notes) {
    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTokens.surface(context),
            actionsPadding: EdgeInsets.zero,
            insetPadding: const EdgeInsets.symmetric(horizontal: 250),
            actions: [
              CustomBottomStickNotesWindow(
                questionId: questionId,
                notes: notes,
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return CustomBottomStickNotes(
            questionId: questionId,
            notes: notes,
          );
        },
      );
    }
  }

  void _showDialog(BuildContext context, String questionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        TextEditingController queryController = TextEditingController();
        String errorText = '';

        return AlertDialog(
          backgroundColor: AppTokens.surface(context),
          shape: RoundedRectangleBorder(borderRadius: AppTokens.radius16),
          title: Text(
            'Have a Query?',
            style: AppTokens.titleMd(context),
          ),
          content: Form(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.2,
              child: TextFormField(
                cursorColor: AppTokens.accent(context),
                controller: queryController,
                maxLines: 7,
                decoration: InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: AppTokens.accent(context)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: AppTokens.accent(context)),
                  ),
                  hintText: 'Enter your query...',
                  hintStyle: AppTokens.body(context)
                      .copyWith(color: AppTokens.muted(context)),
                ),
                style: AppTokens.body(context),
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PrimaryBtn(
                  label: 'Cancel',
                  tone: _PillTone.neutral,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AppTokens.s12),
                _PrimaryBtn(
                  label: 'Submit',
                  onTap: () {
                    String enteredText = queryController.text;
                    if (enteredText.isEmpty) {
                      setState(() {
                        errorText = 'Please enter your query';
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
          ],
        );
      },
    );
  }

  Future<void> _showBottomSheet(BuildContext context) async {
    final double? selectedFontSize = Platform.isWindows || Platform.isMacOS
        ? await showDialog<double>(
            context: context,
            builder: (BuildContext context) {
              return _FontSizeDialog(
                initial: _textSize,
                initialShow: showfontSize,
                desktop: true,
              );
            },
          )
        : await showModalBottomSheet<double>(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (BuildContext context) {
              return _FontSizeDialog(
                initial: _textSize,
                initialShow: showfontSize,
                desktop: false,
              );
            },
          );

    if (selectedFontSize != null) {
      setState(() {
        _textSize = selectedFontSize;
        showfontSize =
            (100 + ((selectedFontSize - Dimensions.fontSizeDefault) * 10));
      });
    }
  }
}

// ============================================================================
//                               Primitives
// ============================================================================

enum _StatTone { success, warning, danger }

enum _ActionTone { brand, outline }

enum _PillTone { primary, neutral }

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
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTokens.surface2(context),
            border: Border.all(color: AppTokens.border(context)),
          ),
          child: Icon(icon, size: 18, color: AppTokens.ink(context)),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.onTap,
    required this.child,
    required this.tone,
  });
  final VoidCallback onTap;
  final Widget child;
  final _ActionTone tone;

  @override
  Widget build(BuildContext context) {
    final Color bg = tone == _ActionTone.brand
        ? AppTokens.accent(context)
        : AppTokens.surface(context);
    final Color fg = tone == _ActionTone.brand
        ? Colors.white
        : AppTokens.ink(context);
    final Color border = tone == _ActionTone.brand
        ? AppTokens.accent(context)
        : AppTokens.border(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: DefaultTextStyle(
            style: AppTokens.titleSm(context).copyWith(color: fg),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _NavCircleBtn extends StatelessWidget {
  const _NavCircleBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = enabled
        ? AppTokens.accent(context)
        : AppTokens.muted(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: enabled ? onTap : null,
      child: Container(
        height: 52,
        width: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: fg),
          color: enabled
              ? AppTokens.accentSoft(context)
              : AppTokens.surface(context),
        ),
        child: Icon(icon, color: fg, size: 18),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({
    required this.label,
    required this.onTap,
    this.tone = _PillTone.primary,
  });
  final String label;
  final VoidCallback onTap;
  final _PillTone tone;

  @override
  Widget build(BuildContext context) {
    final Color bg = tone == _PillTone.primary
        ? AppTokens.accent(context)
        : AppTokens.surface2(context);
    final Color fg = tone == _PillTone.primary
        ? Colors.white
        : AppTokens.ink(context);
    return InkWell(
      borderRadius: AppTokens.radius12,
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppTokens.radius12,
          border: Border.all(color: bg),
        ),
        child: Text(
          label,
          style: AppTokens.titleSm(context).copyWith(color: fg),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final _StatTone tone;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (tone) {
      case _StatTone.success:
        bg = AppTokens.successSoft(context);
        fg = AppTokens.success(context);
        break;
      case _StatTone.danger:
        bg = AppTokens.dangerSoft(context);
        fg = AppTokens.danger(context);
        break;
      case _StatTone.warning:
        bg = AppTokens.warningSoft(context);
        fg = AppTokens.warning(context);
        break;
    }
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: fg),
        ),
        const SizedBox(width: AppTokens.s12),
        Expanded(
          child: Text(
            label,
            style: AppTokens.body(context),
          ),
        ),
        Text(
          value,
          style: AppTokens.titleMd(context),
        ),
      ],
    );
  }
}

class _FontSizeDialog extends StatefulWidget {
  const _FontSizeDialog({
    required this.initial,
    required this.initialShow,
    required this.desktop,
  });
  final double initial;
  final double initialShow;
  final bool desktop;

  @override
  State<_FontSizeDialog> createState() => _FontSizeDialogState();
}

class _FontSizeDialogState extends State<_FontSizeDialog> {
  late double currentFontSize = widget.initial;
  late double showCurrFontSize = widget.initialShow;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: AppTokens.border(context),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Container(
            padding: const EdgeInsets.all(AppTokens.s16),
            decoration: BoxDecoration(
              color: AppTokens.surface2(context),
              borderRadius: AppTokens.radius12,
              border: Border.all(color: AppTokens.border(context)),
            ),
            child: Center(
              child: Text(
                'Sample Text',
                style: AppTokens.body(context).copyWith(
                  fontSize: currentFontSize,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Font size', style: AppTokens.body(context)),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (showCurrFontSize > 50) {
                          showCurrFontSize -= 10;
                          currentFontSize -= 1;
                        }
                      });
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppTokens.ink2(context),
                  ),
                  Text(
                    '$showCurrFontSize',
                    style: AppTokens.titleSm(context),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        showCurrFontSize += 10;
                        currentFontSize += 1;
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppTokens.ink2(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PrimaryBtn(
                label: "Cancel",
                tone: _PillTone.neutral,
                onTap: () => Navigator.pop(context),
              ),
              _PrimaryBtn(
                label: "Apply",
                onTap: () => Navigator.pop(context, currentFontSize),
              ),
            ],
          ),
        ],
      ),
    );
    if (widget.desktop) {
      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 250),
        backgroundColor: AppTokens.surface(context),
        shape: RoundedRectangleBorder(borderRadius: AppTokens.radius16),
        content: body,
      );
    }
    return body;
  }
}
