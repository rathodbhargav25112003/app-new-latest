// ignore_for_file: use_super_parameters, deprecated_member_use, use_build_context_synchronously, unused_import, unused_field, unused_element, unused_local_variable, duplicate_ignore, unrelated_type_equality_checks, dead_null_aware_expression

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
import 'package:shusruta_lms/modules/widgets/bottom_stick_notes_window.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:typewritertext/typewritertext.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/get_all_my_custom_test_model.dart';
import '../../models/get_explanation_model.dart';
import '../../models/get_notes_solution_model.dart';
import '../reports/store/report_by_category_store.dart';
import '../widgets/bottom_raise_query.dart';
import '../widgets/bottom_stick_notes.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_test_cancel_dialogbox.dart';
import 'custom_question_pallet.dart';
import 'custom_test_bottom_raise_query.dart';

class PracticeCustomTestExamScreen extends StatefulWidget {
  final Data? testExamPaper;
  final String? userExamId;
  final int? queNo;
  final bool? isPracticeExam;
  final ValueNotifier<Duration>? remainingTime;
  final String? id;
  final String? type;
  final bool? isCorrect;
  final bool? fromPallete;
  const PracticeCustomTestExamScreen(
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
  State<PracticeCustomTestExamScreen> createState() =>
      _PracticeCustomTestExamScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => PracticeCustomTestExamScreen(
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

class _PracticeCustomTestExamScreenState
    extends State<PracticeCustomTestExamScreen> {
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
      String? nextOption = store.userCustomAnswerExam.value?.selectedOption;
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
    await store.getCustomTestQuestionPalleteCount(userExamId ?? "").then((_) {
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

  void openBottomSheet(TestCategoryStore store) {
    getCountReportPractice(context);
    showDialog(
      context: context,
      builder: (context) => _PracticeSummaryDialog(store: store),
    );
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
    } else {
      return true;
    }
  }

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
              _ZoomableNetworkImage(url: base64String),
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
              style: AppTokens.body(context).copyWith(
                fontSize: _textSize,
                color: AppTokens.ink(context),
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: explanationImageWidget,
            ),
            if (explanationImageWidget.isNotEmpty) ...[
              const SizedBox(height: AppTokens.s8),
              Text(
                "Tap the image to zoom In / Out",
                style: AppTokens.caption(context),
              ),
            ],
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
            questionImageWidget.add(_ZoomableNetworkImage(url: base64String));
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
              style: AppTokens.titleSm(context).copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: AppTokens.ink(context),
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: questionImageWidget,
            ),
            if (questionImageWidget.isNotEmpty) ...[
              const SizedBox(height: AppTokens.s8),
              Text(
                "Tap the image to zoom In / Out",
                style: AppTokens.caption(context),
              ),
            ],
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

  void _scrollToIndex(int index) {
    double totalWidth = (widget.testExamPaper?.test?.length ?? 0) *
        (Dimensions.PADDING_SIZE_SMALL * 2.675 +
            Dimensions.PADDING_SIZE_SMALL * 1.7);
    double viewportWidth = MediaQuery.of(context).size.width;
    double maxScrollExtent = totalWidth - viewportWidth;
    maxScrollExtent = maxScrollExtent.clamp(0.0, double.infinity);
    double targetScrollPosition = index *
        (Dimensions.PADDING_SIZE_SMALL * 2.675 +
            Dimensions.PADDING_SIZE_SMALL * 1.7);
    targetScrollPosition = targetScrollPosition.clamp(0.0, maxScrollExtent);

    _scrollController.animateTo(
      targetScrollPosition,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> getCountReportPractice(context) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onGetCustomReportPracticeCountApiCall(widget.userExamId ?? "");
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

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    final store2 = Provider.of<TestCategoryStore>(context, listen: false);
    explanationWidget = getExplanationText(context);
    questionWidget = getQuestionText(context);

    final testData = widget.testExamPaper?.test?[_currentQuestionIndex];
    final totalQuestions = widget.testExamPaper?.test?.length ?? 0;

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppTokens.scaffold(context),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PracticeHeader(
                onBack: () =>
                    Navigator.of(context).pushNamed(Routes.testCategory),
                onPalletTap: () => _scaffoldKey.currentState?.openDrawer(),
                onSaveExit: () async {
                  await getCountReportPractice(context);
                  showDialog(
                    context: context,
                    builder: (context) =>
                        _PracticeSummaryDialog(store: store2),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTokens.s16, AppTokens.s12, AppTokens.s16, AppTokens.s8),
                child: _QuestionPager(
                  controller: _scrollController,
                  count: totalQuestions,
                  currentIndex: _currentQuestionIndex,
                  selectedIndex: _selectedIndex,
                  testData: widget.testExamPaper?.test ?? [],
                  onTap: (i) => _questionChange(i),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTokens.s16),
                child: _QuestionActionsRow(
                  questionNumber: _currentQuestionIndex + 1,
                  isProcessing: isprocess,
                  onAskCortex: () async {
                    if (!isbutton) {
                      setState(() {
                        isprocess = true;
                      });
                    }
                    TestData? solutionReport =
                        widget.testExamPaper?.test?[_currentQuestionIndex];
                    final questionText = solutionReport?.questionText;
                    final currentOption = solutionReport?.correctOption;
                    final answerTitle = solutionReport?.optionsData
                        ?.map((e) => e.answerTitle);
                    int currentIndex = solutionReport?.optionsData
                            ?.indexWhere((e) => e.value == currentOption) ??
                        -1;
                    String? currentAnswerTitle =
                        answerTitle?.elementAt(currentIndex);
                    List<String?> notMatchingAnswerTitles = answerTitle
                            ?.where((title) => title != currentAnswerTitle)
                            .toList() ??
                        [];
                    String concatenatedTitles = notMatchingAnswerTitles
                        .where((title) => title != null)
                        .join(", ");
                    String question =
                        "Explain why $currentAnswerTitle is the answer to the Question $questionText and why the remaining $concatenatedTitles are not correct answer";
                    if (!isbutton) {
                      await _getExplanationData(question);
                    }
                  },
                  onRaiseQuery: () {
                    showModalBottomSheet<String>(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppTokens.r28),
                        ),
                      ),
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      context: context,
                      backgroundColor: AppTokens.surface(context),
                      builder: (BuildContext context) {
                        return CustomTestBottomRaiseQuery(
                          questionId: widget.testExamPaper
                                  ?.test?[_currentQuestionIndex].sId ??
                              "",
                          questionText: widget
                                  .testExamPaper
                                  ?.test?[_currentQuestionIndex]
                                  .questionText ??
                              '',
                          allOptions:
                              "a) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[0].answerTitle}\nb) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[1].answerTitle}\nc) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[2].answerTitle}\nd) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[3].answerTitle}",
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppTokens.s16, 0,
                      AppTokens.s16, AppTokens.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTokens.s16),
                        decoration: AppTokens.cardDecoration(context),
                        child: questionWidget ?? const SizedBox(),
                      ),
                      const SizedBox(height: AppTokens.s16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: testData?.optionsData?.length ?? 0,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTokens.s12),
                        itemBuilder: (BuildContext context, int index) {
                          final option = testData?.optionsData?[index];
                          final isSelected = index == _selectedIndex;
                          final correctValue = testData?.correctOption ?? "";
                          final thisValue = option?.value ?? "";
                          String selectedValue = "";
                          if (_selectedIndex >= 0 &&
                              _selectedIndex <
                                  (testData?.optionsData?.length ?? 0)) {
                            selectedValue = testData
                                    ?.optionsData?[_selectedIndex].value ??
                                "";
                          }
                          _OptionState state = _OptionState.neutral;
                          if (isTapped) {
                            if (thisValue == correctValue) {
                              state = _OptionState.correct;
                            } else if (thisValue == selectedValue) {
                              state = _OptionState.incorrect;
                            }
                          }
                          return _OptionCard(
                            label: option?.value ?? "",
                            title: option?.answerTitle ?? "",
                            imageUrl: option?.answerImg ?? "",
                            selected: isSelected,
                            state: state,
                            onTap: () {
                              setState(() {
                                if (widget.isPracticeExam == true) {
                                  if (!isTapped) {
                                    isTapped = true;
                                    _selectedIndex = index;
                                    widget
                                            .testExamPaper
                                            ?.test?[_currentQuestionIndex]
                                            .selectedOption =
                                        option?.value;
                                    _postPracticeData();
                                  }
                                } else {
                                  if (isSelected) {
                                    _selectedIndex = -1;
                                  } else {
                                    _selectedIndex = index;
                                    widget
                                            .testExamPaper
                                            ?.test?[_currentQuestionIndex]
                                            .selectedOption =
                                        option?.value;
                                  }
                                }
                              });
                            },
                          );
                        },
                      ),
                      if (isTapped && widget.isPracticeExam == true)
                        Observer(builder: (BuildContext context) {
                          GetNotesSolutionModel? noteModel =
                              store.notesData.value;
                          return Padding(
                            padding:
                                const EdgeInsets.only(top: AppTokens.s20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ExplanationHeader(
                                  onNotes: () => _showNotesDialog(
                                      context,
                                      widget
                                              .testExamPaper
                                              ?.test?[_currentQuestionIndex]
                                              .sId ??
                                          "",
                                      noteModel?.notes ?? ""),
                                  onFont: () => _showBottomSheet(context),
                                ),
                                const SizedBox(height: AppTokens.s12),
                                Container(
                                  padding:
                                      const EdgeInsets.all(AppTokens.s16),
                                  decoration:
                                      AppTokens.cardDecoration(context),
                                  child: explanationWidget ??
                                      const SizedBox(),
                                ),
                                if (isbutton)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: AppTokens.s16),
                                    child: Observer(
                                      builder: (BuildContext context) {
                                        GetExplanationModel?
                                            getExplainModel = store
                                                .getExplanationText.value;
                                        return _CortexAIPanel(
                                          text:
                                              getExplainModel?.text ?? '',
                                        );
                                      },
                                    ),
                                  ),
                                const SizedBox(height: AppTokens.s12),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              _BottomNavBar(
                firstQue: firstQue,
                disabled: isprocess,
                onPrev: firstQue ? null : _showPreviousQuestion,
                onNext: _showNextQuestion,
              ),
            ],
          ),
        ),
        drawer: Drawer(
          backgroundColor: AppTokens.surface(context),
          child: CustomTestQuestionPallet(widget.testExamPaper,
              widget.userExamId, null, widget.isPracticeExam, null),
        ),
      ),
    );
  }

  void _showNotesDialog(
      BuildContext context, String questionId, String notes) {
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

  Future<void> _getNotesData(String queId) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onGetNotesData(queId);
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
          shape: const RoundedRectangleBorder(borderRadius: AppTokens.radius16),
          title: Text('Have a Query?', style: AppTokens.titleMd(context)),
          content: Form(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.2,
              child: TextFormField(
                cursorColor: AppTokens.accent(context),
                controller: queryController,
                maxLines: 7,
                decoration: AppTokens.inputDecoration(
                  context,
                  hint: 'Enter your query...',
                ),
                style: AppTokens.body(context),
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DialogBtn(
                  label: 'Cancel',
                  background: AppTokens.surface3(context),
                  foreground: AppTokens.ink(context),
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AppTokens.s12),
                _DialogBtn(
                  label: 'Submit',
                  background: AppTokens.accent(context),
                  foreground: Colors.white,
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
            backgroundColor: AppTokens.surface(context),
            shape: const RoundedRectangleBorder(
                borderRadius: AppTokens.radius16),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return _FontSizePanel(
                  currentFontSize: currentFontSize,
                  showFontSize: showCurrFontSize,
                  onDec: () {
                    setModalState(() {
                      if (showCurrFontSize > 50) {
                        showCurrFontSize -= 10;
                        currentFontSize -= 1;
                      }
                    });
                  },
                  onInc: () {
                    setModalState(() {
                      showCurrFontSize += 10;
                      currentFontSize += 1;
                    });
                  },
                  onCancel: () => Navigator.pop(context),
                  onApply: () => Navigator.pop(context, currentFontSize),
                );
              },
            ),
          );
        },
      );
      if (selectedFontSize != null) {
        setState(() {
          _textSize = selectedFontSize;
          showfontSize = (100 +
              ((selectedFontSize - Dimensions.fontSizeDefault) * 10));
        });
      }
    } else {
      final double? selectedFontSize = await showModalBottomSheet<double>(
        context: context,
        backgroundColor: AppTokens.surface(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.r28),
          ),
        ),
        builder: (BuildContext context) {
          double currentFontSize = _textSize;
          double showCurrFontSize = showfontSize;
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: const EdgeInsets.all(AppTokens.s20),
                child: _FontSizePanel(
                  currentFontSize: currentFontSize,
                  showFontSize: showCurrFontSize,
                  onDec: () {
                    setModalState(() {
                      if (showCurrFontSize > 50) {
                        showCurrFontSize -= 10;
                        currentFontSize -= 1;
                      }
                    });
                  },
                  onInc: () {
                    setModalState(() {
                      showCurrFontSize += 10;
                      currentFontSize += 1;
                    });
                  },
                  onCancel: () => Navigator.pop(context),
                  onApply: () => Navigator.pop(context, currentFontSize),
                ),
              );
            },
          );
        },
      );
      if (selectedFontSize != null) {
        setState(() {
          _textSize = selectedFontSize;
          showfontSize = (100 +
              ((selectedFontSize - Dimensions.fontSizeDefault) * 10));
        });
      }
    }
  }
}

// ============================================================================
// PRIMITIVES
// ============================================================================

class _PracticeHeader extends StatelessWidget {
  const _PracticeHeader({
    required this.onBack,
    required this.onPalletTap,
    required this.onSaveExit,
  });
  final VoidCallback onBack;
  final VoidCallback onPalletTap;
  final VoidCallback onSaveExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(AppTokens.s16, AppTokens.s12, AppTokens.s16, AppTokens.s16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppTokens.r28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTokens.brand.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _HeaderIconBtn(
            icon: Icons.arrow_back,
            onTap: onBack,
          ),
          const SizedBox(width: AppTokens.s12),
          _HeaderIconBtn(
            icon: Icons.grid_view_rounded,
            onTap: onPalletTap,
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSaveExit,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s16, vertical: AppTokens.s8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: AppTokens.radius20,
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: AppTokens.s8),
                  Text(
                    "Save & Exit",
                    style: AppTokens.titleSm(context)
                        .copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: AppTokens.radius12,
          border: Border.all(color: Colors.white.withOpacity(0.28)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _QuestionPager extends StatelessWidget {
  const _QuestionPager({
    required this.controller,
    required this.count,
    required this.currentIndex,
    required this.selectedIndex,
    required this.testData,
    required this.onTap,
  });
  final ScrollController controller;
  final int count;
  final int currentIndex;
  final int selectedIndex;
  final List<TestData> testData;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.s8),
        itemBuilder: (context, index) {
          final report =
              index < testData.length ? testData[index] : null;
          Color bg = AppTokens.surface(context);
          Color fg = AppTokens.ink2(context);
          Color border = AppTokens.border(context);

          if (report?.selectedOption != null &&
              (report?.selectedOption ?? "").isNotEmpty) {
            final isCorrect = (report?.correctOption ?? "") ==
                (report?.selectedOption ?? "");
            bg = isCorrect
                ? AppTokens.success(context)
                : AppTokens.danger(context);
            fg = Colors.white;
            border = bg;
          } else if (currentIndex == index) {
            if (selectedIndex == -1) {
              bg = AppTokens.accent(context);
              fg = Colors.white;
              border = bg;
            } else {
              final isCorrect = (report?.correctOption ?? "") ==
                  (report?.optionsData?[selectedIndex].value ?? "");
              bg = isCorrect
                  ? AppTokens.success(context)
                  : AppTokens.danger(context);
              fg = Colors.white;
              border = bg;
            }
          }

          return GestureDetector(
            onTap: () => onTap(index),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: border, width: 1.2),
              ),
              child: Text(
                "${index + 1}",
                style: AppTokens.titleSm(context).copyWith(color: fg),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuestionActionsRow extends StatelessWidget {
  const _QuestionActionsRow({
    required this.questionNumber,
    required this.isProcessing,
    required this.onAskCortex,
    required this.onRaiseQuery,
  });
  final int questionNumber;
  final bool isProcessing;
  final VoidCallback onAskCortex;
  final VoidCallback onRaiseQuery;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s12, vertical: AppTokens.s4),
          decoration: BoxDecoration(
            color: AppTokens.accentSoft(context),
            borderRadius: AppTokens.radius12,
          ),
          child: Text(
            "Q $questionNumber",
            style: AppTokens.titleSm(context)
                .copyWith(color: AppTokens.accent(context)),
          ),
        ),
        const Spacer(),
        _AskCortexButton(
          isProcessing: isProcessing,
          onTap: onAskCortex,
        ),
        const SizedBox(width: AppTokens.s8),
        _RaiseQueryButton(onTap: onRaiseQuery),
      ],
    );
  }
}

class _AskCortexButton extends StatelessWidget {
  const _AskCortexButton(
      {required this.isProcessing, required this.onTap});
  final bool isProcessing;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s12, vertical: AppTokens.s8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTokens.brand, AppTokens.brand2],
          ),
          borderRadius: AppTokens.radius20,
          boxShadow: [
            BoxShadow(
              color: AppTokens.brand.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isProcessing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: AppTokens.s4),
                  Text(
                    "Ask Cortex",
                    style: AppTokens.titleSm(context)
                        .copyWith(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}

class _RaiseQueryButton extends StatelessWidget {
  const _RaiseQueryButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s12, vertical: AppTokens.s8),
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          borderRadius: AppTokens.radius20,
          border: Border.all(color: AppTokens.accent(context), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_rounded,
                color: AppTokens.accent(context), size: 14),
            const SizedBox(width: AppTokens.s4),
            Text(
              "Raise Query",
              style: AppTokens.titleSm(context)
                  .copyWith(color: AppTokens.accent(context), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

enum _OptionState { neutral, correct, incorrect }

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.title,
    required this.imageUrl,
    required this.selected,
    required this.state,
    required this.onTap,
  });
  final String label;
  final String title;
  final String imageUrl;
  final bool selected;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color border = AppTokens.border(context);
    Color fg = AppTokens.ink(context);
    Color tint = AppTokens.surface(context);
    IconData? trailing;

    if (state == _OptionState.correct) {
      border = AppTokens.success(context);
      fg = AppTokens.success(context);
      tint = AppTokens.successSoft(context);
      trailing = Icons.check_circle_rounded;
    } else if (state == _OptionState.incorrect) {
      border = AppTokens.danger(context);
      fg = AppTokens.danger(context);
      tint = AppTokens.dangerSoft(context);
      trailing = Icons.cancel_rounded;
    } else if (selected) {
      border = AppTokens.accent(context);
      tint = AppTokens.accentSoft(context);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: AppTokens.radius16,
      child: Container(
        padding: const EdgeInsets.all(AppTokens.s12),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: AppTokens.radius16,
          border: Border.all(color: border, width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: state == _OptionState.neutral && !selected
                    ? AppTokens.surface3(context)
                    : border.withOpacity(0.15),
                borderRadius: AppTokens.radius8,
              ),
              child: Text(
                label,
                style: AppTokens.titleSm(context).copyWith(color: fg),
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTokens.body(context)
                        .copyWith(color: fg, fontSize: 15),
                  ),
                  if (imageUrl.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.s8),
                    ClipRRect(
                      borderRadius: AppTokens.radius12,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppTokens.s8),
              Icon(trailing, color: fg, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExplanationHeader extends StatelessWidget {
  const _ExplanationHeader({required this.onNotes, required this.onFont});
  final VoidCallback onNotes;
  final VoidCallback onFont;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppTokens.accent(context),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        Text("Explanation", style: AppTokens.titleMd(context)),
        const Spacer(),
        _ExplainIconBtn(
          icon: Icons.sticky_note_2_outlined,
          onTap: onNotes,
        ),
        const SizedBox(width: AppTokens.s8),
        _ExplainIconBtn(
          icon: Icons.format_size_rounded,
          onTap: onFont,
        ),
      ],
    );
  }
}

class _ExplainIconBtn extends StatelessWidget {
  const _ExplainIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTokens.surface2(context),
          borderRadius: AppTokens.radius12,
          border: Border.all(color: AppTokens.border(context)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: AppTokens.ink(context), size: 18),
      ),
    );
  }
}

class _CortexAIPanel extends StatelessWidget {
  const _CortexAIPanel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
        borderRadius: AppTokens.radius16,
        boxShadow: [
          BoxShadow(
            color: AppTokens.brand.withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: AppTokens.s8),
              Text(
                "Cortex.AI ",
                style: AppTokens.titleMd(context)
                    .copyWith(color: Colors.white),
              ),
              Text(
                "Explains",
                style: AppTokens.titleMd(context).copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          TypeWriterText(
            text: Text(
              text,
              style: AppTokens.body(context)
                  .copyWith(color: Colors.white, fontSize: 14),
            ),
            maintainSize: false,
            duration: const Duration(milliseconds: 10),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.firstQue,
    required this.disabled,
    required this.onPrev,
    required this.onNext,
  });
  final bool firstQue;
  final bool disabled;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16, vertical: AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        border: Border(
          top: BorderSide(color: AppTokens.border(context)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NavCircle(
            icon: Icons.arrow_back_rounded,
            disabled: disabled || firstQue,
            onTap: disabled ? null : onPrev,
          ),
          const SizedBox(width: AppTokens.s16),
          _NavCircle(
            icon: Icons.arrow_forward_rounded,
            disabled: disabled,
            onTap: disabled ? null : onNext,
          ),
        ],
      ),
    );
  }
}

class _NavCircle extends StatelessWidget {
  const _NavCircle({
    required this.icon,
    required this.disabled,
    required this.onTap,
  });
  final IconData icon;
  final bool disabled;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final color = disabled ? AppTokens.muted(context) : AppTokens.accent(context);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.6),
          color: disabled
              ? AppTokens.surface2(context)
              : AppTokens.accentSoft(context),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _FontSizePanel extends StatelessWidget {
  const _FontSizePanel({
    required this.currentFontSize,
    required this.showFontSize,
    required this.onDec,
    required this.onInc,
    required this.onCancel,
    required this.onApply,
  });
  final double currentFontSize;
  final double showFontSize;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback onCancel;
  final VoidCallback onApply;
  @override
  Widget build(BuildContext context) {
    return Column(
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
        Container(
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            color: AppTokens.surface2(context),
            borderRadius: AppTokens.radius12,
          ),
          child: Center(
            child: Text(
              'Sample Text',
              style: AppTokens.body(context).copyWith(
                fontSize: currentFontSize,
                color: AppTokens.ink(context),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.s16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Font size', style: AppTokens.titleSm(context)),
            Row(
              children: [
                _StepBtn(icon: Icons.remove_rounded, onTap: onDec),
                const SizedBox(width: AppTokens.s8),
                Text('${showFontSize.toInt()}%',
                    style: AppTokens.titleSm(context)),
                const SizedBox(width: AppTokens.s8),
                _StepBtn(icon: Icons.add_rounded, onTap: onInc),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _DialogBtn(
              label: 'Cancel',
              background: AppTokens.surface3(context),
              foreground: AppTokens.ink(context),
              onTap: onCancel,
            ),
            _DialogBtn(
              label: 'Apply',
              background: AppTokens.accent(context),
              foreground: Colors.white,
              onTap: onApply,
            ),
          ],
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTokens.surface2(context),
          borderRadius: AppTokens.radius8,
          border: Border.all(color: AppTokens.border(context)),
        ),
        child: Icon(icon, size: 16, color: AppTokens.ink(context)),
      ),
    );
  }
}

class _DialogBtn extends StatelessWidget {
  const _DialogBtn({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s20, vertical: AppTokens.s12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppTokens.radius12,
        ),
        child: Text(
          label,
          style: AppTokens.titleSm(context).copyWith(color: foreground),
        ),
      ),
    );
  }
}

class _ZoomableNetworkImage extends StatelessWidget {
  const _ZoomableNetworkImage({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: AppTokens.radius20),
              child: ClipRRect(
                borderRadius: AppTokens.radius20,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: PhotoView(
                    imageProvider: NetworkImage(url),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                    backgroundDecoration: BoxDecoration(
                      color: AppTokens.surface(context),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: AppTokens.radius12,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(),
          ),
        ),
      ),
    );
  }
}

class _PracticeSummaryDialog extends StatelessWidget {
  const _PracticeSummaryDialog({required this.store});
  final TestCategoryStore store;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTokens.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: AppTokens.radius20),
      child: Observer(builder: (context) {
        final data = store.getCustomReportPracticeCountData.value;
        return Padding(
          padding: const EdgeInsets.all(AppTokens.s20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Practice Test Summary",
                  style: AppTokens.titleMd(context)),
              const SizedBox(height: AppTokens.s16),
              _SummaryStatRow(
                color: AppTokens.success(context),
                icon: Icons.check_rounded,
                label: "Correct",
                value: "${data?.correctAnswers ?? 0}",
              ),
              const SizedBox(height: AppTokens.s12),
              _SummaryStatRow(
                color: AppTokens.danger(context),
                icon: Icons.close_rounded,
                label: "Incorrect",
                value: "${data?.incorrectAnswers ?? 0}",
              ),
              const SizedBox(height: AppTokens.s12),
              _SummaryStatRow(
                color: AppTokens.warning(context),
                icon: Icons.priority_high_rounded,
                label: "Unanswered",
                value: "${data?.notVisited ?? 0}",
              ),
              const SizedBox(height: AppTokens.s20),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Navigator.of(context)
                      .pushNamed(Routes.testCategory),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTokens.s16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTokens.brand, AppTokens.brand2],
                      ),
                      borderRadius: AppTokens.radius12,
                      boxShadow: [
                        BoxShadow(
                          color: AppTokens.brand.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Save & Exit",
                      style: AppTokens.titleSm(context)
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SummaryStatRow extends StatelessWidget {
  const _SummaryStatRow({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
  });
  final Color color;
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: AppTokens.s12),
        Text(label, style: AppTokens.body(context)),
        const Spacer(),
        Text(value,
            style: AppTokens.titleMd(context)
                .copyWith(color: AppTokens.ink(context))),
      ],
    );
  }
}
