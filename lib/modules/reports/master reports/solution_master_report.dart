// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, use_build_context_synchronously, unused_field, avoid_print, non_constant_identifier_names, unnecessary_null_comparison, dead_code, unused_local_variable, unused_element, unnecessary_string_interpolations

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
import 'package:super_tooltip/super_tooltip.dart';
import 'package:typewritertext/typewritertext.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/app_tokens.dart';
import 'package:shusruta_lms/modules/new_exam_component/widgets/post_attempt_analytics_panel.dart';
import '../../../helpers/colors.dart';
import '../../../helpers/dimensions.dart';
import '../../../helpers/styles.dart';
import '../../../models/get_explanation_model.dart';
import '../../../models/get_notes_solution_model.dart';
import '../../../models/solution_reports_model.dart';
import '../../widgets/bottom_raise_query.dart';
import '../../widgets/bottom_stick_notes.dart';
import '../../widgets/bottom_stick_notes_window.dart';
import '../../widgets/bottom_toast.dart';
import '../../widgets/custom_bottom_sheet.dart';
import '../../widgets/custom_bottom_sheet_winow.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_topic_bottomsheet.dart';
import '../../widgets/custom_topic_bottomsheet_window.dart';
import '../explanation_common_widget.dart';
import '../store/report_by_category_store.dart';
import 'master_bottom_raise_query.dart';
import 'package:shusruta_lms/helpers/comman_widget.dart';
import 'package:shusruta_lms/models/master_solution_reports_model.dart';
import 'package:shusruta_lms/modules/masterTest/master_test_report_details_screen.dart';
import 'package:shusruta_lms/modules/notes/mobilehelper.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';

/// Mock-exam solution viewer (topic-grouped).
///
/// Preserved public contract:
///   • `SolutionMasterReportScreen({super.key, this.solutionReport,
///     required this.filter, required this.userExamId})`
///   • Static `route(RouteSettings)` reads `{solutionReport, filterVal,
///     userExamId}`.
///   • Filters: "View all" / "Correct" / "Incorrect" / "Skipped" /
///     "Marked for review" / "Guessed".
///   • Topic picker: "All topics" + each `MasterSolutionReportsModel.topicName`.
///   • Store calls: identical to regular solution report.
///   • Labels preserved verbatim (see solution_report.dart + additional:
///     "All topics", "Change Topic", "Time Spent - ...").
class SolutionMasterReportScreen extends StatefulWidget {
  final List<MasterSolutionReportsModel>? solutionReport;
  final String filter;
  final String userExamId;
  const SolutionMasterReportScreen({
    super.key,
    this.solutionReport,
    required this.filter,
    required this.userExamId,
  });

  @override
  State<SolutionMasterReportScreen> createState() =>
      _SolutionMasterReportScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => SolutionMasterReportScreen(
        solutionReport: arguments['solutionReport'],
        filter: arguments['filterVal'],
        userExamId: arguments['userExamId'],
      ),
    );
  }
}

class _SolutionMasterReportScreenState
    extends State<SolutionMasterReportScreen> {
  final QuillController _quillController = QuillController.basic();
  final ScrollController _secondController = ScrollController();
  final ScrollController _firstController = ScrollController();
  final ScrollController scrollController = ScrollController();
  final ScrollController _scrollController = ScrollController();

  String filterValue = 'View all';
  int _currentQuestionIndex = 0;
  Uint8List? answerImgBytes;
  Uint8List? quesImgBytes;
  Uint8List? explanationImgBytes;
  bool isButtonVisible = true;
  bool isButtonVisible2 = true;
  double _textSizePercent = 100;
  bool lastQue = false,
      firstQue = true,
      isBookmarked = false,
      isbutton = false,
      isprocess = false;
  List<Questions>? filteredSolutionReport;
  Widget? explanationWidget;
  Widget? questionWidget;
  final _controller = SuperTooltipController();
  Key _viewerKey = GlobalKey();
  final _topicNameKey = GlobalKey<FormFieldState<String>>();
  String selectedValue = '';
  String? topicName;
  final bool _isTopicNameValid = false;
  List<Questions>? allData = [];
  List<Questions>? filterAllData = [];
  List<Questions>? data = [];
  List<Questions>? viewAllData = [];
  double _textSize = Dimensions.fontSizeDefault;
  double showfontSize = 100;

  @override
  void initState() {
    super.initState();
    _secondController.addListener(_syncScroll);
    widget.solutionReport?.forEach((topicJson) {
      allData?.addAll(topicJson.questions as Iterable<Questions>);
    });
    allData?.sort((a, b) {
      int questionNumberA = a.questionNumber ?? 0;
      int questionNumberB = b.questionNumber ?? 0;
      return questionNumberA.compareTo(questionNumberB);
    });
    filteredSolutionReport = allData;
    filterValue = widget.filter;
    _applyFilter();
    _getNotesData(
        filteredSolutionReport?[_currentQuestionIndex].questionId ?? "");
  }

  void _syncScroll() {
    // parity retained
  }

  void _applyFilter({List<Questions>? source}) {
    final List<Questions>? base = source ?? allData;
    if (filterValue.isNotEmpty && filterValue != "View all") {
      filteredSolutionReport = base?.where((report) {
        if (filterValue == "Correct") {
          return report.isCorrect == true;
        } else if (filterValue == "Incorrect") {
          return report.isCorrect == false;
        } else if (filterValue == "Skipped") {
          return report.skipped == true;
        } else if (filterValue == "Guessed") {
          return report.guess?.isNotEmpty ?? false;
        } else if (filterValue == "Marked for review") {
          return (report.markedforreview!.isNotEmpty &&
              report.markedforreview == "true");
        }
        return false;
      }).toList();
    } else {
      filteredSolutionReport = base;
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
      isbutton = true;
      isprocess = false;
    });
  }

  void _persistAnnotation() {
    final Delta delta = _quillController.document.toDelta();
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    store.saveChangeExaplanation(context, {
      "question_id": filteredSolutionReport?[_currentQuestionIndex].questionId,
      "annotation_data": delta.toJson(),
    });
    filteredSolutionReport?[_currentQuestionIndex].isHighlight = true;
    filteredSolutionReport?[_currentQuestionIndex].annotationData =
        delta.toJson();
  }

  void _showNextQuestion() {
    scrollToTop(scrollController);
    _persistAnnotation();
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
    scrollToTop(scrollController);
    _persistAnnotation();
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

  void _questionChange(int index) {
    _persistAnnotation();
    setState(() {
      _currentQuestionIndex = index;
      isbutton = false;
      isprocess = false;
      firstQue = false;
    });
  }

  Widget getExplanationText(BuildContext context) {
    if (filteredSolutionReport == null ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= (filteredSolutionReport?.length ?? 0)) {
      return Center(
        child: Text(
          "No filtered data available",
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w400,
            color: AppTokens.ink(context),
          ),
        ),
      );
    }

    String explanation =
        filteredSolutionReport?[_currentQuestionIndex].explanation ?? "";
    explanation = explanation.replaceAllMapped(
        RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    final List<String> splittedText = explanation.split("splittedImage");
    final List<Widget> columns = [];
    int index = 0;
    for (String text in splittedText) {
      final documentContent = preprocessDocument(text);
      _quillController.document = Document.fromJson(
        filteredSolutionReport![_currentQuestionIndex].isHighlight ?? false
            ? filteredSolutionReport![_currentQuestionIndex]
                        .annotationData!
                        .toString() ==
                    "[{}]"
                ? parseCustomSyntax("""
$documentContent""")
                : filteredSolutionReport![_currentQuestionIndex]
                    .annotationData!
            : parseCustomSyntax("""
$documentContent"""),
      );

      final List<Widget> explanationImageWidget = [];
      if (filteredSolutionReport?[_currentQuestionIndex]
              .explanationImg
              ?.isNotEmpty ??
          false) {
        for (final String base64String
            in filteredSolutionReport![_currentQuestionIndex]
                .explanationImg!) {
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
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppTokens.r12),
                              child: Image.network(base64String,
                                  fit: BoxFit.cover),
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
            const SizedBox(height: AppTokens.s12),
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

  Future<String?> _getSelectedText() async {
    return null;
  }

  Widget getQuestionText(BuildContext context) {
    if (filteredSolutionReport == null ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= (filteredSolutionReport?.length ?? 0)) {
      return Center(
        child: Text(
          "No filtered data available",
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w400,
            color: AppTokens.ink(context),
          ),
        ),
      );
    }

    String questionTxt =
        filteredSolutionReport?[_currentQuestionIndex].questionText ?? "";
    questionTxt = questionTxt.replaceAllMapped(
        RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    final List<String> splittedText = questionTxt.split("splittedImage");
    final List<Widget> columns = [];
    int index = 0;
    for (String text in splittedText) {
      final List<Widget> questionImageWidget = [];
      if (filteredSolutionReport?[_currentQuestionIndex]
              .questionImg
              ?.isNotEmpty ??
          false) {
        for (final String base64String
            in filteredSolutionReport![_currentQuestionIndex].questionImg!) {
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
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppTokens.r12),
                              child: Image.network(base64String,
                                  fit: BoxFit.cover),
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
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w500,
                color: AppTokens.ink(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: questionImageWidget,
            ),
            questionImageWidget.isNotEmpty
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
          (filteredSolutionReport?[_currentQuestionIndex]
                      .questionImg
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
      backgroundColor: AppTokens.accent(context),
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
      backgroundColor: AppTokens.accent(context),
    );
  }

  void _showDialog(BuildContext context, String questionId, String questionText,
      String allOption) {
    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTokens.scaffold(context),
            actionsPadding: EdgeInsets.zero,
            actions: [
              MockBottomRaiseQuery(
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
          return MockBottomRaiseQuery(
            questionId: questionId,
            questionText: questionText,
            allOptions: allOption,
          );
        },
      );
    }
  }

  void _showNotesDialog(BuildContext context, String questionId, String notes) {
    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTokens.scaffold(context),
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

  void _scrollToIndex(int index) {
    final double dotTotal = 34.0 + 14.0;
    final double totalWidth = (filteredSolutionReport?.length ?? 0) * dotTotal;
    final double viewportWidth = MediaQuery.of(context).size.width;
    double maxScrollExtent =
        (totalWidth - viewportWidth).clamp(0.0, double.infinity);
    double target = (index * dotTotal).clamp(0.0, maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
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
    const items = [
      'View all',
      'Correct',
      'Incorrect',
      'Skipped',
      'Marked for review',
      'Guessed'
    ];

    void apply(String? selectedValued) {
      if (selectedValued == null) return;
      setState(() {
        filterValue = selectedValued;
        _currentQuestionIndex = 0;
        if (selectedValue.isEmpty || selectedValue == "All topics") {
          _applyFilter();
        } else {
          widget.solutionReport?.forEach((topicJson) {
            if (topicJson.topicName == selectedValue) {
              filterAllData?.clear();
              filterAllData
                  ?.addAll(topicJson.questions as Iterable<Questions>);
            }
          });
          _applyFilter(source: filterAllData);
        }
        firstQue = true;
        isbutton = false;
        lastQue = false;
      });
    }

    if (Platform.isWindows || Platform.isMacOS) {
      showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTokens.scaffold(context),
            actionsPadding: EdgeInsets.zero,
            actions: [
              CustomBottomSheetWindow(
                selectedVal: filterValue,
                radioItems: items,
              ),
            ],
          );
        },
      ).then(apply);
    } else {
      showModalBottomSheet<String>(
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTokens.r28)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context) {
          return CustomBottomSheet(
            heightSize: MediaQuery.of(context).size.height * 0.6,
            selectedVal: filterValue,
            radioItems: items,
          );
        },
      ).then(apply);
    }
  }

  void _openTopicSheet(List<String> changeTopic) {
    void apply(String? selectedValued) {
      if (selectedValued == null) return;
      setState(() {
        isbutton = false;
        selectedValue = selectedValued;
        if (selectedValue == "All topics") {
          filteredSolutionReport = allData;
        } else {
          for (var topicJson in widget.solutionReport ?? []) {
            if (topicJson.topicName == selectedValue) {
              data?.clear();
              data?.addAll(topicJson.questions as Iterable<Questions>);
              break;
            }
          }
          filteredSolutionReport = data;
        }
        firstQue = true;
        isbutton = false;
        lastQue = false;
        _currentQuestionIndex = 0;
        filterValue = 'View all';
      });
    }

    if (Platform.isWindows || Platform.isMacOS) {
      showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTokens.scaffold(context),
            actionsPadding: EdgeInsets.zero,
            actions: [
              CustomTopicBottomSheetWindow(
                heightSize: MediaQuery.of(context).size.height * 0.56,
                selectedVal: selectedValue,
                radioItems: changeTopic,
              ),
            ],
          );
        },
      ).then(apply);
    } else {
      showModalBottomSheet<String>(
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTokens.r28)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return CustomTopicBottomSheet(
            heightSize: MediaQuery.of(context).size.height * 0.4,
            selectedVal: selectedValue,
            radioItems: changeTopic,
          );
        },
      ).then(apply);
    }
  }

  void _openAskFaculty({bool useMock = true}) {
    final q = filteredSolutionReport?[_currentQuestionIndex];
    final allOptions =
        "a) ${q?.options?[0].answerTitle}\nb) ${q?.options?[1].answerTitle}\nc) ${q?.options?[2].answerTitle}\nd) ${q?.options?[3].answerTitle}";

    Widget buildSheet() => useMock
        ? MockBottomAskFaculty(
            questionId: q?.questionId ?? "",
            questionText: q?.questionText ?? '',
            allOptions: allOptions,
          )
        : CustomBottomAskFaculty(
            questionId: q?.questionId ?? "",
            questionText: q?.questionText ?? '',
            allOptions: allOptions,
          );

    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTokens.scaffold(context),
            actionsPadding: EdgeInsets.zero,
            actions: [buildSheet()],
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
        builder: (BuildContext context) => buildSheet(),
      );
    }
  }

  void _openReportIssue({bool useMock = true}) {
    final q = filteredSolutionReport?[_currentQuestionIndex];
    final allOptions =
        "a) ${q?.options?[0].answerTitle}\nb) ${q?.options?[1].answerTitle}\nc) ${q?.options?[2].answerTitle}\nd) ${q?.options?[3].answerTitle}";

    Widget buildSheet() => useMock
        ? MockBottomReportIssue(
            questionId: q?.questionId ?? "",
            questionText: q?.questionText ?? '',
            allOptions: allOptions,
          )
        : CustomBottomReportIssue(
            questionId: q?.questionId ?? "",
            questionText: q?.questionText ?? '',
            allOptions: allOptions,
          );

    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTokens.scaffold(context),
            actionsPadding: EdgeInsets.zero,
            actions: [buildSheet()],
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
        builder: (BuildContext context) => buildSheet(),
      );
    }
  }

  Future<void> _triggerAiExplain() async {
    if (!isbutton) {
      setState(() {
        isprocess = true;
      });
    }
    final Questions? solutionReport =
        filteredSolutionReport?[_currentQuestionIndex];

    final questionText = solutionReport?.questionText;
    final currentOption = solutionReport?.correctOption;
    final answerTitle = solutionReport?.options?.map((e) => e.answerTitle);
    final int currentIndex = solutionReport?.options
            ?.indexWhere((e) => e.value == currentOption) ??
        -1;
    final String? currentAnswerTitle = answerTitle?.elementAt(currentIndex);
    final List<String?> notMatchingAnswerTitles = answerTitle
            ?.where((title) => title != currentAnswerTitle)
            .toList() ??
        [];
    final String concatenatedTitles = notMatchingAnswerTitles
        .where((title) => title != null)
        .join(", ");

    final String question =
        "Explain why $currentAnswerTitle is the answer to the Question $questionText and why the remaining $concatenatedTitles are not correct answer";
    if (isbutton == false) {
      await _getExplanationData(question);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    explanationWidget = getExplanationText(context);
    questionWidget = getQuestionText(context);

    final List<String> changeTopic = [
      'All topics',
      ...(widget.solutionReport?.map((e) => e.topicName).toList() ?? [])
          .cast<String>()
    ];

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: (filteredSolutionReport?.isEmpty ?? true)
                ? _buildEmpty(context)
                : SingleChildScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppTokens.s12),
                        _buildQuestionDots(),
                        const SizedBox(height: AppTokens.s12),
                        _buildTopicBar(changeTopic),
                        _buildTimeSpent(),
                        _buildMetaRow(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTokens.s20,
                            AppTokens.s8,
                            AppTokens.s20,
                            AppTokens.s8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              questionWidget ?? const SizedBox(),
                              const SizedBox(height: AppTokens.s8),
                              _buildOptionsList(),
                              const SizedBox(height: AppTokens.s16),
                              _buildExplanationHeader(store),
                              const SizedBox(height: AppTokens.s8),
                              explanationWidget ?? const SizedBox(),
                              const SizedBox(height: AppTokens.s12),
                              if (isbutton)
                                _buildAiExplainCard(store)
                              else
                                const SizedBox(),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (filteredSolutionReport?.isNotEmpty ?? false)
            _buildBottomNavBar(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTokens.s8,
        left: AppTokens.s8,
        right: AppTokens.s16,
        bottom: AppTokens.s12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(AppTokens.r8),
            child: Container(
              height: AppTokens.s32,
              width: AppTokens.s32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              "Solutions",
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Wave-2 Insights button — opens PostAttemptAnalyticsPanel.
          if (widget.userExamId.isNotEmpty) ...[
            InkWell(
              onTap: () => _openInsights(context),
              borderRadius: BorderRadius.circular(AppTokens.r8),
              child: Container(
                height: AppTokens.s32,
                width: AppTokens.s32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s8),
          ],
          InkWell(
            onTap: _openFilterSheet,
            borderRadius: BorderRadius.circular(AppTokens.r8),
            child: Container(
              height: AppTokens.s32,
              width: AppTokens.s32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 56, color: AppTokens.muted(context)),
            const SizedBox(height: AppTokens.s16),
            Text(
              "No filtered data available",
              textAlign: TextAlign.center,
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w500,
                color: AppTokens.ink(context),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionDots() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children:
              List.generate(filteredSolutionReport?.length ?? 0, (index) {
            final Questions? solutionReport = filteredSolutionReport?[index];
            final bool isCorrect =
                (solutionReport?.correctOption ?? "") ==
                    (solutionReport?.selectedOption ?? "");
            final Color stateColor = isCorrect
                ? ThemeManager.greenSuccess
                : ThemeManager.redAlert;
            final bool isActive = _currentQuestionIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: AppTokens.s8),
              child: GestureDetector(
                onTap: () => _questionChange(index),
                child: Container(
                  height: 34,
                  width: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? stateColor : AppTokens.surface(context),
                    shape: BoxShape.circle,
                    border: Border.all(color: stateColor, width: 1.2),
                  ),
                  child: Text(
                    "${filteredSolutionReport?[index].questionNumber}",
                    style: AppTokens.caption(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : stateColor,
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

  Widget _buildTopicBar(List<String> changeTopic) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        0,
        AppTokens.s20,
        AppTokens.s8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              selectedValue.isNotEmpty
                  ? selectedValue
                  : "${filteredSolutionReport?[_currentQuestionIndex].topicName}",
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          InkWell(
            onTap: () => _openTopicSheet(changeTopic),
            borderRadius: BorderRadius.circular(AppTokens.r8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Change Topic",
                    style: AppTokens.caption(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTokens.accent(context),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down_outlined,
                    color: AppTokens.accent(context),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSpent() {
    final q = filteredSolutionReport?[_currentQuestionIndex];
    if (q?.timePerQuestion == null || q?.timePerQuestion == "") {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        AppTokens.s4,
        AppTokens.s20,
        AppTokens.s8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, color: AppTokens.muted(context), size: 18),
          const SizedBox(width: 5),
          Text(
            "Time Spent - ${formatTimeString(q?.timePerQuestion?.toString() ?? "00:00:00")}",
            style: AppTokens.body(context).copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: AppTokens.muted(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    final q = filteredSolutionReport?[_currentQuestionIndex];
    final bool isGuessed = (q?.guess ?? "") != "";
    final bool isSkipped = q?.skipped == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        0,
        AppTokens.s20,
        AppTokens.s12,
      ),
      child: Row(
        children: [
          Text(
            "${_currentQuestionIndex + 1}.",
            style: AppTokens.titleSm(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.ink(context),
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          if (isGuessed)
            _StatusPill(
              label: "Guessed",
              color: ThemeManager.skipColor,
              textColor: AppTokens.ink(context),
            )
          else if (isSkipped)
            _StatusPill(
              label: "Skipped",
              color: ThemeManager.skipColor,
              textColor: AppTokens.ink(context),
            ),
          const Spacer(),
          VisibilityDetector(
            key: const Key('button-key2'),
            onVisibilityChanged: (info) {
              setState(() {
                isButtonVisible2 = info.visibleFraction > 0;
              });
            },
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    if (filteredSolutionReport != null &&
                        _currentQuestionIndex >= 0 &&
                        _currentQuestionIndex <
                            (filteredSolutionReport?.length ?? 0)) {
                      putBookMarkApiCall(
                        filteredSolutionReport?[_currentQuestionIndex]
                                .examId ??
                            "",
                        filteredSolutionReport?[_currentQuestionIndex]
                            .questionId,
                        "",
                      );
                    }
                  },
                  child: BookmarkWidget(
                    isSelected:
                        filteredSolutionReport?[_currentQuestionIndex]
                                .bookmarks ??
                            false,
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                _IconAction(
                  onTap: () => _openAskFaculty(useMock: true),
                  asset: 'assets/image/support.svg',
                ),
                const SizedBox(width: AppTokens.s12),
                _IconAction(
                  onTap: () => _openReportIssue(useMock: true),
                  asset: 'assets/image/message.svg',
                ),
                const SizedBox(width: AppTokens.s12),
                _IconAction(
                  onTap: _triggerAiExplain,
                  asset: 'assets/image/ai.svg',
                  loading: isprocess,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsList() {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s8),
      itemCount:
          filteredSolutionReport?[_currentQuestionIndex].options?.length ?? 0,
      itemBuilder: (BuildContext context, int index) {
        final Questions? solutionReport =
            filteredSolutionReport?[_currentQuestionIndex];
        final String optionValue =
            solutionReport?.options?[index].value ?? "";
        final bool isCorrect =
            (solutionReport?.correctOption ?? "") == optionValue;
        final bool isSelected =
            (solutionReport?.selectedOption ?? "") == optionValue;
        final bool isGuess = (solutionReport?.guess ?? "") == optionValue;

        Color borderColor;
        Color fillColor;
        Color textColor;
        String? tag;
        if (isCorrect) {
          borderColor = ThemeManager.greenSuccess;
          fillColor = ThemeManager.greenSuccess.withOpacity(0.08);
          textColor = ThemeManager.greenSuccess;
          tag = "Correct Answer";
        } else if (isSelected) {
          borderColor = ThemeManager.redAlert;
          fillColor = ThemeManager.redAlert.withOpacity(0.08);
          textColor = ThemeManager.redAlert;
          tag = "Incorrect Answer";
        } else if (isGuess) {
          borderColor = Colors.brown;
          fillColor = Colors.brown.withOpacity(0.08);
          textColor = Colors.brown;
          tag = "Guess";
        } else {
          borderColor = AppTokens.border(context);
          fillColor = AppTokens.surface(context);
          textColor = AppTokens.ink(context);
          tag = null;
        }

        final String base64String =
            solutionReport?.options?[index].answerImg ?? "";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: fillColor,
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
                      Text(
                        "$optionValue. ",
                        style: AppTokens.body(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          solutionReport?.options?[index].answerTitle ?? "",
                          style: AppTokens.body(context).copyWith(
                            fontWeight: FontWeight.w500,
                            color: textColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: AppTokens.s8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: borderColor.withOpacity(0.16),
                            borderRadius:
                                BorderRadius.circular(AppTokens.r8),
                          ),
                          child: Text(
                            tag,
                            style: AppTokens.caption(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: borderColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (base64String.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.s8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTokens.r8),
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 3.0,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: 200,
                          child: Image.network(base64String,
                              fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _buildPercentageLine(solutionReport, index),
          ],
        );
      },
    );
  }

  Widget _buildPercentageLine(Questions? solutionReport, int index) {
    final String optionValue = solutionReport?.options?[index].value ?? "";
    final bool isCorrect =
        (solutionReport?.correctOption ?? "") == optionValue;
    final bool isSelected =
        (solutionReport?.selectedOption ?? "") == optionValue;
    final String pct = solutionReport?.options?[index].percentage ?? "0";

    if (isCorrect) {
      return Padding(
        padding: const EdgeInsets.only(top: 6.0, left: AppTokens.s16),
        child: Text(
          "$pct% Got this answer correct",
          style: AppTokens.caption(context).copyWith(
            color: ThemeManager.greenSuccess,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (isSelected) {
      return Padding(
        padding: const EdgeInsets.only(top: 6.0, left: AppTokens.s16),
        child: Text(
          "$pct% Marked this incorrect",
          style: AppTokens.caption(context).copyWith(
            color: ThemeManager.redAlert,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 6.0, left: AppTokens.s16),
        child: Text(
          "$pct% Marked this",
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.muted(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }

  Widget _buildExplanationHeader(ReportsCategoryStore store) {
    return VisibilityDetector(
      key: const Key('button-key'),
      onVisibilityChanged: (info) {
        setState(() {
          isButtonVisible = info.visibleFraction > 0;
        });
      },
      child: Observer(
        builder: (BuildContext context) {
          final GetNotesSolutionModel? noteModel = store.notesData.value;
          return Row(
            children: [
              Text(
                "Explanation:",
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink(context),
                ),
              ),
              const Spacer(),
              CommonTool(
                onTap: _persistAnnotation,
                controller: _quillController,
              ),
              const SizedBox(width: AppTokens.s8),
              GestureDetector(
                onTap: () {
                  _showNotesDialog(
                    context,
                    filteredSolutionReport?[_currentQuestionIndex]
                            .questionId ??
                        "",
                    noteModel?.notes ?? "",
                  );
                },
                child: SvgPicture.asset(
                  "assets/image/notes1.svg",
                  colorFilter: ColorFilter.mode(
                    AppTokens.ink(context),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              GestureDetector(
                onTap: () => _showBottomSheet(context),
                child: SvgPicture.asset(
                  "assets/image/atoz.svg",
                  colorFilter: ColorFilter.mode(
                    AppTokens.ink(context),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAiExplainCard(ReportsCategoryStore store) {
    return Observer(
      builder: (BuildContext context) {
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
            borderRadius: BorderRadius.circular(AppTokens.r16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
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
                    style: AppTokens.titleSm(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Explains",
                    style: AppTokens.titleSm(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              TypeWriterText(
                text: Text(
                  getExplainModel?.text ?? '',
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.5,
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

  Widget _buildBottomNavBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          border: Border(
            top: BorderSide(color: AppTokens.border(context)),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s12,
          AppTokens.s20,
          AppTokens.s12,
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: isprocess || firstQue ? null : _showPreviousQuestion,
                borderRadius: BorderRadius.circular(AppTokens.r12),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.surface(context),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                    border: Border.all(color: AppTokens.border(context)),
                  ),
                  child: Text(
                    "Previous",
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: firstQue
                          ? AppTokens.muted(context)
                          : AppTokens.ink(context),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: InkWell(
                onTap: isprocess || lastQue ? null : _showNextQuestion,
                borderRadius: BorderRadius.circular(AppTokens.r12),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: lastQue
                          ? [
                              AppTokens.muted(context),
                              AppTokens.muted(context),
                            ]
                          : [AppTokens.brand, AppTokens.brand2],
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                  ),
                  child: Text(
                    "Next",
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
      ),
    );
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
            backgroundColor: AppTokens.scaffold(context),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return _FontSizeContent(
                  currentFontSize: currentFontSize,
                  showCurrFontSize: showCurrFontSize,
                  onDec: () {
                    setModalState(() {
                      if (showCurrFontSize > 50) {
                        showCurrFontSize -= 10;
                        currentPercentFontSize -= 10;
                        currentFontSize -= 1;
                      }
                    });
                  },
                  onInc: () {
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
      final dynamic selectedFontSize = await showDialog<dynamic>(
        context: context,
        builder: (BuildContext context) {
          double currentFontSize = _textSize;
          double currentPercentFontSize = _textSizePercent;
          double showCurrFontSize = showfontSize;
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.r20),
            ),
            elevation: 10,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40),
            backgroundColor: AppTokens.surface(context),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return _FontSizeDialogBody(
                  currentFontSize: currentFontSize,
                  showCurrFontSize: showCurrFontSize,
                  onDec: () {
                    setModalState(() {
                      if (showCurrFontSize > 50) {
                        showCurrFontSize -= 10;
                        currentPercentFontSize -= 10;
                        currentFontSize -= 1;
                      }
                    });
                  },
                  onInc: () {
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

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _StatusPill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(60),
      ),
      child: Text(
        label,
        style: AppTokens.caption(context).copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final VoidCallback onTap;
  final String asset;
  final bool loading;
  const _IconAction({
    required this.onTap,
    required this.asset,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.r8),
      onTap: onTap,
      child: Container(
        height: 32,
        width: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTokens.surface2(context),
          borderRadius: BorderRadius.circular(AppTokens.r8),
        ),
        child: loading
            ? CupertinoActivityIndicator(color: AppTokens.ink(context))
            : SvgPicture.asset(asset),
      ),
    );
  }
}

class _FontSizeContent extends StatelessWidget {
  final double currentFontSize;
  final double showCurrFontSize;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback onCancel;
  final VoidCallback onApply;
  const _FontSizeContent({
    required this.currentFontSize,
    required this.showCurrFontSize,
    required this.onDec,
    required this.onInc,
    required this.onCancel,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 4,
          decoration: BoxDecoration(
            color: AppTokens.muted(context).withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        Container(
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            color: AppTokens.surface2(context),
            borderRadius: BorderRadius.circular(AppTokens.r12),
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
        const SizedBox(height: AppTokens.s12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Font size',
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w400,
                color: AppTokens.ink(context),
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: onDec,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppTokens.muted(context),
                ),
                Text(
                  '$showCurrFontSize',
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.ink(context),
                  ),
                ),
                IconButton(
                  onPressed: onInc,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppTokens.muted(context),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomButton(
              onPressed: onCancel,
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
              onPressed: onApply,
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
  }
}

class _FontSizeDialogBody extends StatelessWidget {
  final double currentFontSize;
  final double showCurrFontSize;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback onCancel;
  final VoidCallback onApply;
  const _FontSizeDialogBody({
    required this.currentFontSize,
    required this.showCurrFontSize,
    required this.onDec,
    required this.onInc,
    required this.onCancel,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: AppTokens.s12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTokens.border(context)),
              ),
            ),
            child: Text(
              'Adjust Font Size',
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Container(
            padding: const EdgeInsets.all(AppTokens.s20),
            decoration: BoxDecoration(
              color: AppTokens.surface2(context),
              borderRadius: BorderRadius.circular(AppTokens.r12),
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
                'Font Size',
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTokens.ink(context),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: onDec,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppTokens.muted(context),
                  ),
                  Text(
                    '$showCurrFontSize',
                    style: AppTokens.body(context).copyWith(
                      color: AppTokens.ink(context),
                    ),
                  ),
                  IconButton(
                    onPressed: onInc,
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppTokens.muted(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          Divider(height: 1, color: AppTokens.border(context)),
          const SizedBox(height: AppTokens.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomButton(
                  onPressed: onCancel,
                  buttonText: "Cancel",
                  height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                  radius: Dimensions.RADIUS_DEFAULT,
                  transparent: true,
                  bgColor: ThemeManager.btnGrey,
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: CustomButton(
                  onPressed: onApply,
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
  }
}
