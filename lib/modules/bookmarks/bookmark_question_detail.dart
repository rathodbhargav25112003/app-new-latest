import 'dart:io';
// ignore: unused_import
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_svg/svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/comman_widget.dart';
import 'package:shusruta_lms/modules/notes/mobilehelper.dart';
import 'package:shusruta_lms/modules/reports/explanation_common_widget.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/widgets/bottom_raise_query_window.dart'
    show CustomBottomRaiseQueryWindow;
import 'package:shusruta_lms/modules/widgets/bottom_stick_notes_window.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:typewritertext/typewritertext.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/get_explanation_model.dart';
import '../../models/get_notes_solution_model.dart';
import '../../models/solution_reports_model.dart';
import '../reports/store/report_by_category_store.dart';
import '../widgets/bottom_raise_query.dart';
import '../widgets/bottom_stick_notes.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';

/// BookMarkQuestionDetailScreen — paginated review of bookmarked questions.
/// Re-skinned with AppTokens; public surface (class, const constructor,
/// static [route] factory, state fields, and all instance methods incl.
/// [getExplanationText] / [getQuestionText] / [_putBookMarkApiCall] /
/// [deleteBookMarkApiCall] / [getQuestionLabel] / [_showDialog] /
/// [_getExplanationData] / [_showNotesDialog] / [addNotes] /
/// [_showBottomSheet]) is preserved exactly.
class BookMarkQuestionDetailScreen extends StatefulWidget {
  final List<SolutionReportsModel>? bookMarkQuestions;
  final int index;
  final String? examId;
  const BookMarkQuestionDetailScreen(
      {super.key, this.bookMarkQuestions, this.examId, required this.index});

  @override
  State<BookMarkQuestionDetailScreen> createState() =>
      _BookMarkQuestionDetailScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => BookMarkQuestionDetailScreen(
        bookMarkQuestions: arguments["bookMarkQuestions"],
        index: arguments['queIndex'],
        examId: arguments['examId'],
      ),
    );
  }
}

class _BookMarkQuestionDetailScreenState
    extends State<BookMarkQuestionDetailScreen> {
  final QuillController _quillController = QuillController.basic();
  int _currentQuestionIndex = 0;
  double _textSizePercent = 100;
  // ignore: unused_field
  Uint8List? answerImgBytes;
  bool isButtonVisible = true;
  bool isButtonVisible2 = true;
  // ignore: unused_field
  Uint8List? quesImgBytes;
  // ignore: unused_field
  Uint8List? explanationImgBytes;
  bool lastQue = false, firstQue = true, isBookmarked = false;
  Widget? explanationWidget;
  Widget? questionWidget;
  // ignore: unused_field
  final _controller = SuperTooltipController();
  bool isbutton = false, isprocess = false;
  double _textSize = Dimensions.fontSizeDefault;
  double showfontSize = 100;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentQuestionIndex = widget.index;
    _quillController.readOnly = true;
    _getNotesData(
        widget.bookMarkQuestions?[_currentQuestionIndex].questionId ?? "");
  }

  Future<void> _getNotesData(String queId) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onGetNotesData(queId);
  }

  Future<void> _showNextQuestion() async {
    scrollToTop(scrollController);
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    Delta delta = _quillController.document.toDelta();
    store.saveChangeExaplanation(context, {
      "question_id":
          widget.bookMarkQuestions?[_currentQuestionIndex].questionId,
      "annotation_data": delta.toJson()
    });
    widget.bookMarkQuestions?[_currentQuestionIndex].isHighlight = true;
    widget.bookMarkQuestions?[_currentQuestionIndex].annotationData =
        delta.toJson();
    setState(() {
      isbutton = false;
      firstQue = false;
      _currentQuestionIndex++;
      if (_currentQuestionIndex >=
          (widget.bookMarkQuestions?.length ?? 0) - 1) {
        lastQue = true;
        _currentQuestionIndex = (widget.bookMarkQuestions?.length ?? 0) - 1;
      } else {
        lastQue = false;
      }
      explanationWidget = getExplanationText(context);
      questionWidget = getQuestionText(context);
    });
    await _getNotesData(
        widget.bookMarkQuestions?[_currentQuestionIndex].questionId ?? "");
  }

  Future<void> _showPreviousQuestion() async {
    scrollToTop(scrollController);
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    Delta delta = _quillController.document.toDelta();
    store.saveChangeExaplanation(context, {
      "question_id":
          widget.bookMarkQuestions?[_currentQuestionIndex].questionId,
      "annotation_data": delta.toJson()
    });
    widget.bookMarkQuestions?[_currentQuestionIndex].isHighlight = true;
    widget.bookMarkQuestions?[_currentQuestionIndex].annotationData =
        delta.toJson();
    setState(() {
      isbutton = false;
      lastQue = false;
      if (widget.bookMarkQuestions?.length == 1) {
        _currentQuestionIndex = 0;
        firstQue = true;
      } else if (_currentQuestionIndex > 0) {
        _currentQuestionIndex--;
        firstQue = false;
      }
      explanationWidget = getExplanationText(context);
      questionWidget = getQuestionText(context);
    });
    await _getNotesData(
        widget.bookMarkQuestions?[_currentQuestionIndex].questionId ?? "");
  }

  Widget getExplanationText(BuildContext context) {
    String explanation =
        widget.bookMarkQuestions?[_currentQuestionIndex].explanation ?? "";
    explanation = explanation.replaceAllMapped(
        RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    List<String> splittedText = explanation.split("splittedImage");
    List<Widget> columns = [];
    int index = 0;
    for (String text in splittedText) {
      final documentContent = preprocessDocument(text);
      log(widget.bookMarkQuestions![_currentQuestionIndex].toJson().toString());
      _quillController.document = Document.fromJson(widget
                  .bookMarkQuestions![_currentQuestionIndex].isHighlight ??
              false
          ? widget.bookMarkQuestions![_currentQuestionIndex].annotationData!
                      .toString() ==
                  "[{}]"
              // ignore: unnecessary_string_interpolations
              ? parseCustomSyntax("""
$documentContent""")
              : widget.bookMarkQuestions![_currentQuestionIndex].annotationData!
          // ignore: unnecessary_string_interpolations
          : parseCustomSyntax("""
$documentContent"""));
      List<Widget> explanationImageWidget = [];
      if (widget.bookMarkQuestions?[_currentQuestionIndex].explanationImg
              ?.isNotEmpty ??
          false) {
        for (String base64String in widget
            .bookMarkQuestions![_currentQuestionIndex].explanationImg!) {
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
                child: Row(
                  children: [
                    Expanded(
                      child: InteractiveViewer(
                        scaleEnabled: false,
                        child: Center(
                          child: Container(
                            padding:
                                const EdgeInsets.only(bottom: AppTokens.s8),
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
            CommonExplanationWidget(
              textPercentage: _textSizePercent.toInt(),
              controller: _quillController,
            ),
            const SizedBox(height: AppTokens.s16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: explanationImageWidget,
            ),
            const SizedBox(height: AppTokens.s8),
            explanationImageWidget.isNotEmpty
                ? Text(
                    "Tap the image to zoom In/Out",
                    style: AppTokens.caption(context).copyWith(
                      color: AppTokens.muted(context),
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      );
      index++;
      if (index >=
          (widget.bookMarkQuestions?[_currentQuestionIndex].explanationImg
                      ?.length ??
                  0) -
              1) {
        break;
      }
    }
    return Column(children: columns);
  }

  Widget getQuestionText(BuildContext context) {
    if (widget.bookMarkQuestions == null ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= (widget.bookMarkQuestions?.length ?? 0)) {
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
        widget.bookMarkQuestions?[_currentQuestionIndex].questionText ?? "";
    questionTxt = questionTxt.replaceAllMapped(
        RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    List<String> splittedText = questionTxt.split("splittedImage");
    List<Widget> columns = [];
    int index = 0;
    for (String text in splittedText) {
      List<Widget> questionImageWidget = [];
      if (widget.bookMarkQuestions?[_currentQuestionIndex].questionImg
              ?.isNotEmpty ??
          false) {
        for (String base64String
            in widget.bookMarkQuestions![_currentQuestionIndex].questionImg!) {
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
                            padding:
                                const EdgeInsets.only(bottom: AppTokens.s8),
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
                  .replaceAll("\t\t\t--", "                 •")
                  .replaceAll("\t\t--", "           •")
                  .replaceAll("\t--", "     •")
                  .replaceAll("--", "•"),
              textAlign: TextAlign.left,
              style: AppTokens.titleMd(context).copyWith(
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: questionImageWidget,
            ),
            const SizedBox(height: AppTokens.s8),
            questionImageWidget.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.s8),
                    child: Text(
                      "Tap the image to zoom In/Out",
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.muted(context),
                      ),
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      );
      index++;
      if (index >=
          (widget.bookMarkQuestions?[_currentQuestionIndex].questionImg
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

  Future<void> _putBookMarkApiCall(String examId, String? questionId) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onBookMarkQuestion(
        // ignore: use_build_context_synchronously
        context,
        false,
        examId,
        questionId ?? "",
        "");
    BottomToast.showBottomToastOverlay(
      // ignore: use_build_context_synchronously
      context: context,
      errorMessage: "Bookmark Removed!",
      // ignore: use_build_context_synchronously
      backgroundColor: Theme.of(context).primaryColor,
    );

    if (widget.bookMarkQuestions!.length > 1) {
      widget.bookMarkQuestions?.removeWhere((e) => e.questionId == questionId);
      setState(() {});
    } else {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushNamed(Routes.bookMarkCategoryList,
          arguments: {'fromhome': true});
    }
  }

  Future<void> deleteBookMarkApiCall(String bookMarkId) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onDeleteBookMarkQuestion(context, bookMarkId);
  }

  String getQuestionLabel(int index) {
    int indexCount = index + 1;
    String formattedIndex = indexCount.toString().padLeft(2, '0');
    return 'Q - $formattedIndex/';
  }

  // ignore: unused_element
  void _showDialog(BuildContext context, String questionId, String questionText,
      String allOption) {
    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: ThemeManager.mainBackground,
            actionsPadding: EdgeInsets.zero,
            actions: [
              CustomBottomRaiseQueryWindow(
                questionId: questionId,
                questionText: questionText,
                allOptions: allOption,
              ),
            ],
          );
        },
      );
    } else {
      showModalBottomSheet<String>(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return CustomBottomRaiseQuery(
            questionId: questionId,
            questionText: questionText,
            allOptions: allOption,
          );
        },
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
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers for repeated dialog/sheet flows (ask faculty / report issue)
  // ---------------------------------------------------------------------------

  String _optionsJoined() {
    final opts = widget.bookMarkQuestions?[_currentQuestionIndex].options;
    return "a) ${opts?[0].answerTitle}\n"
        "b) ${opts?[1].answerTitle}\n"
        "c) ${opts?[2].answerTitle}\n"
        "d) ${opts?[3].answerTitle}";
  }

  void _showAskFaculty(BuildContext context) {
    final qId =
        widget.bookMarkQuestions?[_currentQuestionIndex].questionId ?? "";
    final qText =
        widget.bookMarkQuestions?[_currentQuestionIndex].questionText ?? '';
    final opts = _optionsJoined();

    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: ThemeManager.mainBackground,
            actionsPadding: EdgeInsets.zero,
            actions: [
              CustomBottomAskFaculty(
                questionId: qId,
                questionText: qText,
                allOptions: opts,
              ),
            ],
          );
        },
      );
    } else {
      showModalBottomSheet<String>(
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return CustomBottomAskFaculty(
            questionId: qId,
            questionText: qText,
            allOptions: opts,
          );
        },
      );
    }
  }

  void _showReportIssue(BuildContext context) {
    final qId =
        widget.bookMarkQuestions?[_currentQuestionIndex].questionId ?? "";
    final qText =
        widget.bookMarkQuestions?[_currentQuestionIndex].questionText ?? '';
    final opts = _optionsJoined();

    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: ThemeManager.mainBackground,
            actionsPadding: EdgeInsets.zero,
            actions: [
              CustomBottomReportIssue(
                questionId: qId,
                questionText: qText,
                allOptions: opts,
              ),
            ],
          );
        },
      );
    } else {
      showModalBottomSheet<String>(
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return CustomBottomReportIssue(
            questionId: qId,
            questionText: qText,
            allOptions: opts,
          );
        },
      );
    }
  }

  Future<void> _requestAiExplanation() async {
    if (!isbutton) {
      setState(() => isprocess = true);
    }
    final solutionReport = widget.bookMarkQuestions?[_currentQuestionIndex];
    final questionText = solutionReport?.questionText;
    final currentOption = solutionReport?.correctOption;
    final answerTitle = solutionReport?.options?.map((e) => e.answerTitle);

    int currentIndex = solutionReport?.options
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
    if (isbutton == false) {
      await _getExplanationData(question);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    explanationWidget = getExplanationText(context);
    questionWidget = getQuestionText(context);

    final hasQuestions = widget.bookMarkQuestions?.isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s16,
                AppTokens.s12,
                AppTokens.s16,
                AppTokens.s8,
              ),
              child: Row(
                children: [
                  _GhostIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      _putBookMarkApiCall(
                          widget.bookMarkQuestions?[_currentQuestionIndex]
                                  .examId ??
                              "",
                          widget.bookMarkQuestions?[_currentQuestionIndex]
                              .questionId);
                    },
                    borderRadius: BorderRadius.circular(AppTokens.r28),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.s16,
                        vertical: AppTokens.s8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTokens.dangerSoft(context),
                        borderRadius: BorderRadius.circular(AppTokens.r28),
                        border: Border.all(
                          // ignore: deprecated_member_use
                          color: AppTokens.danger(context).withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark_remove_rounded,
                            size: 16,
                            color: AppTokens.danger(context),
                          ),
                          const SizedBox(width: AppTokens.s8),
                          Text(
                            "Remove Bookmark",
                            style: AppTokens.caption(context).copyWith(
                              color: AppTokens.danger(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTokens.s16),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppTokens.s8),
                      if (hasQuestions) _buildQuestionHeader(context),
                      const SizedBox(height: AppTokens.s16),
                      if (!hasQuestions)
                        Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(top: AppTokens.s32),
                            child: Text(
                              "No filtered data available",
                              style: AppTokens.body(context).copyWith(
                                color: AppTokens.muted(context),
                              ),
                            ),
                          ),
                        ),
                      if (hasQuestions) ...[
                        // Question text + images
                        questionWidget ?? const SizedBox(),
                        // Options list
                        _buildOptions(context),
                        const SizedBox(height: AppTokens.s20),
                        // Explanation header + inline tools
                        _buildExplanationHeader(store),
                        const SizedBox(height: AppTokens.s8),
                        // Explanation body + optional AI answer
                        explanationWidget ?? const SizedBox(),
                        if (isbutton)
                          _buildAiExplainBlock(store)
                        else
                          const SizedBox(height: AppTokens.s8),
                        const SizedBox(height: AppTokens.s24),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Sticky floating-tools strip (when header is out of view)
            if (hasQuestions && !isButtonVisible2) _buildStickyToolsRow(store),

            // Bottom Previous/Next bar
            if (hasQuestions) _buildBottomNavBar(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Question header with Q-N / Total + inline action icons
  // ---------------------------------------------------------------------------

  Widget _buildQuestionHeader(BuildContext context) {
    return VisibilityDetector(
      key: const Key('button-key1'),
      onVisibilityChanged: (info) {
        setState(() {
          isButtonVisible2 = info.visibleFraction > 0;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppTokens.s16),
        decoration: AppTokens.cardDecoration(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s12, vertical: AppTokens.s4),
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: Text(
                "Q ${(_currentQuestionIndex + 1).toString().padLeft(2, '0')}",
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.accent(context),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            Text(
              "of ${widget.bookMarkQuestions?.length}",
              style: AppTokens.caption(context).copyWith(
                color: AppTokens.muted(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            _InlineIconButton(
              tooltip: "Ask Faculty",
              svgAsset: 'assets/image/support.svg',
              onTap: () => _showAskFaculty(context),
            ),
            const SizedBox(width: AppTokens.s8),
            _InlineIconButton(
              tooltip: "Report Issue",
              svgAsset: 'assets/image/message.svg',
              onTap: () => _showReportIssue(context),
            ),
            const SizedBox(width: AppTokens.s8),
            isprocess
                ? Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTokens.accentSoft(context),
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                    ),
                    child: CupertinoActivityIndicator(
                      color: AppTokens.accent(context),
                    ),
                  )
                : _InlineIconButton(
                    tooltip: "AI Explain",
                    svgAsset: 'assets/image/ai.svg',
                    onTap: _requestAiExplanation,
                    isAccent: true,
                  ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Options list (color-coded by correct / selected / guess)
  // ---------------------------------------------------------------------------

  Widget _buildOptions(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: AppTokens.s8, bottom: AppTokens.s8),
      physics: const NeverScrollableScrollPhysics(),
      itemCount:
          widget.bookMarkQuestions?[_currentQuestionIndex].options?.length,
      itemBuilder: (BuildContext context, int index) {
        final solutionReport =
            widget.bookMarkQuestions?[_currentQuestionIndex];
        final option = solutionReport?.options?[index];
        final optValue = option?.value ?? "";
        final correctValue = solutionReport?.correctOption ?? "";
        final selectedValue = solutionReport?.selectedOption ?? "";
        final guessValue = solutionReport?.guess ?? "";

        final isCorrect = correctValue == optValue;
        final isIncorrect = selectedValue == optValue && !isCorrect;
        final isGuess = guessValue == optValue && !isCorrect && !isIncorrect;

        Color chipBg;
        Color chipFg;
        Color borderColor;
        if (isCorrect) {
          chipBg = AppTokens.successSoft(context);
          chipFg = AppTokens.success(context);
          // ignore: deprecated_member_use
          borderColor = AppTokens.success(context).withOpacity(0.4);
        } else if (isIncorrect) {
          chipBg = AppTokens.dangerSoft(context);
          chipFg = AppTokens.danger(context);
          // ignore: deprecated_member_use
          borderColor = AppTokens.danger(context).withOpacity(0.4);
        } else if (isGuess) {
          // ignore: deprecated_member_use
          chipBg = Colors.brown.withOpacity(0.1);
          chipFg = Colors.brown;
          // ignore: deprecated_member_use
          borderColor = Colors.brown.withOpacity(0.4);
        } else {
          chipBg = AppTokens.surface(context);
          chipFg = AppTokens.ink(context);
          borderColor = AppTokens.border(context);
        }

        final base64String = option?.answerImg ?? "";

        return Padding(
          padding: const EdgeInsets.only(top: AppTokens.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  border: Border.all(color: borderColor, width: 1),
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
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: chipFg.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            optValue,
                            style: AppTokens.caption(context).copyWith(
                              color: chipFg,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.s12),
                        Expanded(
                          child: Text(
                            option?.answerTitle ?? "",
                            style: AppTokens.body(context).copyWith(
                              color: AppTokens.ink(context),
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (isCorrect)
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppTokens.success(context),
                            size: 20,
                          )
                        else if (isIncorrect)
                          Icon(
                            Icons.cancel_rounded,
                            color: AppTokens.danger(context),
                            size: 20,
                          ),
                      ],
                    ),
                    if (base64String.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppTokens.s8),
                        child: InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 3.0,
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppTokens.r8),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.6,
                              height: 250,
                              child: Stack(
                                children: [
                                  Image.network(base64String),
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
              if (isCorrect)
                Padding(
                  padding: const EdgeInsets.only(
                      top: AppTokens.s4, left: AppTokens.s16),
                  child: Text(
                    "${option?.percentage ?? "0"}% Got this answer correct",
                    style: AppTokens.caption(context).copyWith(
                      color: AppTokens.success(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (isIncorrect)
                Padding(
                  padding: const EdgeInsets.only(
                      top: AppTokens.s4, left: AppTokens.s16),
                  child: Text(
                    "${option?.percentage ?? "0"}% Marked this incorrect",
                    style: AppTokens.caption(context).copyWith(
                      color: AppTokens.danger(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (!isCorrect && !isIncorrect)
                Padding(
                  padding: const EdgeInsets.only(
                      top: AppTokens.s4, left: AppTokens.s16),
                  child: Text(
                    "${option?.percentage ?? "0"}% Marked this",
                    style: AppTokens.caption(context).copyWith(
                      color: AppTokens.warning(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Explanation header with highlight/notes/font tools
  // ---------------------------------------------------------------------------

  Widget _buildExplanationHeader(ReportsCategoryStore store) {
    return Observer(
      builder: (BuildContext context) {
        GetNotesSolutionModel? noteModel = store.notesData.value;
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s12, vertical: AppTokens.s4),
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: Text(
                "EXPLANATION",
                style: AppTokens.overline(context).copyWith(
                  color: AppTokens.accent(context),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
            ),
            const Spacer(),
            VisibilityDetector(
              key: const Key('button-key'),
              onVisibilityChanged: (info) {
                setState(() {
                  isButtonVisible = info.visibleFraction > 0;
                });
              },
              child: CommonTool(
                onTap: () {
                  final tstore = Provider.of<TestCategoryStore>(context,
                      listen: false);
                  Delta delta = _quillController.document.toDelta();
                  tstore.saveChangeExaplanation(context, {
                    "question_id": widget
                        .bookMarkQuestions?[_currentQuestionIndex].questionId,
                    "annotation_data": delta.toJson()
                  });
                  widget.bookMarkQuestions?[_currentQuestionIndex]
                      .isHighlight = true;
                  widget.bookMarkQuestions?[_currentQuestionIndex]
                      .annotationData = delta.toJson();
                },
                controller: _quillController,
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            _InlineIconButton(
              tooltip: "Notes",
              svgAsset: "assets/image/notes1.svg",
              onTap: () {
                _showNotesDialog(
                    context,
                    widget.bookMarkQuestions?[_currentQuestionIndex]
                            .questionId ??
                        "",
                    noteModel?.notes ?? "");
              },
            ),
            const SizedBox(width: AppTokens.s8),
            _InlineIconButton(
              tooltip: "Font size",
              svgAsset: "assets/image/atoz.svg",
              onTap: () => _showBottomSheet(context),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // AI explain block
  // ---------------------------------------------------------------------------

  Widget _buildAiExplainBlock(ReportsCategoryStore store) {
    return Observer(
      builder: (BuildContext context) {
        GetExplanationModel? getExplainModel = store.getExplanationText.value;
        return Container(
          margin: const EdgeInsets.only(top: AppTokens.s12),
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r16),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: AppTokens.brand.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
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
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "AI",
                      style: AppTokens.caption(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.brand,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Text(
                    "Cortex.AI ",
                    style: AppTokens.titleMd(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Explains",
                    style: AppTokens.titleMd(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              // ignore: deprecated_member_use
              TypeWriterText(
                text: Text(
                  getExplainModel?.text ?? '',
                  style: AppTokens.body(context).copyWith(
                    color: Colors.white,
                    height: 1.4,
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

  // ---------------------------------------------------------------------------
  // Sticky tools row (shown when header scrolls out)
  // ---------------------------------------------------------------------------

  Widget _buildStickyToolsRow(ReportsCategoryStore store) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        border: Border(
          top: BorderSide(color: AppTokens.border(context)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isButtonVisible) ...[
            CommonTool(
              onTap: () {
                final tstore =
                    Provider.of<TestCategoryStore>(context, listen: false);
                Delta delta = _quillController.document.toDelta();
                tstore.saveChangeExaplanation(context, {
                  "question_id": widget
                      .bookMarkQuestions?[_currentQuestionIndex].questionId,
                  "annotation_data": delta.toJson()
                });
                widget.bookMarkQuestions?[_currentQuestionIndex]
                    .isHighlight = true;
                widget.bookMarkQuestions?[_currentQuestionIndex]
                    .annotationData = delta.toJson();
              },
              controller: _quillController,
            ),
            const SizedBox(width: AppTokens.s8),
          ],
          _InlineIconButton(
            tooltip: "Ask Faculty",
            svgAsset: 'assets/image/support.svg',
            onTap: () => _showAskFaculty(context),
          ),
          const SizedBox(width: AppTokens.s8),
          _InlineIconButton(
            tooltip: "Report Issue",
            svgAsset: 'assets/image/message.svg',
            onTap: () => _showReportIssue(context),
          ),
          if (!isButtonVisible) ...[
            const SizedBox(width: AppTokens.s8),
            _InlineIconButton(
              tooltip: "Notes",
              svgAsset: "assets/image/notes1.svg",
              onTap: () {
                GetNotesSolutionModel? noteModel = store.notesData.value;
                _showNotesDialog(
                    context,
                    widget.bookMarkQuestions?[_currentQuestionIndex]
                            .questionId ??
                        "",
                    noteModel?.notes ?? "");
              },
            ),
            const SizedBox(width: AppTokens.s8),
            _InlineIconButton(
              tooltip: "Font size",
              svgAsset: "assets/image/atoz.svg",
              onTap: () => _showBottomSheet(context),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Previous / Next bar
  // ---------------------------------------------------------------------------

  Widget _buildBottomNavBar(BuildContext context) {
    final bool prevDisabled = isprocess == true || firstQue;
    final bool nextDisabled = isprocess == true;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s16,
        AppTokens.s12,
        AppTokens.s16,
        AppTokens.s20,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        border: Border(
          top: BorderSide(color: AppTokens.border(context)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _GhostCta(
                label: "Previous",
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: prevDisabled ? null : _showPreviousQuestion,
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: _GradientCta(
                label: "Next",
                icon: Icons.arrow_forward_ios_rounded,
                onTap: nextDisabled ? null : _showNextQuestion,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Notes dialog — preserved signature
  // ---------------------------------------------------------------------------

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
    _getNotesData(
        widget.bookMarkQuestions?[_currentQuestionIndex].questionId ?? "");
    BottomToast.showBottomToastOverlay(
      // ignore: use_build_context_synchronously
      context: context,
      errorMessage: "Notes Added Successfully!",
      // ignore: use_build_context_synchronously
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  // ---------------------------------------------------------------------------
  // Font-size bottom sheet / dialog — preserved platform branching
  // ---------------------------------------------------------------------------

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
            backgroundColor: AppTokens.surface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.r20),
            ),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return _FontSizePanel(
                  currentFontSize: currentFontSize,
                  showCurrFontSize: showCurrFontSize,
                  currentPercentFontSize: currentPercentFontSize,
                  onDecrement: () {
                    setModalState(() {
                      if (showCurrFontSize > 50) {
                        showCurrFontSize -= 10;
                        currentPercentFontSize -= 10;
                        currentFontSize -= 1;
                      }
                    });
                  },
                  onIncrement: () {
                    setModalState(() {
                      showCurrFontSize += 10;
                      currentPercentFontSize += 10;
                      currentFontSize += 1;
                    });
                  },
                  onCancel: () => Navigator.pop(context),
                  onApply: () =>
                      Navigator.pop(context, currentPercentFontSize),
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
          showfontSize =
              (100 + ((selectedFontSize - Dimensions.fontSizeDefault) * 10));
        });
      }
    } else {
      // ignore: prefer_typing_uninitialized_variables
      final selectedFontSize = await showDialog<dynamic>(
        context: context,
        builder: (BuildContext context) {
          double currentFontSize = _textSize;
          double currentPercentFontSize = _textSizePercent;
          double showCurrFontSize = showfontSize;

          return Dialog(
            backgroundColor: AppTokens.surface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.r20),
            ),
            elevation: 10,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return _FontSizePanel(
                  title: "Adjust Font Size",
                  currentFontSize: currentFontSize,
                  showCurrFontSize: showCurrFontSize,
                  currentPercentFontSize: currentPercentFontSize,
                  onDecrement: () {
                    setModalState(() {
                      if (showCurrFontSize > 50) {
                        showCurrFontSize -= 10;
                        currentPercentFontSize -= 10;
                        currentFontSize -= 1;
                      }
                    });
                  },
                  onIncrement: () {
                    setModalState(() {
                      showCurrFontSize += 10;
                      currentPercentFontSize += 10;
                      currentFontSize += 1;
                    });
                  },
                  onCancel: () => Navigator.pop(context),
                  onApply: () => Navigator.pop(context, {
                    "currentPercentFontSize": currentPercentFontSize,
                    "currentFontSize": currentFontSize,
                  }),
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
          showfontSize = (100 +
              ((selectedFontSize["currentFontSize"] -
                      Dimensions.fontSizeDefault) *
                  10)) as double;
        });
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Ghost icon button (used for back)
// ---------------------------------------------------------------------------

class _GhostIconButton extends StatelessWidget {
  const _GhostIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTokens.surface2(context),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(color: AppTokens.border(context)),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppTokens.ink(context)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inline compact icon button (tools row)
// ---------------------------------------------------------------------------

class _InlineIconButton extends StatelessWidget {
  const _InlineIconButton({
    required this.svgAsset,
    required this.onTap,
    this.tooltip,
    this.isAccent = false,
  });

  final String svgAsset;
  final VoidCallback onTap;
  final String? tooltip;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final bg = isAccent
        ? AppTokens.accentSoft(context)
        : AppTokens.surface2(context);
    final fg = isAccent
        ? AppTokens.accent(context)
        : AppTokens.ink(context);
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(color: AppTokens.border(context)),
          ),
          child: SvgPicture.asset(
            svgAsset,
            width: 16,
            height: 16,
            // ignore: deprecated_member_use
            color: fg,
          ),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }
}

// ---------------------------------------------------------------------------
// Gradient primary CTA (Next)
// ---------------------------------------------------------------------------

class _GradientCta extends StatelessWidget {
  const _GradientCta({required this.label, required this.onTap, this.icon});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    colors: [AppTokens.brand, AppTokens.brand2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: enabled ? null : AppTokens.surface3(context),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: AppTokens.brand.withOpacity(0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTokens.body(context).copyWith(
                  color:
                      enabled ? Colors.white : AppTokens.muted(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: AppTokens.s8),
                Icon(
                  icon,
                  size: 14,
                  color:
                      enabled ? Colors.white : AppTokens.muted(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ghost CTA (Previous)
// ---------------------------------------------------------------------------

class _GhostCta extends StatelessWidget {
  const _GhostCta({required this.label, required this.onTap, this.icon});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: enabled
                ? AppTokens.surface2(context)
                : AppTokens.surface3(context),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(
              color: AppTokens.border(context),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: enabled
                      ? AppTokens.ink(context)
                      : AppTokens.muted(context),
                ),
                const SizedBox(width: AppTokens.s8),
              ],
              Text(
                label,
                style: AppTokens.body(context).copyWith(
                  color: enabled
                      ? AppTokens.ink(context)
                      : AppTokens.muted(context),
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

// ---------------------------------------------------------------------------
// Font size panel (shared between platforms)
// ---------------------------------------------------------------------------

class _FontSizePanel extends StatelessWidget {
  const _FontSizePanel({
    this.title,
    required this.currentFontSize,
    required this.showCurrFontSize,
    // ignore: unused_element_parameter
    required this.currentPercentFontSize,
    required this.onDecrement,
    required this.onIncrement,
    required this.onCancel,
    required this.onApply,
  });

  final String? title;
  final double currentFontSize;
  final double showCurrFontSize;
  final double currentPercentFontSize;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(bottom: AppTokens.s12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTokens.border(context)),
                ),
              ),
              child: Text(
                title!,
                style: AppTokens.titleMd(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.s20),
          ],
          Container(
            padding: const EdgeInsets.all(AppTokens.s20),
            decoration: BoxDecoration(
              color: AppTokens.surface2(context),
              borderRadius: BorderRadius.circular(AppTokens.r12),
            ),
            alignment: Alignment.center,
            child: Text(
              'Sample Text',
              style: AppTokens.body(context).copyWith(
                fontSize: currentFontSize,
                color: AppTokens.ink(context),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Font Size',
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTokens.ink(context),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: onDecrement,
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: AppTokens.muted(context),
                    ),
                  ),
                  Text(
                    '$showCurrFontSize',
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTokens.ink(context),
                    ),
                  ),
                  IconButton(
                    onPressed: onIncrement,
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: AppTokens.muted(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s20),
          Divider(height: 2, color: AppTokens.border(context)),
          const SizedBox(height: AppTokens.s20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomButton(
                  onPressed: onCancel,
                  buttonText: "Cancel",
                  height: AppTokens.s24 * 2,
                  radius: AppTokens.r12,
                  transparent: true,
                  bgColor: ThemeManager.btnGrey,
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: CustomButton(
                  onPressed: onApply,
                  buttonText: "Apply",
                  height: AppTokens.s24 * 2,
                  radius: AppTokens.r12,
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
  }
}

// ignore: unused_element
Html _unusedHtmlSink(String data) => Html(data: data);

// ignore: unused_element
Widget _unusedInterRegular() =>
    Text("", style: interRegular.copyWith(fontSize: Dimensions.fontSizeDefault));

// ignore: unused_element
Widget _unusedInterBlack() =>
    Text("", style: interBlack.copyWith(fontSize: Dimensions.fontSizeDefault));
