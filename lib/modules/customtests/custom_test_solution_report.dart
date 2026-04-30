// ignore_for_file: use_super_parameters, deprecated_member_use, use_build_context_synchronously, unused_import, unused_field, unused_element, unused_local_variable

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/models/get_explanation_model.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/modules/widgets/bottom_stick_notes_window.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:typewritertext/typewritertext.dart';

import '../../helpers/app_tokens.dart';
import 'package:shusruta_lms/modules/new_exam_component/widgets/post_attempt_analytics_panel.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/get_notes_solution_model.dart';
import '../widgets/bottom_stick_notes.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_bottom_sheet.dart';
import 'custom_test_bottom_raise_query.dart';
import 'model/custom_test_solution_reports_model.dart';

class CustomTestSolutionReportScreen extends StatefulWidget {
  final List<CustomTestSolutionReportsModel>? solutionReport;
  final String filter;
  final String userExamId;
  const CustomTestSolutionReportScreen(
      {Key? key,
      this.solutionReport,
      required this.filter,
      required this.userExamId})
      : super(key: key);

  @override
  State<CustomTestSolutionReportScreen> createState() =>
      _CustomTestSolutionReportScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => CustomTestSolutionReportScreen(
        solutionReport: arguments['solutionReport'],
        filter: arguments['filterVal'],
        userExamId: arguments['userExamId'],
      ),
    );
  }
}

class _CustomTestSolutionReportScreenState
    extends State<CustomTestSolutionReportScreen> {
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
  List<CustomTestSolutionReportsModel>? filteredSolutionReport;
  Widget? explanationWidget;
  Widget? questionWidget;
  final _controller = SuperTooltipController();
  Key _viewerKey = GlobalKey();
  double _textSize = Dimensions.fontSizeDefault;
  double showfontSize = 100;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    filteredSolutionReport = widget.solutionReport;
    filterValue = widget.filter;
    if (filterValue.isNotEmpty && filterValue != "View all") {
      filteredSolutionReport = widget.solutionReport?.where((report) {
        if (filterValue == "Correct") {
          return report.isCorrect == true;
        } else if (filterValue == "Incorrect") {
          return report.isCorrect == false;
        } else if (filterValue == "Skipped") {
          return report.skipped = false;
        } else if (filterValue == "Guessed") {
          return report.guess?.isNotEmpty ?? false;
        }
        return false;
      }).toList();
    } else {
      filteredSolutionReport = widget.solutionReport;
    }
    _getNotesData(
        filteredSolutionReport?[_currentQuestionIndex].questionId ?? "");
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
      return const SizedBox();
    }

    String explanation =
        filteredSolutionReport?[_currentQuestionIndex].explanation ?? "";
    explanation = explanation.replaceAllMapped(
        RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    List<String> splittedText = explanation.split("splittedImage");
    List<Widget> columns = [];
    int index = 0;
    for (String text in splittedText) {
      List<Widget> explanationImageWidget = [];
      if (filteredSolutionReport?[_currentQuestionIndex]
              .explanationImg
              ?.isNotEmpty ??
          false) {
        for (String base64String
            in filteredSolutionReport![_currentQuestionIndex].explanationImg!) {
          try {
            explanationImageWidget.add(
              _ZoomableImage(src: base64String, maxHeight: 260),
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
              style: AppTokens.bodyLg(context).copyWith(
                fontSize: _textSize,
                color: AppTokens.ink(context),
              ),
            ),
            if (explanationImageWidget.isNotEmpty)
              const SizedBox(height: AppTokens.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: explanationImageWidget,
            ),
            if (explanationImageWidget.isNotEmpty)
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
      return const SizedBox();
    }

    String questionTxt =
        filteredSolutionReport?[_currentQuestionIndex].questionText ?? "";
    questionTxt = questionTxt.replaceAllMapped(
        RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    List<String> splittedText = questionTxt.split("splittedImage");
    List<Widget> columns = [];
    int index = 0;
    for (String text in splittedText) {
      List<Widget> questionImageWidget = [];
      if (filteredSolutionReport?[_currentQuestionIndex]
              .questionImg
              ?.isNotEmpty ??
          false) {
        for (String base64String
            in filteredSolutionReport![_currentQuestionIndex].questionImg!) {
          try {
            questionImageWidget.add(
              _ZoomableImage(src: base64String, maxHeight: 240),
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
              style: AppTokens.titleMd(context).copyWith(
                fontSize: Dimensions.fontSizeLarge,
                fontWeight: FontWeight.w600,
                height: 1.35,
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
        bookMarkNote);
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
    showModalBottomSheet<String>(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.r28)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      backgroundColor: AppTokens.surface(context),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return CustomTestBottomRaiseQuery(
          questionId: questionId,
          questionText: questionText,
          allOptions: allOption,
        );
      },
    );
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
            shape: const RoundedRectangleBorder(
                borderRadius: AppTokens.radius20),
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
    const double pillSize = 40;
    const double pillGap = 10;
    final double totalWidth =
        (filteredSolutionReport?.length ?? 0) * (pillSize + pillGap);
    final double viewportWidth = MediaQuery.of(context).size.width;
    double maxScrollExtent = totalWidth - viewportWidth;
    maxScrollExtent = maxScrollExtent.clamp(0.0, double.infinity);
    double targetScrollPosition = index * (pillSize + pillGap);
    targetScrollPosition = targetScrollPosition.clamp(0.0, maxScrollExtent);
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      targetScrollPosition,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOut,
    );
  }

  void _questionChange(int index) {
    setState(() {
      _currentQuestionIndex = index;
      explanationWidget = getExplanationText(context);
      questionWidget = getQuestionText(context);
      firstQue = index == 0;
      lastQue = index >= (filteredSolutionReport?.length ?? 1) - 1;
      isbutton = false;
    });
    _getNotesData(
        filteredSolutionReport?[_currentQuestionIndex].questionId ?? "");
  }

  void _openInsights(BuildContext context) {
    if (widget.userExamId.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Performance insights')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: PostAttemptAnalyticsPanel(
            userExamId: widget.userExamId,
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

  void _openFilterSheet() {
    showModalBottomSheet<String>(
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.r28)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      context: context,
      builder: (BuildContext context) {
        return CustomBottomSheet(
            heightSize: MediaQuery.of(context).size.height * 0.55,
            selectedVal: filterValue,
            radioItems: const [
              'View all',
              'Correct',
              'Incorrect',
              'Skipped',
              'Guessed'
            ]);
      },
    ).then((selectedValue) {
      if (selectedValue != null) {
        setState(() {
          filterValue = selectedValue;
          _currentQuestionIndex = 0;
          firstQue = true;
          lastQue = false;
          if (filterValue.isNotEmpty && filterValue != "View all") {
            filteredSolutionReport =
                widget.solutionReport?.where((report) {
              if (filterValue == "Correct") {
                return report.isCorrect == true;
              } else if (filterValue == "Incorrect") {
                return report.isCorrect == false;
              } else if (filterValue == "Skipped") {
                return report.skipped == true;
              } else if (filterValue == "Guessed") {
                return report.guess?.isNotEmpty ?? false;
              }
              return false;
            }).toList();
          } else {
            filteredSolutionReport = widget.solutionReport;
          }
          explanationWidget = getExplanationText(context);
          questionWidget = getQuestionText(context);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    explanationWidget = getExplanationText(context);
    questionWidget = getQuestionText(context);

    final int total = filteredSolutionReport?.length ?? 0;
    final bool hasData = total > 0;

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: _GradientHeader(
          currentIndex: _currentQuestionIndex,
          total: total,
          filterLabel: filterValue,
          onBack: () => Navigator.pop(context),
          onFilter: _openFilterSheet,
          // Wave-2 Insights — opens PostAttemptAnalyticsPanel.
          onInsights: widget.userExamId.isEmpty ? null : () => _openInsights(context),
        ),
      ),
      body: !hasData
          ? const _EmptyState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTokens.s16),
                _QuestionPager(
                  reports: filteredSolutionReport!,
                  currentIndex: _currentQuestionIndex,
                  scrollController: _scrollController,
                  onTap: _questionChange,
                ),
                const SizedBox(height: AppTokens.s16),
                _QuestionActionsRow(
                  index: _currentQuestionIndex,
                  report:
                      filteredSolutionReport![_currentQuestionIndex],
                  isProcessing: isprocess,
                  onAskCortex: _handleAskCortex,
                  onRaiseQuery: () {
                    final r =
                        filteredSolutionReport![_currentQuestionIndex];
                    final options = r.options ?? [];
                    _showDialog(
                      context,
                      r.questionId ?? "",
                      r.questionText ?? '',
                      "a) ${options.isNotEmpty ? options[0].answerTitle : ''}"
                          "\nb) ${options.length > 1 ? options[1].answerTitle : ''}"
                          "\nc) ${options.length > 2 ? options[2].answerTitle : ''}"
                          "\nd) ${options.length > 3 ? options[3].answerTitle : ''}",
                    );
                  },
                ),
                const SizedBox(height: AppTokens.s16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(AppTokens.s16, 0, AppTokens.s16, AppTokens.s24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _QuestionCard(child: questionWidget ?? const SizedBox()),
                        const SizedBox(height: AppTokens.s16),
                        ..._buildOptions(),
                        const SizedBox(height: AppTokens.s24),
                        _ExplanationHeader(
                          onNotes: () {
                            final noteModel = store.notesData.value;
                            _showNotesDialog(
                                context,
                                filteredSolutionReport?[_currentQuestionIndex]
                                        .questionId ??
                                    "",
                                noteModel?.notes ?? "");
                          },
                          onFontSize: () => _showBottomSheet(context),
                        ),
                        const SizedBox(height: AppTokens.s12),
                        _ExplanationCard(child: explanationWidget ?? const SizedBox()),
                        const SizedBox(height: AppTokens.s16),
                        if (isbutton)
                          Observer(builder: (BuildContext context) {
                            final GetExplanationModel? getExplainModel =
                                store.getExplanationText.value;
                            return _CortexAIPanel(
                              text: getExplainModel?.text ?? '',
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                _BottomNavBar(
                  firstQue: firstQue,
                  lastQue: lastQue,
                  isProcessing: isprocess,
                  onPrev: _showPreviousQuestion,
                  onNext: _showNextQuestion,
                ),
              ],
            ),
    );
  }

  List<Widget> _buildOptions() {
    final r = filteredSolutionReport![_currentQuestionIndex];
    final options = r.options ?? [];
    final List<Widget> rows = [];
    for (int i = 0; i < options.length; i++) {
      final opt = options[i];
      final String val = opt.value ?? "";
      _OptionState state = _OptionState.neutral;
      if ((r.correctOption ?? "") == val) {
        state = _OptionState.correct;
      } else if ((r.selectedOption ?? "") == val) {
        state = _OptionState.incorrect;
      } else if ((r.guess ?? "") == val) {
        state = _OptionState.guess;
      }
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: AppTokens.s12),
        child: _OptionCard(
          label: opt.value ?? "",
          text: opt.answerTitle ?? "",
          imageUrl: opt.answerImg ?? "",
          state: state,
        ),
      ));
    }
    return rows;
  }

  Future<void> _handleAskCortex() async {
    if (!isbutton) {
      setState(() => isprocess = true);
    }
    final solutionReport = filteredSolutionReport?[_currentQuestionIndex];
    final questionText = solutionReport?.questionText;
    final currentOption = solutionReport?.correctOption;
    final answerTitle = solutionReport?.options?.map((e) => e.answerTitle);
    int currentIndex = solutionReport?.options
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
    if (!isbutton) {
      await _getExplanationData(question);
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
            shape: const RoundedRectangleBorder(
                borderRadius: AppTokens.radius20),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
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
          showfontSize = (100 +
              ((selectedFontSize - Dimensions.fontSizeDefault) * 10));
        });
      }
    } else {
      final double? selectedFontSize = await showModalBottomSheet<double>(
        context: context,
        backgroundColor: AppTokens.surface(context),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTokens.r28)),
        ),
        builder: (BuildContext context) {
          double currentFontSize = _textSize;
          double showCurrFontSize = showfontSize;
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: const EdgeInsets.all(AppTokens.s16),
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
          showfontSize = (100 +
              ((selectedFontSize - Dimensions.fontSizeDefault) * 10));
        });
      }
    }
  }
}

// -----------------------------------------------------------------------------
//  Primitives
// -----------------------------------------------------------------------------

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({
    Key? key,
    required this.currentIndex,
    required this.total,
    required this.filterLabel,
    required this.onBack,
    required this.onFilter,
    this.onInsights,
  }) : super(key: key);

  final int currentIndex;
  final int total;
  final String filterLabel;
  final VoidCallback onBack;
  final VoidCallback onFilter;
  // Wave-2 Insights button — null hides the button.
  final VoidCallback? onInsights;

  @override
  Widget build(BuildContext context) {
    final subtitle = total == 0
        ? "No questions"
        : "Question ${currentIndex + 1} of $total";
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          AppTokens.s12, MediaQuery.of(context).padding.top + 10, AppTokens.s12, AppTokens.s12),
      child: Row(
        children: [
          _HeaderChip(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Solution Review",
                  style: AppTokens.titleMd(context).copyWith(
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTokens.caption(context).copyWith(
                    color: Colors.white.withOpacity(0.82),
                  ),
                ),
              ],
            ),
          ),
          if (onInsights != null) ...[
            _HeaderChip(icon: Icons.insights_rounded, onTap: onInsights!),
            const SizedBox(width: AppTokens.s8),
          ],
          _FilterChip(label: filterLabel, onTap: onFilter),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({Key? key, required this.icon, required this.onTap})
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
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({Key? key, required this.label, required this.onTap})
      : super(key: key);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.20),
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
              const Icon(Icons.tune_rounded,
                  color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label.isEmpty ? "Filter" : label,
                style: AppTokens.caption(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTokens.surface2(context),
                borderRadius: AppTokens.radius20,
              ),
              child: Icon(Icons.filter_alt_off_rounded,
                  color: AppTokens.muted(context), size: 32),
            ),
            const SizedBox(height: AppTokens.s12),
            Text("No filtered data available",
                style: AppTokens.titleSm(context)),
            const SizedBox(height: AppTokens.s4),
            Text(
              "Try choosing a different filter from the top-right.",
              style: AppTokens.caption(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionPager extends StatelessWidget {
  const _QuestionPager({
    Key? key,
    required this.reports,
    required this.currentIndex,
    required this.scrollController,
    required this.onTap,
  }) : super(key: key);

  final List<CustomTestSolutionReportsModel> reports;
  final int currentIndex;
  final ScrollController scrollController;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
        itemCount: reports.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.s8),
        itemBuilder: (context, i) {
          final r = reports[i];
          final bool isCorrect =
              (r.correctOption ?? "") == (r.selectedOption ?? "");
          final bool isActive = currentIndex == i;
          final Color accent =
              isCorrect ? AppTokens.success(context) : AppTokens.danger(context);
          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 1.4),
              ),
              child: Text(
                "${i + 1}",
                style: AppTokens.caption(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : accent,
                ),
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
    Key? key,
    required this.index,
    required this.report,
    required this.isProcessing,
    required this.onAskCortex,
    required this.onRaiseQuery,
  }) : super(key: key);

  final int index;
  final CustomTestSolutionReportsModel report;
  final bool isProcessing;
  final Future<void> Function() onAskCortex;
  final VoidCallback onRaiseQuery;

  @override
  Widget build(BuildContext context) {
    Widget? tag;
    if ((report.guess ?? "") != "") {
      tag = _StatusTag(
        label: "Guessed",
        background: AppTokens.warningSoft(context),
        foreground: AppTokens.warning(context),
      );
    } else if (
        // ignore: unrelated_type_equality_checks
        report.selectedOption == true) {
      tag = _StatusTag(
        label: "Skipped",
        background: AppTokens.surface3(context),
        foreground: AppTokens.ink2(context),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTokens.accentSoft(context),
              borderRadius: AppTokens.radius8,
            ),
            child: Text(
              "Q ${index + 1}",
              style: AppTokens.caption(context).copyWith(
                color: AppTokens.accent(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (tag != null) ...[
            const SizedBox(width: AppTokens.s8),
            tag,
          ],
          const Spacer(),
          _AskCortexButton(
              isProcessing: isProcessing,
              onTap: isProcessing ? null : () => onAskCortex()),
          const SizedBox(width: AppTokens.s8),
          _RaiseQueryButton(onTap: onRaiseQuery),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({
    Key? key,
    required this.label,
    required this.background,
    required this.foreground,
  }) : super(key: key);
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppTokens.radius8,
      ),
      child: Text(
        label,
        style: AppTokens.caption(context).copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AskCortexButton extends StatelessWidget {
  const _AskCortexButton(
      {Key? key, required this.isProcessing, required this.onTap})
      : super(key: key);

  final bool isProcessing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: Container(
          height: 36,
          padding:
              const EdgeInsets.symmetric(horizontal: AppTokens.s12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
            ),
            borderRadius: AppTokens.radius12,
            boxShadow: [
              BoxShadow(
                color: AppTokens.brand.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isProcessing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                isProcessing ? "Thinking..." : "Ask Cortex.AI",
                style: AppTokens.caption(context).copyWith(
                  color: Colors.white,
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

class _RaiseQueryButton extends StatelessWidget {
  const _RaiseQueryButton({Key? key, required this.onTap}) : super(key: key);
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
          height: 36,
          padding:
              const EdgeInsets.symmetric(horizontal: AppTokens.s12),
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: AppTokens.radius12,
            border: Border.all(color: AppTokens.accent(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.report_gmailerrorred_rounded,
                  color: AppTokens.accent(context), size: 16),
              const SizedBox(width: 6),
              Text(
                "Raise Query",
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

enum _OptionState { correct, incorrect, guess, neutral }

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    Key? key,
    required this.label,
    required this.text,
    required this.imageUrl,
    required this.state,
  }) : super(key: key);

  final String label;
  final String text;
  final String imageUrl;
  final _OptionState state;

  @override
  Widget build(BuildContext context) {
    Color border;
    Color background;
    Color ink;
    IconData? icon;
    switch (state) {
      case _OptionState.correct:
        border = AppTokens.success(context);
        background = AppTokens.successSoft(context);
        ink = AppTokens.success(context);
        icon = Icons.check_circle_rounded;
        break;
      case _OptionState.incorrect:
        border = AppTokens.danger(context);
        background = AppTokens.dangerSoft(context);
        ink = AppTokens.danger(context);
        icon = Icons.cancel_rounded;
        break;
      case _OptionState.guess:
        border = AppTokens.warning(context);
        background = AppTokens.warningSoft(context);
        ink = AppTokens.warning(context);
        icon = Icons.help_rounded;
        break;
      case _OptionState.neutral:
        border = AppTokens.border(context);
        background = AppTokens.surface(context);
        ink = AppTokens.ink(context);
        icon = null;
        break;
    }

    return Container(
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
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: state == _OptionState.neutral
                  ? AppTokens.surface2(context)
                  : ink.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: ink, width: 1.2),
            ),
            child: Text(
              label,
              style: AppTokens.caption(context).copyWith(
                color: ink,
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
                    color: ink,
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
          if (icon != null) ...[
            const SizedBox(width: AppTokens.s8),
            Icon(icon, color: ink, size: 22),
          ],
        ],
      ),
    );
  }
}

class _ExplanationHeader extends StatelessWidget {
  const _ExplanationHeader(
      {Key? key, required this.onNotes, required this.onFontSize})
      : super(key: key);
  final VoidCallback onNotes;
  final VoidCallback onFontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTokens.accent(context),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        Text(
          "Explanation",
          style: AppTokens.titleSm(context).copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        _ExplainIconBtn(
          icon: Icons.sticky_note_2_rounded,
          tooltip: "Stick notes",
          onTap: onNotes,
        ),
        const SizedBox(width: AppTokens.s8),
        _ExplainIconBtn(
          icon: Icons.text_fields_rounded,
          tooltip: "Font size",
          onTap: onFontSize,
        ),
      ],
    );
  }
}

class _ExplainIconBtn extends StatelessWidget {
  const _ExplainIconBtn(
      {Key? key, required this.icon, required this.tooltip, required this.onTap})
      : super(key: key);
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppTokens.surface2(context),
        borderRadius: AppTokens.radius12,
        child: InkWell(
          borderRadius: AppTokens.radius12,
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Center(
                child: Icon(icon, size: 18, color: AppTokens.ink(context))),
          ),
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({Key? key, required this.child}) : super(key: key);
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
      ),
      child: child,
    );
  }
}

class _CortexAIPanel extends StatelessWidget {
  const _CortexAIPanel({Key? key, required this.text}) : super(key: key);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            blurRadius: 18,
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
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.22),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 18, color: Colors.white),
              ),
              const SizedBox(width: AppTokens.s8),
              Text(
                "Cortex.AI",
                style: AppTokens.titleSm(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppTokens.s4),
              Text(
                "Explains",
                style: AppTokens.titleSm(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          TypeWriterText(
            text: Text(
              text,
              style: AppTokens.bodyLg(context).copyWith(
                color: Colors.white,
              ),
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
    Key? key,
    required this.firstQue,
    required this.lastQue,
    required this.isProcessing,
    required this.onPrev,
    required this.onNext,
  }) : super(key: key);

  final bool firstQue;
  final bool lastQue;
  final bool isProcessing;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          AppTokens.s16, AppTokens.s12, AppTokens.s16,
          AppTokens.s12 + MediaQuery.of(context).padding.bottom),
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
            icon: Icons.arrow_back_ios_new_rounded,
            enabled: !isProcessing && !firstQue,
            onTap: onPrev,
          ),
          const SizedBox(width: AppTokens.s16),
          _NavCircle(
            icon: Icons.arrow_forward_ios_rounded,
            enabled: !isProcessing && !lastQue,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _NavCircle extends StatelessWidget {
  const _NavCircle(
      {Key? key, required this.icon, required this.enabled, required this.onTap})
      : super(key: key);
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color tint = enabled
        ? AppTokens.accent(context)
        : AppTokens.border(context);
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

class _FontSizePanel extends StatelessWidget {
  const _FontSizePanel({
    Key? key,
    required this.currentFontSize,
    required this.showCurrFontSize,
    required this.onDecrement,
    required this.onIncrement,
    required this.onCancel,
    required this.onApply,
  }) : super(key: key);

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
      children: [
        Container(
          width: 44,
          height: 4,
          margin: const EdgeInsets.only(bottom: AppTokens.s16),
          decoration: BoxDecoration(
            color: AppTokens.border(context),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            color: AppTokens.surface2(context),
            borderRadius: AppTokens.radius16,
          ),
          child: Center(
            child: Text(
              'Sample Text',
              style: AppTokens.bodyLg(context).copyWith(
                fontSize: currentFontSize,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Font size',
                style: AppTokens.titleSm(context).copyWith(fontWeight: FontWeight.w600)),
            Row(
              children: [
                _StepBtn(
                    icon: Icons.remove_rounded, onTap: onDecrement),
                const SizedBox(width: AppTokens.s8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTokens.surface2(context),
                    borderRadius: AppTokens.radius8,
                  ),
                  child: Text(
                    '${showCurrFontSize.toInt()}%',
                    style: AppTokens.body(context)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                _StepBtn(
                    icon: Icons.add_rounded, onTap: onIncrement),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        Row(
          children: [
            Expanded(
              child: _DialogBtn(
                  label: "Cancel", outlined: true, onTap: onCancel),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: _DialogBtn(
                  label: "Apply", outlined: false, onTap: onApply),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({Key? key, required this.icon, required this.onTap})
      : super(key: key);
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surface2(context),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Center(
              child:
                  Icon(icon, size: 18, color: AppTokens.ink(context))),
        ),
      ),
    );
  }
}

class _DialogBtn extends StatelessWidget {
  const _DialogBtn(
      {Key? key,
      required this.label,
      required this.outlined,
      required this.onTap})
      : super(key: key);
  final String label;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          shape: const RoundedRectangleBorder(
              borderRadius: AppTokens.radius12),
          side: BorderSide(color: AppTokens.border(context)),
          foregroundColor: AppTokens.ink(context),
        ),
        child: Text(label,
            style: AppTokens.titleSm(context).copyWith(fontWeight: FontWeight.w600)),
      );
    }
    return Material(
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: Container(
          height: 44,
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
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
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
                  backgroundDecoration: BoxDecoration(
                    color: AppTokens.surface(context),
                  ),
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
