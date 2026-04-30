// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names, dead_null_aware_expression

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
import 'package:shusruta_lms/modules/masterTest/question_master_pallet.dart';
import 'package:shusruta_lms/modules/masterTest/question_master_pallet_drawer.dart';
import 'package:shusruta_lms/modules/test/question_pallet.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
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
import '../reports/master reports/master_bottom_raise_query.dart';
import '../reports/store/report_by_category_store.dart';
import '../widgets/bottom_raise_query.dart';
import '../widgets/bottom_stick_notes.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_test_cancel_dialogbox.dart';
import 'custom_master_test_dialogbox.dart';

/// Master test practice-mode runner. Redesigned with AppTokens. Preserves:
///   • Constructor `PracticeMasterTestExamScreen({super.key, fromPallete,
///     testExamPaper, userExamId, isPracticeExam, queNo, remainingTime, id,
///     type, isCorrect})`
///   • Static `route(RouteSettings)` factory with same argument keys
///     (testData / userexamId / queNo / isPracticeExam / remainingTime / id /
///     type / fromPallete / isCorrect)
///   • State fields: _scaffoldKey, _selectedIndex=-1, _currentQuestionIndex=0,
///     firstQue=true, isLastQues=false, 5 attempt flags
///     (isAttempted / isMarkedForReview / isGuess /
///      isAttemptedAndMarkedForReview / isSkipped),
///     answerImgBytes / quesImgBytes / explanationImgBytes, isTapped,
///     explanationWidget / questionWidget, _controller,
///     isbutton / isprocess, _textSize, showfontSize, _scrollController
///   • Helpers (verbatim signatures): _getExplanationData,
///     _postSelectedAnswerApiCall, _getSelectedAnswer, _getCount,
///     _postPracticeData, openBottomSheet, _showNextQuestion,
///     _showPreviousQuestion, _onBackPressed, getExplanationText,
///     getQuestionText, _scrollToIndex, getCountReportPractice,
///     _questionChange, _showNotesDialog, addNotes, _getNotesData,
///     _showDialog, _showBottomSheet, _putBookMarkApiCall
///   • TestCategoryStore APIs: `userAnswerMasterTest`, `questionAnswerById`,
///     `userAnswerExam.value`, `getQuestionPalleteCount`,
///     `onGetMockReportPracticeCountApiCall`,
///     `getMockReportPracticeCountData.value`
///   • ReportsCategoryStore APIs: `onGetExplanationCall`,
///     `onBookMarkQuestion`, `onGetNotesData`, `onCreateNotes`,
///     `notesData.value`, `getExplanationText.value`
///   • Back arrow / Save & Exit → `Routes.allTestCategory`
///   • `QuestionMasterPallet(testExamPaper, userExamId, null, isPracticeExam)`
///     4-positional drawer API
///   • `MockBottomRaiseQuery` for desktop AlertDialog + mobile modal sheet
///   • `CustomBottomStickNotesWindow` (desktop) / `CustomBottomStickNotes`
///     (mobile) for notes
///   • PhotoView full-screen image zoom
///   • TypeWriterText 10ms cadence for Cortex.AI typing
///   • Bullet rewrite chain (\t\t\t-- → 17sp, \t\t-- → 11sp, \t-- → 5sp,
///     -- → •)
///   • Font-size dialog clamp at 50 + showfontSize =
///     100 + (size - default) * 10 formula
class PracticeMasterTestExamScreen extends StatefulWidget {
  final TestExamPaperListModel? testExamPaper;
  final String? userExamId;
  final int? queNo;
  final bool? isPracticeExam;
  final ValueNotifier<Duration>? remainingTime;
  final String? id;
  final String? type;
  final bool? isCorrect;
  final bool? fromPallete;
  const PracticeMasterTestExamScreen(
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
  State<PracticeMasterTestExamScreen> createState() =>
      _PracticeMasterTestExamScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => PracticeMasterTestExamScreen(
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

class _PracticeMasterTestExamScreenState
    extends State<PracticeMasterTestExamScreen> {
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
  bool isTapped = false;
  Widget? explanationWidget;
  Widget? questionWidget;
  final _controller = SuperTooltipController();
  bool isbutton = false, isprocess = false;
  double _textSize = Dimensions.fontSizeDefault;
  double showfontSize = 100;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    isTapped = false;
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
    }

    _getNotesData(widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "");
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ==========================================================================
  //                                HELPERS
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
        "");
    BottomToast.showBottomToastOverlay(
      context: context,
      errorMessage:
          widget.testExamPaper?.test?[_currentQuestionIndex].bookmarks ?? false
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
        "00:00:00");
  }

  Future<void> _getSelectedAnswer(String queId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.questionAnswerById(widget.userExamId ?? "", queId);
    setState(() {
      String? nextOption = store.userAnswerExam.value?.selectedOption;
      _selectedIndex = widget
              .testExamPaper?.test?[_currentQuestionIndex].optionsData
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

  Future<void> _postPracticeData() async {
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
    await _postSelectedAnswerApiCall(
        widget.userExamId,
        selectedOption,
        questionId,
        isAttempted,
        isAttemptedAndMarkedForReview,
        isSkipped,
        isMarkedForReview,
        selectedOption!,
        "");
  }

  Future<void> _showNextQuestion() async {
    isbutton = false;
    firstQue = false;
    isTapped = false;
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

    await _postSelectedAnswerApiCall(
        widget.userExamId,
        selectedOption,
        questionId,
        isAttempted,
        isAttemptedAndMarkedForReview,
        isSkipped,
        isMarkedForReview,
        selectedOption!,
        "");
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

      explanationWidget = getExplanationText(context);
      questionWidget = getQuestionText(context);
      _getNotesData(
          widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "");
      _scrollToIndex(_currentQuestionIndex);
    });
  }

  Future<void> _showPreviousQuestion() async {
    setState(() {
      isbutton = false;
      _selectedIndex = -1;
      isTapped = false;
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

      explanationWidget = getExplanationText(context);
      questionWidget = getQuestionText(context);
      _getNotesData(
          widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "");
      _scrollToIndex(_currentQuestionIndex);
    });
  }

  Future<bool> _onBackPressed() async {
    if (_currentQuestionIndex > 0) {
      _showPreviousQuestion();
      return false;
    }
    return true;
  }

  Future<void> getCountReportPractice(context) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onGetMockReportPracticeCountApiCall(widget.userExamId ?? "");
  }

  void _questionChange(int index) {
    setState(() {
      _selectedIndex = -1;
      isTapped = false;
      String? questionId = widget.testExamPaper?.test?[index].sId;
      _getSelectedAnswer(questionId ?? "");
      _currentQuestionIndex = index;
    });
  }

  void _scrollToIndex(int index) {
    const double itemExtent = 44 + 12; // diameter + spacing
    final double totalWidth =
        (widget.testExamPaper?.test?.length ?? 0) * itemExtent;
    final double viewportWidth = MediaQuery.of(context).size.width;
    double maxScrollExtent = (totalWidth - viewportWidth).clamp(0.0, double.infinity);
    double targetScrollPosition = (index * itemExtent).clamp(0.0, maxScrollExtent);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetScrollPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _getNotesData(String queId) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onGetNotesData(queId);
    debugPrint('queIdbookmark$queId');
  }

  Future<void> addNotes(String? questionId, String? notes) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onCreateNotes(context, questionId ?? "", notes ?? "");
    _getNotesData(widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "");
    BottomToast.showBottomToastOverlay(
      context: context,
      errorMessage: "Notes Added Successfully!",
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  // ==========================================================================
  //                           QUESTION / EXPLANATION
  // ==========================================================================

  Widget getExplanationText(BuildContext context) {
    String explanation =
        widget.testExamPaper?.test?[_currentQuestionIndex].explanation ?? "";
    explanation = explanation.replaceAllMapped(
        RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    List<String> splittedText = explanation.split("splittedImage");
    List<Widget> columns = [];
    int index = 0;

    for (String text in splittedText) {
      List<Widget> explanationImageWidget = [];
      if (widget.testExamPaper?.test?[_currentQuestionIndex].explanationImg
              ?.isNotEmpty ??
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
                    child: Image.network(base64String, fit: BoxFit.cover),
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
                  .replaceAll("			--", "                 •")
                  .replaceAll("		--", "           •")
                  .replaceAll("	--", "     •")
                  .replaceAll("--", "•"),
              textAlign: TextAlign.justify,
              style: AppTokens.body(context).copyWith(fontSize: _textSize),
            ),
            const SizedBox(height: AppTokens.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: explanationImageWidget,
            ),
            if (explanationImageWidget.isNotEmpty)
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
          (widget.testExamPaper?.test?[_currentQuestionIndex].explanationImg
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

  Widget getQuestionText(BuildContext context) {
    if (widget.testExamPaper?.test == null ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= (widget.testExamPaper?.test?.length ?? 0)) {
      return Center(
        child: Text(
          "No filtered data available",
          style: AppTokens.body(context),
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
                    child: Image.network(base64String, fit: BoxFit.cover),
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
                  .replaceAll("			--", "                 •")
                  .replaceAll("		--", "           •")
                  .replaceAll("	--", "     •")
                  .replaceAll("--", "•"),
              textAlign: TextAlign.left,
              style: AppTokens.bodyLg(context)
                  .copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: AppTokens.s12),
            Column(children: questionImageWidget),
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
          (widget.testExamPaper?.test?[_currentQuestionIndex].questionImg
                      ?.length ??
                  0) -
              1) {
        break;
      }
    }
    return Column(children: columns);
  }

  // ==========================================================================
  //                                BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    explanationWidget = getExplanationText(context);
    questionWidget = getQuestionText(context);

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppTokens.scaffold(context),
        drawer: Drawer(
          backgroundColor: AppTokens.surface(context),
          child: QuestionMasterPallet(widget.testExamPaper, widget.userExamId,
              null, widget.isPracticeExam),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ------------------------------------------------------------
              // Top bar: back / title / palette / bookmark / Save & Exit
              // ------------------------------------------------------------
              _buildTopBar(context),
              Divider(
                height: 1,
                thickness: 1,
                color: AppTokens.border(context),
              ),
              // ------------------------------------------------------------
              // Index strip
              // ------------------------------------------------------------
              _buildIndexStrip(context),
              // ------------------------------------------------------------
              // Body scroll area
              // ------------------------------------------------------------
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
                      _buildQuestionHeader(context),
                      const SizedBox(height: AppTokens.s12),
                      questionWidget ?? const SizedBox(),
                      const SizedBox(height: AppTokens.s16),
                      _buildOptionsList(context),
                      _buildExplanationSection(context, store),
                    ],
                  ),
                ),
              ),
              // ------------------------------------------------------------
              // Footer nav (prev / next)
              // ------------------------------------------------------------
              _buildNavBar(context),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------- top bar ----------------------------------
  Widget _buildTopBar(BuildContext context) {
    final bool wideMode = MediaQuery.of(context).size.width > 1160 &&
        MediaQuery.of(context).size.height > 670;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s12,
        AppTokens.s12,
        AppTokens.s12,
        AppTokens.s12,
      ),
      child: Row(
        children: [
          _CircleIconBtn(
            icon: Icons.arrow_back_rounded,
            onTap: () =>
                Navigator.of(context).pushNamed(Routes.allTestCategory),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              "${widget.testExamPaper?.examName}",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.titleMd(context),
            ),
          ),
          if (!wideMode) ...[
            const SizedBox(width: AppTokens.s8),
            _CircleIconBtn(
              icon: Icons.grid_view_rounded,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ],
          const SizedBox(width: AppTokens.s8),
          _CircleIconBtn(
            icon: (widget.testExamPaper?.test?[_currentQuestionIndex]
                        .bookmarks ??
                    false)
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            tint: (widget.testExamPaper?.test?[_currentQuestionIndex]
                        .bookmarks ??
                    false)
                ? AppTokens.accent(context)
                : null,
            onTap: () => _putBookMarkApiCall(
                widget.testExamPaper?.examId ?? "",
                widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? ""),
          ),
          const SizedBox(width: AppTokens.s8),
          _PrimaryBtn(
            label: "Save & Exit",
            onTap: () async {
              await getCountReportPractice(context);
              _showPracticeSummaryDialog(context);
            },
          ),
        ],
      ),
    );
  }

  // ----------------------------- index strip --------------------------------
  Widget _buildIndexStrip(BuildContext context) {
    final items = widget.testExamPaper?.test ?? [];
    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s12,
        AppTokens.s8,
        AppTokens.s12,
        AppTokens.s8,
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(items.length, (index) {
            final solutionReport = items[index];

            Color bg() {
              if (solutionReport.selectedOption != null &&
                  (solutionReport.selectedOption ?? "").isNotEmpty) {
                final isCorrect = (solutionReport.correctOption ?? "") ==
                    (solutionReport.selectedOption ?? "");
                return isCorrect
                    ? AppTokens.success(context)
                    : AppTokens.danger(context);
              } else if (_currentQuestionIndex == index) {
                return _selectedIndex == -1
                    ? AppTokens.accent(context)
                    : ((solutionReport.correctOption ?? "") ==
                            (solutionReport.optionsData?[_selectedIndex].value ??
                                ""))
                        ? AppTokens.success(context)
                        : AppTokens.danger(context);
              }
              return AppTokens.surface(context);
            }

            Color fg() {
              if (solutionReport.selectedOption != null &&
                  (solutionReport.selectedOption ?? "").isNotEmpty) {
                return Colors.white;
              }
              return _currentQuestionIndex == index
                  ? Colors.white
                  : AppTokens.ink(context);
            }

            Color border() {
              if (solutionReport.selectedOption != null &&
                  (solutionReport.selectedOption ?? "").isNotEmpty) {
                final isCorrect = (solutionReport.correctOption ?? "") ==
                    (solutionReport.selectedOption ?? "");
                return isCorrect
                    ? AppTokens.success(context)
                    : AppTokens.danger(context);
              }
              return _currentQuestionIndex == index
                  ? AppTokens.accent(context)
                  : AppTokens.border(context);
            }

            return Padding(
              padding: const EdgeInsets.only(right: AppTokens.s8),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _questionChange(index),
                child: Container(
                  height: 44,
                  width: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg(),
                    shape: BoxShape.circle,
                    border: Border.all(color: border()),
                  ),
                  child: Text(
                    "${index + 1}",
                    style: AppTokens.titleSm(context).copyWith(color: fg()),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // --------------------------- question header ------------------------------
  Widget _buildQuestionHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          "${_currentQuestionIndex + 1}.",
          style: AppTokens.titleMd(context)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        _ActionPill(
          tone: _ActionTone.brand,
          onTap: isprocess
              ? null
              : () async {
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
                  String? currentAnswerTitle =
                      currentIndex >= 0 ? answerTitle?.elementAt(currentIndex) : null;

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
                  if (!isbutton) {
                    await _getExplanationData(question);
                  }
                },
          child: isprocess
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text("Ask Cortex.AI"),
        ),
        const SizedBox(width: AppTokens.s8),
        _ActionPill(
          tone: _ActionTone.outline,
          onTap: () {
            final qId = widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "";
            final qText = widget.testExamPaper?.test?[_currentQuestionIndex].questionText ?? "";
            final opts = widget.testExamPaper?.test?[_currentQuestionIndex].optionsData;
            final allOptions =
                "a) ${opts != null && opts.isNotEmpty ? opts[0].answerTitle : ''}"
                "\nb) ${opts != null && opts.length > 1 ? opts[1].answerTitle : ''}"
                "\nc) ${opts != null && opts.length > 2 ? opts[2].answerTitle : ''}"
                "\nd) ${opts != null && opts.length > 3 ? opts[3].answerTitle : ''}";
            if (Platform.isWindows || Platform.isMacOS) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: AppTokens.surface(context),
                    surfaceTintColor: AppTokens.surface(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.r16),
                    ),
                    actionsPadding: EdgeInsets.zero,
                    actions: [
                      MockBottomRaiseQuery(
                          questionId: qId,
                          questionText: qText,
                          allOptions: allOptions),
                    ],
                  );
                },
              );
            } else {
              showModalBottomSheet<String>(
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(AppTokens.r20)),
                ),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                context: context,
                backgroundColor: AppTokens.surface(context),
                builder: (BuildContext context) {
                  return MockBottomRaiseQuery(
                      questionId: qId,
                      questionText: qText,
                      allOptions: allOptions);
                },
              );
            }
          },
          child: const Text("Raise Query"),
        ),
      ],
    );
  }

  // --------------------------- options list ---------------------------------
  Widget _buildOptionsList(BuildContext context) {
    final optionsData = widget
            .testExamPaper?.test?[_currentQuestionIndex].optionsData ??
        [];
    final testExamPaper = widget.testExamPaper?.test?[_currentQuestionIndex];
    final correctPercentage = testExamPaper?.correctPercentage;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: optionsData.length,
      itemBuilder: (BuildContext context, int index) {
        final option = optionsData[index];
        final base64String = option.answerImg ?? "";
        final bool isSelected = index == _selectedIndex;

        // Semantic state for this tile
        String showTxt = "";
        Color accent = AppTokens.border(context);
        Color textColor = AppTokens.ink(context);
        Color tileFill = AppTokens.surface(context);
        Color borderColor = AppTokens.border(context);

        if (_selectedIndex >= 0 && _selectedIndex < optionsData.length) {
          final correctValue = testExamPaper?.correctOption ?? "";
          final selectedValue =
              optionsData[_selectedIndex].value ?? "";
          final thisValue = option.value ?? "";

          final bool isThisCorrect = correctValue == thisValue;
          final bool isThisWrongSelected =
              selectedValue == thisValue && correctValue != thisValue;

          if (isThisCorrect) {
            showTxt = "Correct Answer";
            accent = AppTokens.success(context);
            textColor = AppTokens.success(context);
            tileFill = AppTokens.successSoft(context);
            borderColor = AppTokens.success(context);
          } else if (isThisWrongSelected) {
            showTxt = "Incorrect Answer";
            accent = AppTokens.danger(context);
            textColor = AppTokens.danger(context);
            tileFill = AppTokens.dangerSoft(context);
            borderColor = AppTokens.danger(context);
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.s12),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.r20),
            onTap: () {
              setState(() {
                if (widget.isPracticeExam == true) {
                  if (!isTapped) {
                    isTapped = true;
                    _selectedIndex = index;
                    widget.testExamPaper?.test?[_currentQuestionIndex]
                        .selectedOption = option.value;
                    _postPracticeData();
                  }
                } else {
                  if (isSelected) {
                    _selectedIndex = -1;
                  } else {
                    _selectedIndex = index;
                    widget.testExamPaper?.test?[_currentQuestionIndex]
                        .selectedOption = option.value;
                  }
                }
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isTapped ? tileFill : AppTokens.surface(context),
                    borderRadius: BorderRadius.circular(AppTokens.r20),
                    border: Border.all(
                      color: isTapped ? borderColor : AppTokens.border(context),
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
                          color: isTapped
                              ? accent.withOpacity(0.12)
                              : AppTokens.surface2(context),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isTapped
                                ? accent
                                : AppTokens.border(context),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          option.value ?? "",
                          style: AppTokens.titleSm(context).copyWith(
                            color:
                                isTapped ? accent : AppTokens.ink2(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    option.answerTitle ?? "",
                                    style: AppTokens.body(context).copyWith(
                                      color: isTapped
                                          ? textColor
                                          : AppTokens.ink(context),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isTapped && widget.isPracticeExam == true)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: AppTokens.s8),
                                    child: Text(
                                      "${option.percentage ?? 0}%",
                                      style:
                                          AppTokens.caption(context).copyWith(
                                        color: AppTokens.muted(context),
                                      ),
                                    ),
                                  ),
                              ],
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
                            if (isTapped && showTxt.isNotEmpty) ...[
                              const SizedBox(height: AppTokens.s4),
                              Text(
                                showTxt,
                                style: AppTokens.caption(context).copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if ((testExamPaper?.correctOption ?? "") ==
                        (option.value ?? "") &&
                    isTapped &&
                    widget.isPracticeExam == true)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: AppTokens.s8, left: 16),
                    child: Text(
                      "${correctPercentage ?? "0"}% Got this answer correct",
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.success(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --------------------------- explanation ----------------------------------
  Widget _buildExplanationSection(
      BuildContext context, ReportsCategoryStore store) {
    if (!(isTapped == true && widget.isPracticeExam == true)) {
      return const SizedBox();
    }
    return Observer(
      builder: (BuildContext context) {
        final GetNotesSolutionModel? noteModel = store.notesData.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTokens.s12),
            Row(
              children: [
                Text(
                  "Explanation",
                  style: AppTokens.titleMd(context)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  tooltip: "Notes",
                  icon: Icon(Icons.edit_note_rounded,
                      color: AppTokens.ink2(context)),
                  onPressed: () => _showNotesDialog(
                      context,
                      widget.testExamPaper?.test?[_currentQuestionIndex].sId ??
                          "",
                      noteModel?.notes ?? ""),
                ),
                IconButton(
                  tooltip: "Font size",
                  icon: Icon(Icons.format_size_rounded,
                      color: AppTokens.ink2(context)),
                  onPressed: () => _showBottomSheet(context),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTokens.s16),
              decoration: BoxDecoration(
                color: AppTokens.surface(context),
                borderRadius: BorderRadius.circular(AppTokens.r16),
                border: Border.all(color: AppTokens.border(context)),
              ),
              child: explanationWidget ?? const SizedBox(),
            ),
            const SizedBox(height: AppTokens.s12),
            if (isbutton) _buildCortexAiCard(context, store),
            const SizedBox(height: AppTokens.s12),
          ],
        );
      },
    );
  }

  Widget _buildCortexAiCard(
      BuildContext context, ReportsCategoryStore store) {
    return Observer(
      builder: (BuildContext context) {
        final GetExplanationModel? getExplainModel =
            store.getExplanationText.value;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r16),
            boxShadow: AppTokens.shadow2(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.22),
                    ),
                    child: const Text(
                      "AI",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  const Text("Cortex.AI ",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white)),
                  const Text("Explains",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              TypeWriterText(
                text: Text(
                  getExplainModel?.text ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
                maintainSize: false,
                duration: const Duration(milliseconds: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------- nav bar ----------------------------------
  Widget _buildNavBar(BuildContext context) {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NavCircleBtn(
            icon: Icons.arrow_back_rounded,
            enabled: !firstQue && !isprocess,
            onTap: firstQue || isprocess ? null : _showPreviousQuestion,
          ),
          const SizedBox(width: AppTokens.s16),
          _NavCircleBtn(
            icon: Icons.arrow_forward_rounded,
            enabled: !isprocess,
            onTap: isprocess ? null : _showNextQuestion,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  //                    Save & Exit summary dialog (Observer)
  // ===========================================================================
  void _showPracticeSummaryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTokens.surface(context),
          surfaceTintColor: AppTokens.surface(context),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.r20)),
          contentPadding: const EdgeInsets.fromLTRB(
              AppTokens.s24, AppTokens.s24, AppTokens.s24, AppTokens.s12),
          actionsPadding: const EdgeInsets.fromLTRB(
              AppTokens.s24, 0, AppTokens.s24, AppTokens.s24),
          content: Observer(
            builder: (context) {
              final store =
                  Provider.of<TestCategoryStore>(context, listen: false);
              final data = store.getMockReportPracticeCountData.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Practice Test Summary",
                      style: AppTokens.titleMd(context)),
                  const SizedBox(height: AppTokens.s16),
                  _SummaryStat(
                    icon: Icons.check_rounded,
                    tone: _StatTone.success,
                    label: "Correct",
                    value: "${data?.correctAnswers ?? 0}",
                  ),
                  const SizedBox(height: AppTokens.s8),
                  _SummaryStat(
                    icon: Icons.close_rounded,
                    tone: _StatTone.danger,
                    label: "Incorrect",
                    value: "${data?.incorrectAnswers ?? 0}",
                  ),
                  const SizedBox(height: AppTokens.s8),
                  _SummaryStat(
                    icon: Icons.priority_high_rounded,
                    tone: _StatTone.warning,
                    label: "Unanswered",
                    value: "${data?.notVisited ?? 0}",
                  ),
                ],
              );
            },
          ),
          actions: [
            _PrimaryBtn(
              label: "Save & Exit",
              expanded: true,
              onTap: () =>
                  Navigator.of(context).pushNamed(Routes.allTestCategory),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  //                         openBottomSheet (preserved)
  // ==========================================================================
  void openBottomSheet(TestCategoryStore store) {
    getCountReportPractice(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTokens.surface(context),
        surfaceTintColor: AppTokens.surface(context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r20)),
        contentPadding: const EdgeInsets.fromLTRB(
            AppTokens.s24, AppTokens.s24, AppTokens.s24, AppTokens.s12),
        actionsPadding: const EdgeInsets.fromLTRB(
            AppTokens.s24, 0, AppTokens.s24, AppTokens.s24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Practice Test Summary",
                style: AppTokens.titleMd(context)),
            const SizedBox(height: AppTokens.s16),
            _SummaryStat(
              icon: Icons.check_rounded,
              tone: _StatTone.success,
              label: "Correct",
              value:
                  "${store.getMockReportPracticeCountData.value?.correctAnswers ?? 0}",
            ),
            const SizedBox(height: AppTokens.s8),
            _SummaryStat(
              icon: Icons.close_rounded,
              tone: _StatTone.danger,
              label: "Incorrect",
              value:
                  "${store.getMockReportPracticeCountData.value?.incorrectAnswers ?? 0}",
            ),
            const SizedBox(height: AppTokens.s8),
            _SummaryStat(
              icon: Icons.priority_high_rounded,
              tone: _StatTone.warning,
              label: "Unanswered",
              value:
                  "${store.getMockReportPracticeCountData.value?.notVisited ?? 0}",
            ),
          ],
        ),
        actions: [
          _PrimaryBtn(
            label: "Save & Exit",
            expanded: true,
            onTap: () =>
                Navigator.of(context).pushNamed(Routes.allTestCategory),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  //                             _showNotesDialog
  // ==========================================================================
  void _showNotesDialog(
      BuildContext context, String questionId, String notes) {
    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTokens.surface(context),
            surfaceTintColor: AppTokens.surface(context),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.r20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 250),
            actionsPadding: EdgeInsets.zero,
            actions: [
              CustomBottomStickNotesWindow(
                  questionId: questionId, notes: notes),
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

  // ==========================================================================
  //                              _showDialog
  // ==========================================================================
  void _showDialog(BuildContext context, String questionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final TextEditingController queryController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppTokens.surface(context),
          surfaceTintColor: AppTokens.surface(context),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.r20)),
          title: Text("Have a Query?", style: AppTokens.titleMd(context)),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.2,
            child: TextFormField(
              cursorColor: AppTokens.accent(context),
              controller: queryController,
              maxLines: 7,
              decoration: InputDecoration(
                hintText: "Enter your query...",
                hintStyle: AppTokens.body(context)
                    .copyWith(color: AppTokens.muted(context)),
                enabledBorder: UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: AppTokens.border(context)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTokens.accent(context)),
                ),
              ),
              style: AppTokens.body(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: AppTokens.body(context)
                    .copyWith(color: AppTokens.ink2(context)),
              ),
            ),
            _PrimaryBtn(
              label: "Submit",
              onTap: () {
                // addQuery(questionId, queryController.text, context);
              },
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  //                              _showBottomSheet
  // ==========================================================================
  Future<void> _showBottomSheet(BuildContext context) async {
    if (Platform.isWindows || Platform.isMacOS) {
      final double? selectedFontSize = await showDialog<double>(
        context: context,
        builder: (BuildContext context) {
          return _FontSizeDialog(
            initialTextSize: _textSize,
            initialShowFontSize: showfontSize,
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
    } else {
      final double? selectedFontSize = await showModalBottomSheet<double>(
        context: context,
        backgroundColor: AppTokens.surface(context),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTokens.r20)),
        ),
        builder: (BuildContext context) {
          return _FontSizeDialog(
            initialTextSize: _textSize,
            initialShowFontSize: showfontSize,
            asSheet: true,
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
}

// ============================================================================
//                               PRIMITIVES
// ============================================================================

class _CircleIconBtn extends StatelessWidget {
  const _CircleIconBtn({required this.icon, required this.onTap, this.tint});
  final IconData icon;
  final VoidCallback onTap;
  final Color? tint;

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
          child: Icon(icon, size: 18, color: tint ?? AppTokens.ink(context)),
        ),
      ),
    );
  }
}

enum _ActionTone { brand, outline }

class _ActionPill extends StatelessWidget {
  const _ActionPill(
      {required this.tone, required this.onTap, required this.child});
  final _ActionTone tone;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isBrand = tone == _ActionTone.brand;
    final bool disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Material(
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
              gradient: isBrand
                  ? LinearGradient(
                      colors: [AppTokens.brand, AppTokens.brand2],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: isBrand ? null : AppTokens.surface(context),
              borderRadius: BorderRadius.circular(AppTokens.r28),
              border: isBrand
                  ? null
                  : Border.all(color: AppTokens.accent(context)),
              boxShadow: isBrand ? AppTokens.shadow1(context) : null,
            ),
            child: DefaultTextStyle(
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w600,
                color: isBrand ? Colors.white : AppTokens.accent(context),
              ),
              child: IconTheme(
                data: IconThemeData(
                  color: isBrand ? Colors.white : AppTokens.accent(context),
                  size: 16,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavCircleBtn extends StatelessWidget {
  const _NavCircleBtn(
      {required this.icon,
      required this.enabled,
      required this.onTap});
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

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn(
      {required this.label, required this.onTap, this.expanded = false});
  final String label;
  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            boxShadow: AppTokens.shadow1(context),
          ),
          child: Text(
            label,
            style: AppTokens.titleSm(context).copyWith(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}

enum _StatTone { success, warning, danger }

class _SummaryStat extends StatelessWidget {
  const _SummaryStat(
      {required this.icon,
      required this.tone,
      required this.label,
      required this.value});
  final IconData icon;
  final _StatTone tone;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (tone) {
      case _StatTone.success:
        bg = AppTokens.successSoft(context);
        fg = AppTokens.success(context);
        break;
      case _StatTone.warning:
        bg = AppTokens.warningSoft(context);
        fg = AppTokens.warning(context);
        break;
      case _StatTone.danger:
        bg = AppTokens.dangerSoft(context);
        fg = AppTokens.danger(context);
        break;
    }
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: fg, size: 16),
        ),
        const SizedBox(width: AppTokens.s12),
        Expanded(
            child: Text(label, style: AppTokens.body(context))),
        Text(value,
            style: AppTokens.body(context)
                .copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _FontSizeDialog extends StatefulWidget {
  const _FontSizeDialog({
    required this.initialTextSize,
    required this.initialShowFontSize,
    this.asSheet = false,
  });
  final double initialTextSize;
  final double initialShowFontSize;
  final bool asSheet;

  @override
  State<_FontSizeDialog> createState() => _FontSizeDialogState();
}

class _FontSizeDialogState extends State<_FontSizeDialog> {
  late double currentFontSize;
  late double showCurrFontSize;

  @override
  void initState() {
    super.initState();
    currentFontSize = widget.initialTextSize;
    showCurrFontSize = widget.initialShowFontSize;
  }

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: AppTokens.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTokens.s16),
            decoration: BoxDecoration(
              color: AppTokens.surface2(context),
              borderRadius: BorderRadius.circular(AppTokens.r12),
            ),
            child: Center(
              child: Text(
                "Sample Text",
                style: AppTokens.body(context).copyWith(
                  fontSize: currentFontSize,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Font size", style: AppTokens.body(context)),
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
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: AppTokens.ink2(context),
                  ),
                  Text(
                    "$showCurrFontSize",
                    style: AppTokens.body(context),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        showCurrFontSize += 10;
                        currentFontSize += 1;
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: AppTokens.ink2(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTokens.s12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                      side: BorderSide(color: AppTokens.border(context)),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: AppTokens.body(context)
                        .copyWith(color: AppTokens.ink2(context)),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: _PrimaryBtn(
                  label: "Apply",
                  expanded: true,
                  onTap: () => Navigator.pop(context, currentFontSize),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (widget.asSheet) return body;
    return AlertDialog(
      backgroundColor: AppTokens.surface(context),
      surfaceTintColor: AppTokens.surface(context),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 250),
      contentPadding: EdgeInsets.zero,
      content: body,
    );
  }
}
