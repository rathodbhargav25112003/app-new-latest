// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, unused_field, unused_local_variable, use_build_context_synchronously, avoid_print, non_constant_identifier_names, constant_identifier_names, dead_code

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:typewritertext/typewritertext.dart';

import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/modules/new_exam_component/widgets/post_attempt_analytics_panel.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/models/get_explanation_model.dart';
import 'package:shusruta_lms/models/get_notes_solution_model.dart';
import 'package:shusruta_lms/modules/quiztest/model/quiz_solution_reports_model.dart';
import 'package:shusruta_lms/modules/quiztest/quiz_bottom_raise_query.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/modules/widgets/bottom_stick_notes.dart';
import 'package:shusruta_lms/modules/widgets/bottom_stick_notes_window.dart';
import 'package:shusruta_lms/modules/widgets/bottom_toast.dart';
import 'package:shusruta_lms/modules/widgets/custom_bottom_sheet.dart';
import 'package:shusruta_lms/modules/widgets/custom_bottom_sheet_winow.dart';

/// Quiz solution report screen — navigator for per-question solutions
/// after a quiz is completed.
///
/// Preserved public contract:
///   • Constructor
///     `QuizSolutionReportScreen({super.key, this.solutionReport, required this.filter, required this.userExamId})`
///   • Static `route(RouteSettings)` reads `solutionReport`, `filterVal`,
///     `userExamId`.
///   • Filter toggles `View all` / `Correct` / `Incorrect` over
///     `widget.solutionReport` via `report.isCorrect`.
///   • `_getNotesData(queId)` → `ReportsCategoryStore.onGetNotesData`
///   • `_getExplanationData(prompt)` → `ReportsCategoryStore.onGetExplanationCall`
///   • `putBookMarkApiCall(examId, questionId, bookMarkNote)` →
///     `ReportsCategoryStore.onBookMarkQuestion`
///   • `addNotes(questionId, notes)` → `ReportsCategoryStore.onCreateNotes`
///   • `_showDialog(context, questionId, questionText, allOption)` →
///     `CustomQuizBottomRaiseQuery` (platform split for desktop/mobile).
///   • `_showNotesDialog(context, questionId, notes)` →
///     `CustomBottomStickNotes` / `CustomBottomStickNotesWindow`.
///   • `_showBottomSheet(context)` → font-size picker.
///   • `getQuestionText` / `getExplanationText` preserve
///     `----(.*?)----`  →  'splittedImage' token splitting and
///     bullet replacement (`\t\t\t--` / `\t\t--` / `\t--` / `--`).
///   • Bookmark toast: "Question Bookmarked Successfully!" /
///     "Bookmark Removed!"
///   • Notes toast: "Notes Added Successfully!"
class QuizSolutionReportScreen extends StatefulWidget {
  final List<QuizSolutionReportsModel>? solutionReport;
  final String filter;
  final String userExamId;
  const QuizSolutionReportScreen({
    super.key,
    this.solutionReport,
    required this.filter,
    required this.userExamId,
  });

  @override
  State<QuizSolutionReportScreen> createState() =>
      _QuizSolutionReportScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => QuizSolutionReportScreen(
        solutionReport: arguments['solutionReport'],
        filter: arguments['filterVal'],
        userExamId: arguments['userExamId'],
      ),
    );
  }
}

class _QuizSolutionReportScreenState extends State<QuizSolutionReportScreen> {
  String filterValue = 'View all';
  int _currentQuestionIndex = 0;
  Uint8List? answerImgBytes;
  Uint8List? quesImgBytes;
  Uint8List? explanationImgBytes;
  bool lastQue = false,
      firstQue = true,
      isBookmarked = false,
      isbutton = false,
      isprocess = false;
  List<QuizSolutionReportsModel>? filteredSolutionReport;
  Widget? explanationWidget;
  Widget? questionWidget;
  final _controller = SuperTooltipController();
  Key _viewerKey = GlobalKey();
  double _textSize = 14;
  double showfontSize = 100;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    filteredSolutionReport = widget.solutionReport;
    filterValue = widget.filter;
    _applyFilter();
    _getNotesData(
        filteredSolutionReport?[_currentQuestionIndex].questionId ?? "");
  }

  void _applyFilter() {
    if (filterValue.isNotEmpty && filterValue != "View all") {
      filteredSolutionReport = widget.solutionReport?.where((report) {
        if (filterValue == "Correct") {
          return report.isCorrect == true;
        } else if (filterValue == "Incorrect") {
          return report.isCorrect == false;
        }
        return false;
      }).toList();
    } else {
      filteredSolutionReport = widget.solutionReport;
    }
  }

  Future<void> _getNotesData(String queId) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onGetNotesData(queId);
  }

  Future<void> _getExplanationData(String prompt) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onGetExplanationCall(prompt);
    setState(() {
      isprocess = false;
      isbutton = true;
    });
  }

  void _showNextQuestion() {
    setState(() {
      _viewerKey = GlobalKey();
      isbutton = false;
      firstQue = false;
      _currentQuestionIndex++;
      if (_currentQuestionIndex >= (filteredSolutionReport?.length ?? 0) - 1) {
        lastQue = true;
        _currentQuestionIndex = (filteredSolutionReport?.length ?? 0) - 1;
      } else {
        lastQue = false;
      }
      explanationWidget = getExplanationText(context);
      questionWidget = getQuestionText(context);
      _scrollToIndex(_currentQuestionIndex);
    });
    _getNotesData(
        filteredSolutionReport?[_currentQuestionIndex].questionId ?? "");
  }

  void _showPreviousQuestion() {
    setState(() {
      isbutton = false;
      lastQue = false;
      if (filteredSolutionReport?.length == 1) {
        _currentQuestionIndex = 0;
        firstQue = true;
      } else if (_currentQuestionIndex > 0) {
        _currentQuestionIndex--;
        _viewerKey = GlobalKey();
        firstQue = false;
      }
      explanationWidget = getExplanationText(context);
      questionWidget = getQuestionText(context);
      _scrollToIndex(_currentQuestionIndex);
    });
    _getNotesData(
        filteredSolutionReport?[_currentQuestionIndex].questionId ?? "");
  }

  Widget getExplanationText(BuildContext context) {
    if (filteredSolutionReport == null ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= (filteredSolutionReport?.length ?? 0)) {
      return Center(
        child: Text(
          "No filtered data available",
          style: AppTokens.body(context).copyWith(
            color: AppTokens.ink(context),
          ),
        ),
      );
    }

    String explanation =
        filteredSolutionReport?[_currentQuestionIndex].explanation ?? "";
    explanation = explanation.replaceAllMapped(
        RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    final splittedText = explanation.split("splittedImage");
    final columns = <Widget>[];
    int index = 0;
    for (final text in splittedText) {
      final explanationImageWidget = <Widget>[];
      if (filteredSolutionReport?[_currentQuestionIndex]
              .explanationImg
              ?.isNotEmpty ??
          false) {
        for (final base64String in filteredSolutionReport![_currentQuestionIndex]
            .explanationImg!) {
          try {
            explanationImageWidget.add(
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: AppTokens.scaffold(context),
                      child: PhotoView(
                        imageProvider: NetworkImage(base64String),
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 2,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppTokens.s8),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                    border: Border.all(color: AppTokens.border(context)),
                  ),
                  child: InteractiveViewer(
                    scaleEnabled: false,
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
              style: AppTokens.body(context).copyWith(
                fontSize: _textSize,
                fontWeight: FontWeight.w400,
                color: AppTokens.ink(context),
                height: 1.5,
              ),
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
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.muted(context),
                ),
              ),
          ],
        ),
      );
      index++;
      if (index >=
          (filteredSolutionReport?[_currentQuestionIndex]
                      .explanationImg
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
    if (filteredSolutionReport == null ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= (filteredSolutionReport?.length ?? 0)) {
      return Center(
        child: Text(
          "No filtered data available",
          style: AppTokens.body(context).copyWith(
            color: AppTokens.ink(context),
          ),
        ),
      );
    }

    String questionTxt =
        filteredSolutionReport?[_currentQuestionIndex].questionText ?? "";
    questionTxt = questionTxt.replaceAllMapped(
        RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    final splittedText = questionTxt.split("splittedImage");
    final columns = <Widget>[];
    int index = 0;
    for (final text in splittedText) {
      final questionImageWidget = <Widget>[];
      if (filteredSolutionReport?[_currentQuestionIndex]
              .questionImg
              ?.isNotEmpty ??
          false) {
        for (final base64String
            in filteredSolutionReport![_currentQuestionIndex].questionImg!) {
          try {
            questionImageWidget.add(
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: AppTokens.scaffold(context),
                      child: PhotoView(
                        imageProvider: NetworkImage(base64String),
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 2,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppTokens.s8),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                    border: Border.all(color: AppTokens.border(context)),
                  ),
                  child: InteractiveViewer(
                    scaleEnabled: false,
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
              style: AppTokens.body(context).copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTokens.ink(context),
                height: 1.45,
              ),
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
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.muted(context),
                ),
              ),
          ],
        ),
      );
      index++;
      if (index >=
          (filteredSolutionReport?[_currentQuestionIndex].questionImg?.length ??
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

  Future<void> putBookMarkApiCall(
      String examId, String? questionId, String? bookMarkNote) async {
    setState(() {
      filteredSolutionReport?[_currentQuestionIndex].bookmarks =
          !(filteredSolutionReport?[_currentQuestionIndex].bookmarks ?? false);
    });
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onBookMarkQuestion(
      context,
      filteredSolutionReport?[_currentQuestionIndex].bookmarks ?? false,
      examId,
      questionId ?? "",
      bookMarkNote,
    );
    BottomToast.showBottomToastOverlay(
      context: context,
      errorMessage:
          filteredSolutionReport?[_currentQuestionIndex].bookmarks ?? false
              ? "Question Bookmarked Successfully!"
              : "Bookmark Removed!",
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  Future<void> addNotes(String? questionId, String? notes) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onCreateNotes(context, questionId ?? "", notes ?? "");
    _getNotesData(
        filteredSolutionReport?[_currentQuestionIndex].questionId ?? "");
    BottomToast.showBottomToastOverlay(
      context: context,
      errorMessage: "Notes Added Successfully!",
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  void _showDialog(BuildContext context, String questionId, String questionText,
      String allOption) {
    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTokens.surface(context),
            actionsPadding: EdgeInsets.zero,
            insetPadding: const EdgeInsets.symmetric(horizontal: 250),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.r20),
            ),
            actions: [
              CustomQuizBottomRaiseQuery(
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
          backgroundColor: AppTokens.surface(context),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTokens.r28),
            ),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          context: context,
          builder: (BuildContext context) {
            return CustomQuizBottomRaiseQuery(
              questionId: questionId,
              questionText: questionText,
              allOptions: allOption,
            );
          });
    }
  }

  void _showNotesDialog(BuildContext context, String questionId, String notes) {
    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTokens.surface(context),
            actionsPadding: EdgeInsets.zero,
            insetPadding: const EdgeInsets.symmetric(horizontal: 250),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.r20),
            ),
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

  void _scrollToIndex(int index) {
    const tileWidth = 44.0;
    const tileGap = AppTokens.s12;
    final totalWidth =
        (filteredSolutionReport?.length ?? 0) * (tileWidth + tileGap);
    final viewportWidth = MediaQuery.of(context).size.width;
    double maxScrollExtent = totalWidth - viewportWidth;
    maxScrollExtent = maxScrollExtent.clamp(0.0, double.infinity);
    double targetScrollPosition = index * (tileWidth + tileGap);
    targetScrollPosition = targetScrollPosition.clamp(0.0, maxScrollExtent);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetScrollPosition,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _questionChange(int index) {
    setState(() {
      _currentQuestionIndex = index;
      isbutton = false;
      firstQue = index == 0;
      lastQue = index == (filteredSolutionReport?.length ?? 1) - 1;
    });
    _getNotesData(
        filteredSolutionReport?[_currentQuestionIndex].questionId ?? "");
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    explanationWidget = getExplanationText(context);
    questionWidget = getQuestionText(context);

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: AppTokens.scaffold(context),
        surfaceTintColor: Colors.transparent,
        titleSpacing: AppTokens.s16,
        title: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(AppTokens.r8),
              child: Container(
                height: AppTokens.s32,
                width: AppTokens.s32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.surface2(context),
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppTokens.ink(context),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Text(
                "Solution Report",
                style: AppTokens.titleSm(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink(context),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            // Wave-2 Insights button — opens PostAttemptAnalyticsPanel.
            // Quizzes have small cohorts so cohort percentile is hidden.
            if (widget.userExamId.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.insights_rounded),
                tooltip: 'Performance insights',
                onPressed: () => _openInsights(context),
              ),
            const SizedBox(width: AppTokens.s8),
            _FilterButton(
              onTap: () => _openFilterSheet(context),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (filteredSolutionReport?.isNotEmpty ?? false)
            _QuestionPills(
              scrollController: _scrollController,
              reports: filteredSolutionReport!,
              currentIndex: _currentQuestionIndex,
              onTap: _questionChange,
            ),
          if (filteredSolutionReport?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(
                top: AppTokens.s16,
                left: AppTokens.s16,
                right: AppTokens.s16,
              ),
              child: Row(
                children: [
                  Text(
                    "${_currentQuestionIndex + 1}.",
                    style: AppTokens.titleSm(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTokens.ink(context),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  _StatusBadge(
                    report: filteredSolutionReport?[_currentQuestionIndex],
                  ),
                  const Spacer(),
                  _CortexAiButton(
                    loading: isprocess,
                    onTap: () => _onAskCortex(),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  _RaiseQueryButton(
                    onTap: () {
                      final rep =
                          filteredSolutionReport?[_currentQuestionIndex];
                      _showDialog(
                        context,
                        rep?.questionId ?? "",
                        rep?.questionText ?? '',
                        "a) ${rep?.options?[0].answerTitle}\nb) ${rep?.options?[1].answerTitle}\nc) ${rep?.options?[2].answerTitle}\nd) ${rep?.options?[3].answerTitle}",
                      );
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s16,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTokens.s12),
                    if (filteredSolutionReport?.isNotEmpty ?? false) ...[
                      Container(
                        padding: const EdgeInsets.all(AppTokens.s16),
                        decoration: BoxDecoration(
                          color: AppTokens.surface(context),
                          borderRadius: BorderRadius.circular(AppTokens.r16),
                          border: Border.all(color: AppTokens.border(context)),
                        ),
                        child: questionWidget ?? const SizedBox.shrink(),
                      ),
                      const SizedBox(height: AppTokens.s16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: filteredSolutionReport?[_currentQuestionIndex]
                            .options
                            ?.length,
                        itemBuilder: (BuildContext context, int i) {
                          final report =
                              filteredSolutionReport?[_currentQuestionIndex];
                          return _OptionSolutionTile(
                            report: report,
                            index: i,
                          );
                        },
                      ),
                      const SizedBox(height: AppTokens.s20),
                      Observer(
                        builder: (BuildContext context) {
                          GetNotesSolutionModel? noteModel =
                              store.notesData.value;
                          return Row(
                            children: [
                              Text(
                                "Explanation:",
                                style: AppTokens.titleSm(context).copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTokens.ink(context),
                                ),
                              ),
                              const Spacer(),
                              _IconTile(
                                asset: "assets/image/stickyIcon.png",
                                onTap: () {
                                  _showNotesDialog(
                                    context,
                                    filteredSolutionReport?[
                                                _currentQuestionIndex]
                                            .questionId ??
                                        "",
                                    noteModel?.notes ?? "",
                                  );
                                },
                              ),
                              const SizedBox(width: AppTokens.s8),
                              _IconTile(
                                asset: "assets/image/font_icon.png",
                                onTap: () => _showBottomSheet(context),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppTokens.s12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTokens.s16),
                        decoration: BoxDecoration(
                          color: AppTokens.surface(context),
                          borderRadius: BorderRadius.circular(AppTokens.r16),
                          border: Border.all(color: AppTokens.border(context)),
                        ),
                        child: explanationWidget ?? const SizedBox.shrink(),
                      ),
                      const SizedBox(height: AppTokens.s16),
                      if (isbutton)
                        Observer(
                          builder: (BuildContext context) {
                            GetExplanationModel? getExplainModel =
                                store.getExplanationText.value;
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppTokens.s20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTokens.brand,
                                    AppTokens.brand2,
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(AppTokens.r16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: AppTokens.s32,
                                        height: AppTokens.s32,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        child: Text(
                                          "AI",
                                          style: AppTokens.caption(context)
                                              .copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: AppTokens.brand,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppTokens.s8),
                                      Text(
                                        "Cortex.AI ",
                                        style: AppTokens.titleSm(context)
                                            .copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        "Explains",
                                        style: AppTokens.titleSm(context)
                                            .copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTokens.s12),
                                  TypeWriterText(
                                    text: Text(
                                      getExplainModel?.text ?? '',
                                      style:
                                          AppTokens.body(context).copyWith(
                                        color: Colors.white,
                                        height: 1.5,
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
                        ),
                      const SizedBox(height: AppTokens.s24),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (filteredSolutionReport?.isNotEmpty ?? false)
            _NavBar(
              firstQue: firstQue,
              lastQue: lastQue,
              disabled: isprocess,
              onPrev: _showPreviousQuestion,
              onNext: _showNextQuestion,
            ),
        ],
      ),
    );
  }

  Future<void> _onAskCortex() async {
    if (!isbutton) {
      setState(() {
        isprocess = true;
      });
    }
    final solutionReport = filteredSolutionReport?[_currentQuestionIndex];
    final questionText = solutionReport?.questionText;
    final currentOption = solutionReport?.correctOption;
    final answerTitle = solutionReport?.options?.map((e) => e.answerTitle);
    int currentIndex =
        solutionReport?.options?.indexWhere((e) => e.value == currentOption) ??
            -1;
    String? currentAnswerTitle = answerTitle?.elementAt(currentIndex);
    final notMatchingAnswerTitles = answerTitle
            ?.where((title) => title != currentAnswerTitle)
            .toList() ??
        [];
    final concatenatedTitles =
        notMatchingAnswerTitles.where((title) => title != null).join(", ");
    final question =
        "Explain why $currentAnswerTitle is the answer to the Question $questionText and why the remaining $concatenatedTitles are not correct answer";
    if (isbutton == false) {
      await _getExplanationData(question);
    }
  }

  void _openInsights(BuildContext context) {
    if (widget.userExamId.isEmpty) return;
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
            userExamId: widget.userExamId,
            // Quizzes have small cohorts — hide percentile to avoid
            // misleading the student at low n.
            showCohortPercentile: false,
            onRemediationCreated: (newId, count) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Remediation set ready ($count Qs). Find it in In-progress attempts.'),
              ));
            },
          ),
        ),
      ),
    ));
  }

  void _openFilterSheet(BuildContext context) {
    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTokens.surface(context),
            actionsPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.r20),
            ),
            actions: [
              CustomBottomSheetWindow(
                selectedVal: filterValue,
                radioItems: const ['View all', 'Correct', 'Incorrect'],
              ),
            ],
          );
        },
      ).then((selectedValue) {
        if (selectedValue != null) {
          setState(() {
            filterValue = selectedValue;
            _currentQuestionIndex = 0;
            _applyFilter();
            firstQue = true;
            lastQue = (filteredSolutionReport?.length ?? 0) <= 1;
          });
        }
      });
    } else {
      showModalBottomSheet<String>(
        backgroundColor: AppTokens.surface(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.r28),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return CustomBottomSheet(
            heightSize: MediaQuery.of(context).size.height * 0.4,
            selectedVal: filterValue,
            radioItems: const ['View all', 'Correct', 'Incorrect'],
          );
        },
      ).then((selectedValue) {
        if (selectedValue != null) {
          setState(() {
            filterValue = selectedValue;
            _currentQuestionIndex = 0;
            _applyFilter();
            firstQue = true;
            lastQue = (filteredSolutionReport?.length ?? 0) <= 1;
          });
        }
      });
    }
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.r20),
            ),
            content: StatefulBuilder(
              builder:
                  (BuildContext context, StateSetter setModalState) {
                return _FontSizePanel(
                  currentFontSize: currentFontSize,
                  showCurrFontSize: showCurrFontSize,
                  onDecrement: () {
                    setModalState(() {
                      if (showCurrFontSize > 50) {
                        showCurrFontSize -= 10;
                        currentFontSize -= 1;
                      }
                    });
                  },
                  onIncrement: () {
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
          showfontSize = (100 + ((selectedFontSize - 14) * 10));
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
            builder:
                (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s20,
                  AppTokens.s12,
                  AppTokens.s20,
                  AppTokens.s24,
                ),
                child: _FontSizePanel(
                  currentFontSize: currentFontSize,
                  showCurrFontSize: showCurrFontSize,
                  onDecrement: () {
                    setModalState(() {
                      if (showCurrFontSize > 50) {
                        showCurrFontSize -= 10;
                        currentFontSize -= 1;
                      }
                    });
                  },
                  onIncrement: () {
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
          showfontSize = (100 + ((selectedFontSize - 14) * 10));
        });
      }
    }
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r20),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTokens.accent(context)),
          borderRadius: BorderRadius.circular(AppTokens.r20),
          color: AppTokens.accentSoft(context),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 14,
              color: AppTokens.accent(context),
            ),
            const SizedBox(width: AppTokens.s4),
            Text(
              "Filter",
              style: AppTokens.caption(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.accent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionPills extends StatelessWidget {
  const _QuestionPills({
    required this.scrollController,
    required this.reports,
    required this.currentIndex,
    required this.onTap,
  });

  final ScrollController scrollController;
  final List<QuizSolutionReportsModel> reports;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTokens.s16,
        left: AppTokens.s16,
        right: AppTokens.s8,
      ),
      child: SizedBox(
        height: 44,
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(reports.length, (index) {
              final r = reports[index];
              final isCorrect =
                  (r.correctOption ?? "") == (r.selectedOption ?? "");
              final active = currentIndex == index;
              final tileColor = active
                  ? (isCorrect ? ThemeManager.greenSuccess : ThemeManager.redText)
                  : AppTokens.surface(context);
              final borderColor = isCorrect
                  ? ThemeManager.greenSuccess
                  : ThemeManager.redText;
              final textColor = active
                  ? Colors.white
                  : (isCorrect
                      ? ThemeManager.greenSuccess
                      : ThemeManager.redText);
              return Padding(
                padding: const EdgeInsets.only(right: AppTokens.s12),
                child: GestureDetector(
                  onTap: () => onTap(index),
                  child: Container(
                    height: 36,
                    width: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tileColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 1.4),
                    ),
                    child: Text(
                      "${r.questionNumber}",
                      style: AppTokens.caption(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.report});
  final QuizSolutionReportsModel? report;

  @override
  Widget build(BuildContext context) {
    final isGuessed = (report?.guess ?? "") != "";
    final isSkipped = (report?.selectedOption ?? "") == "";
    if (!isGuessed && !isSkipped) return const SizedBox.shrink();
    final label = isGuessed ? "Guessed" : "Skipped";
    return Container(
      height: 26,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTokens.r20),
        border: Border.all(color: Colors.orange.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: AppTokens.caption(context).copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.orange.shade700,
        ),
      ),
    );
  }
}

class _CortexAiButton extends StatelessWidget {
  const _CortexAiButton({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(AppTokens.r20),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTokens.brand, AppTokens.brand2],
          ),
          borderRadius: BorderRadius.circular(AppTokens.r20),
        ),
        child: loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppTokens.s4),
                  Text(
                    "Ask Cortex.AI",
                    style: AppTokens.caption(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r20),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s12),
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          borderRadius: BorderRadius.circular(AppTokens.r20),
          border: Border.all(color: AppTokens.accent(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline_rounded,
                size: 14, color: AppTokens.accent(context)),
            const SizedBox(width: AppTokens.s4),
            Text(
              "Raise Query",
              style: AppTokens.caption(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionSolutionTile extends StatelessWidget {
  const _OptionSolutionTile({required this.report, required this.index});
  final QuizSolutionReportsModel? report;
  final int index;

  @override
  Widget build(BuildContext context) {
    final optionValue = report?.options?[index].value ?? "";
    final isCorrect = (report?.correctOption ?? "") == optionValue;
    final isSelectedWrong = !isCorrect &&
        (report?.selectedOption ?? "") == optionValue;
    final isGuess = !isCorrect &&
        !isSelectedWrong &&
        (report?.guess ?? "") == optionValue;

    Color borderColor;
    Color fillColor;
    Color textColor;
    IconData? iconData;
    Color? iconColor;

    if (isCorrect) {
      borderColor = ThemeManager.greenSuccess;
      fillColor = ThemeManager.greenSuccess.withOpacity(0.10);
      textColor = ThemeManager.greenSuccess;
      iconData = Icons.check_circle_rounded;
      iconColor = ThemeManager.greenSuccess;
    } else if (isSelectedWrong) {
      borderColor = ThemeManager.redText;
      fillColor = ThemeManager.redText.withOpacity(0.10);
      textColor = ThemeManager.redText;
      iconData = Icons.cancel_rounded;
      iconColor = ThemeManager.redText;
    } else if (isGuess) {
      borderColor = Colors.brown;
      fillColor = Colors.brown.withOpacity(0.10);
      textColor = Colors.brown;
      iconData = Icons.help_rounded;
      iconColor = Colors.brown;
    } else {
      borderColor = AppTokens.border(context);
      fillColor = AppTokens.surface(context);
      textColor = AppTokens.ink(context);
      iconData = null;
      iconColor = null;
    }

    final base64String = report?.options?[index].answerImg ?? "";

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppTokens.r16),
          color: fillColor,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16,
          vertical: AppTokens.s12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${report?.options?[index].value ?? ""}.  ",
                        style: AppTokens.body(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          report?.options?[index].answerTitle ?? "",
                          style: AppTokens.body(context).copyWith(
                            fontWeight: FontWeight.w500,
                            color: textColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (base64String.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.s8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                      child: Image.network(base64String, fit: BoxFit.cover),
                    ),
                  ],
                ],
              ),
            ),
            if (iconData != null) ...[
              const SizedBox(width: AppTokens.s8),
              Icon(iconData, color: iconColor, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.asset, required this.onTap});
  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: Container(
        height: AppTokens.s32 + 4,
        width: AppTokens.s32 + 4,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTokens.surface2(context),
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: Border.all(color: AppTokens.border(context)),
        ),
        child: Image.asset(asset, width: 18, height: 18),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.firstQue,
    required this.lastQue,
    required this.disabled,
    required this.onPrev,
    required this.onNext,
  });

  final bool firstQue;
  final bool lastQue;
  final bool disabled;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTokens.surface(context),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NavCircle(
            disabled: disabled || firstQue,
            onTap: onPrev,
            icon: Icons.arrow_back_ios_new_rounded,
          ),
          const SizedBox(width: AppTokens.s16),
          _NavCircle(
            disabled: disabled || lastQue,
            onTap: onNext,
            icon: Icons.arrow_forward_ios_rounded,
          ),
        ],
      ),
    );
  }
}

class _NavCircle extends StatelessWidget {
  const _NavCircle({
    required this.disabled,
    required this.onTap,
    required this.icon,
  });
  final bool disabled;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        disabled ? AppTokens.border(context) : AppTokens.accent(context);
    final iconColor =
        disabled ? AppTokens.muted(context) : AppTokens.accent(context);
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 48,
        width: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: disabled
              ? AppTokens.surface2(context)
              : AppTokens.accentSoft(context),
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }
}

class _FontSizePanel extends StatelessWidget {
  const _FontSizePanel({
    required this.currentFontSize,
    required this.showCurrFontSize,
    required this.onDecrement,
    required this.onIncrement,
    required this.onCancel,
    required this.onApply,
  });

  final double currentFontSize;
  final double showCurrFontSize;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTokens.border(context),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.s16),
        Container(
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            color: AppTokens.surface2(context),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(color: AppTokens.border(context)),
          ),
          child: Center(
            child: Text(
              'Sample Text',
              style: TextStyle(
                fontSize: currentFontSize,
                fontWeight: FontWeight.w400,
                color: AppTokens.ink(context),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.s16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Font size',
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: onDecrement,
                  icon: Icon(Icons.remove_circle_outline,
                      color: AppTokens.muted(context)),
                ),
                Text(
                  '$showCurrFontSize',
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.ink(context),
                  ),
                ),
                IconButton(
                  onPressed: onIncrement,
                  icon: Icon(Icons.add_circle_outline,
                      color: AppTokens.muted(context)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: InkWell(
                onTap: onCancel,
                borderRadius: BorderRadius.circular(AppTokens.r12),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.surface2(context),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                    border: Border.all(color: AppTokens.border(context)),
                  ),
                  child: Text(
                    "Cancel",
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTokens.ink(context),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: InkWell(
                onTap: onApply,
                borderRadius: BorderRadius.circular(AppTokens.r12),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTokens.brand, AppTokens.brand2],
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                  ),
                  child: Text(
                    "Apply",
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
