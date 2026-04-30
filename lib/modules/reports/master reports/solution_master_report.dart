import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:shusruta_lms/services/daily_review_recorder.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_svg/svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/comman_widget.dart';
import 'package:shusruta_lms/models/master_solution_reports_model.dart';
import 'package:shusruta_lms/modules/masterTest/master_test_report_details_screen.dart';
import 'package:shusruta_lms/modules/new_exam_component/widget/custome_exam_button.dart';
import 'package:shusruta_lms/modules/notes/mobilehelper.dart';
import 'package:shusruta_lms/modules/reports/explanation_common_widget.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/widgets/bottom_stick_notes_window.dart';
import 'package:shusruta_lms/modules/widgets/custom_bottom_sheet_winow.dart';
import 'package:shusruta_lms/modules/widgets/custom_topic_bottomsheet_window.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:typewritertext/typewritertext.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/colors.dart';
import '../../../helpers/dimensions.dart';
import '../../../helpers/styles.dart';
import '../../../models/get_explanation_model.dart';
import '../../../models/get_notes_solution_model.dart';
import '../../widgets/bottom_raise_query.dart';
import '../../widgets/bottom_stick_notes.dart';
import '../../widgets/bottom_toast.dart';
import '../../widgets/custom_bottom_sheet.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_topic_bottomsheet.dart';
import 'master_bottom_raise_query.dart';

class SolutionMasterReportScreen extends StatefulWidget {
  final List<MasterSolutionReportsModel>? solutionReport;
  final String filter;
  final String userExamId;
  const SolutionMasterReportScreen(
      {super.key, this.solutionReport, required this.filter, required this.userExamId});

  @override
  State<SolutionMasterReportScreen> createState() => _SolutionMasterReportScreenState();
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

class _SolutionMasterReportScreenState extends State<SolutionMasterReportScreen> {
  late QuillController _quillController = QuillController.basic();
  final ScrollController _secondController = ScrollController();
  final ScrollController _firstController = ScrollController();
  String filterValue = 'View all';
  int _currentQuestionIndex = 0;
  Uint8List? answerImgBytes;
  final ScrollController scrollController = ScrollController();
  Uint8List? quesImgBytes;
  Uint8List? explanationImgBytes;
  bool isButtonVisible = true;
  bool isButtonVisible2 = true;
  double _textSizePercent = 100;
  bool lastQue = false, firstQue = true, isBookmarked = false, isbutton = false, isprocess = false;
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
    // Print the modified data
    allData?.sort((a, b) {
      int questionNumberA = a.questionNumber ?? 0;
      int questionNumberB = b.questionNumber ?? 0;

      return questionNumberA.compareTo(questionNumberB);
    });
    print("allData:$allData");
    filteredSolutionReport = allData;
    filterValue = widget.filter;
    if (filterValue.isNotEmpty && filterValue != "View all") {
      filteredSolutionReport = allData?.where((report) {
        log(filterValue);
        if (filterValue == "Correct") {
          return report.isCorrect == true;
        } else if (filterValue == "Incorrect") {
          return report.isCorrect == false;
        } else if (filterValue == "Skipped") {
          return report.skipped == true;
        } else if (filterValue == "Guessed") {
          return report.guess?.isNotEmpty ?? false;
        } else if (filterValue == "Marked for review") {
          return (report.markedforreview!.isNotEmpty && report.markedforreview == "true");
        }
        return false;
      }).toList();
    } else {
      filteredSolutionReport = allData;
    }
    _getNotesData(filteredSolutionReport?[_currentQuestionIndex].questionId ?? "");

    // Sync entire master/mock report into daily-review pools.
    if (allData != null) {
      // ignore: discarded_futures
      DailyReviewRecorder.ingestMasterReport(allData);
    }
  }

  Future<void> _getNotesData(String queId) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onGetNotesData(queId);
  }

  Future<void> _getExplanationData(String prompt) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onGetExplanationCall(prompt);
    debugPrint("store.getExplanationText.value:${store.getExplanationText.value?.text}");
    setState(() {
      isbutton = true;
      isprocess = false;
    });
  }

  void _syncScroll() {
    // if (_secondController.offset <= 0 && !_secondController.position.outOfRange) {
    //   _firstController.animateTo(
    //     _firstController.offset - 100, // Adjust this based on your requirement
    //     duration: Duration(milliseconds: 300),
    //     curve: Curves.easeInOut,
    //   );
    // }
  }

  void _showNextQuestion() {
    scrollToTop(scrollController);
    debugPrint("solution${filteredSolutionReport?.map((e) => e.skipped)}");
    Delta delta = _quillController.document.toDelta();
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    store.saveChangeExaplanation(context, {
      "question_id": filteredSolutionReport?[_currentQuestionIndex].questionId,
      "annotation_data": delta.toJson()
    });
    filteredSolutionReport?[_currentQuestionIndex].isHighlight = true;
    filteredSolutionReport?[_currentQuestionIndex].annotationData = delta.toJson();
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

    _getNotesData(filteredSolutionReport?[_currentQuestionIndex].questionId ?? "");
  }

  void _showPreviousQuestion() {
    scrollToTop(scrollController);
    Delta delta = _quillController.document.toDelta();
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    store.saveChangeExaplanation(context, {
      "question_id": filteredSolutionReport?[_currentQuestionIndex].questionId,
      "annotation_data": delta.toJson()
    });
    filteredSolutionReport?[_currentQuestionIndex].isHighlight = true;
    filteredSolutionReport?[_currentQuestionIndex].annotationData = delta.toJson();
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
    _getNotesData(filteredSolutionReport?[_currentQuestionIndex].questionId ?? "");
  }

  Widget getExplanationText(BuildContext context) {
    if (filteredSolutionReport == null ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= (filteredSolutionReport?.length ?? 0)) {
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

    String explanation = filteredSolutionReport?[_currentQuestionIndex].explanation ?? "";
    explanation =
        explanation.replaceAllMapped(RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    List<String> splittedText = explanation.split("splittedImage");
    List<Widget> columns = [];
    int index = 0;
    for (String text in splittedText) {
      final documentContent = preprocessDocument(text);

      _quillController.document =
          Document.fromJson(filteredSolutionReport![_currentQuestionIndex].isHighlight ?? false
              ? filteredSolutionReport![_currentQuestionIndex].annotationData!.toString() == "[{}]"
                  ? parseCustomSyntax("""
$documentContent""")
                  : filteredSolutionReport![_currentQuestionIndex].annotationData!
              : parseCustomSyntax("""
$documentContent"""));

      List<Widget> explanationImageWidget = [];
      if (filteredSolutionReport?[_currentQuestionIndex].explanationImg?.isNotEmpty ?? false) {
        for (String base64String in filteredSolutionReport![_currentQuestionIndex].explanationImg!) {
          try {
            // Uint8List explanationImgBytes = base64Decode(base64String);
            explanationImageWidget.add(
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        child: PhotoView(
                          // imageProvider: MemoryImage(explanationImgBytes),
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
                        // minScale: 1.0,
                        // maxScale: 3.0,
                        scaleEnabled: false,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            // width: MediaQuery.of(context).size.width,
                            // height: MediaQuery.of(context).size.height * 0.3,
                            child: Stack(
                              children: [
                                // Image.memory(explanationImgBytes),
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
            // Html(
            //   data:  text.replaceAll("			--", "                 •").replaceAll("		--", "           •").replaceAll("	--", "     •").replaceAll("--", "•"),
            // ),
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
              textPercentage: _textSizePercent.toInt(),
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
                      fontSize: Dimensions.fontSizeSmall * (_textSizePercent / 100),
                      fontWeight: FontWeight.w400,
                      color: ThemeManager.black,
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      );
      index++;

      if (index >= (filteredSolutionReport?[_currentQuestionIndex].explanationImg?.length ?? 0) - 1) {
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns,
    );
  }

  // Widget getExplanationText(BuildContext context) {
  //   if (filteredSolutionReport == null ||
  //       _currentQuestionIndex < 0 ||
  //       _currentQuestionIndex >= filteredSolutionReport!.length) {
  //     return const Center(
  //       child: Text("No data available"),
  //     );
  //   }
  //
  //   final currentData = filteredSolutionReport![_currentQuestionIndex];
  //
  //   List<Widget> columns = [];
  //
  //   /// TEXT
  //   String explanation = currentData.explanation ?? "";
  //   final documentContent = preprocessDocument(explanation);
  //
  //   Document document;
  //
  //   /// ✅ ⭐ MOST IMPORTANT PART
  //   if (currentData.annotationData != null &&
  //       currentData.annotationData!.isNotEmpty &&
  //       currentData.annotationData.toString() != "[{}]") {
  //     try {
  //       document = Document.fromJson(currentData.annotationData!);
  //       debugPrint("✅ Loaded SAVED annotation");
  //     } catch (e) {
  //       debugPrint("❌ Error loading annotation: $e");
  //
  //       final parsed = parseCustomSyntax(documentContent);
  //       document = parsed.isEmpty
  //           ? (Document()..insert(0, "No explanation available\n"))
  //           : Document.fromJson(parsed);
  //     }
  //   } else {
  //     final parsed = documentContent.trim().isEmpty ? null : parseCustomSyntax(documentContent);
  //
  //     document = (parsed == null || parsed.isEmpty)
  //         ? (Document()..insert(0, "No explanation available\n"))
  //         : Document.fromJson(parsed);
  //
  //     debugPrint("⚪ Loaded ORIGINAL content  ${parsed}");
  //   }
  //
  //   /// ✅ IMPORTANT: recreate controller with document
  //
  //   columns.add(
  //     CommonExplanationWidget(
  //       textPercentage: _textSizePercent.toInt(),
  //       controller: _quillController,
  //     ),
  //   );
  //
  //   /// IMAGES
  //   if (currentData.explanationImg != null && currentData.explanationImg!.isNotEmpty) {
  //     columns.add(const SizedBox(height: 12));
  //
  //     columns.add(
  //       Column(
  //         children: currentData.explanationImg!.map<Widget>((imageUrl) {
  //           return Padding(
  //             padding: const EdgeInsets.only(bottom: 8),
  //             child: GestureDetector(
  //               onTap: () {
  //                 showDialog(
  //                   context: context,
  //                   builder: (_) => Dialog(
  //                     child: PhotoView(
  //                       imageProvider: NetworkImage(imageUrl),
  //                     ),
  //                   ),
  //                 );
  //               },
  //               child: Image.network(imageUrl),
  //             ),
  //           );
  //         }).toList(),
  //       ),
  //     );
  //   }
  //
  //   return SingleChildScrollView(
  //     child: Column(children: columns),
  //   );
  // }

  Future<String?> _getSelectedText() async {
    return null;

    // final TextSelection? selection = WidgetsBinding.instance.platformDispatcher.textInputClient?.currentTextEditingValue?.selection;
    // if (selection != null && selection.start >= 0 && selection.end > selection.start) {
    //   final selectedText = filteredSolutionReport![_currentQuestionIndex]
    //                                       .explanation ??
    //                                   "".substring(selection.start, selection.end);
    //   return selectedText;
    // }
    // return null;
  }

  Widget getQuestionText(BuildContext context) {
    if (filteredSolutionReport == null ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= (filteredSolutionReport?.length ?? 0)) {
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

    String questionTxt = filteredSolutionReport?[_currentQuestionIndex].questionText ?? "";
    questionTxt =
        questionTxt.replaceAllMapped(RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    List<String> splittedText = questionTxt.split("splittedImage");
    List<Widget> columns = [];
    int index = 0;
    for (String text in splittedText) {
      List<Widget> questionImageWidget = [];
      if (filteredSolutionReport?[_currentQuestionIndex].questionImg?.isNotEmpty ?? false) {
        for (String base64String in filteredSolutionReport![_currentQuestionIndex].questionImg!) {
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
            const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: questionImageWidget,
            ),
            if (questionImageWidget.isNotEmpty) ...[
              const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
            ],
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

      if (index >= (filteredSolutionReport?[_currentQuestionIndex].questionImg?.length ?? 0) - 1) {
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns,
    );
  }

  Future<void> putBookMarkApiCall(String examId, String? questionId, String? bookMarkNote) async {
    setState(() {
      filteredSolutionReport?[_currentQuestionIndex].bookmarks =
          !(filteredSolutionReport?[_currentQuestionIndex].bookmarks ?? false);
    });

    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    final isBookmarkedNow =
        filteredSolutionReport?[_currentQuestionIndex].bookmarks ?? false;
    await store.onBookMarkQuestion(
        context, isBookmarkedNow, examId, questionId ?? "", bookMarkNote);
    final q = filteredSolutionReport?[_currentQuestionIndex];
    if (q != null) {
      // ignore: discarded_futures
      DailyReviewRecorder.bookmarkToggleMaster(q, isBookmarkedNow);
    }
    BottomToast.showBottomToastOverlay(
      context: context,
      errorMessage: isBookmarkedNow
          ? "Question Bookmarked Successfully!"
          : "Bookmark Removed!",
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  Future<void> addNotes(String? questionId, String? notes) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onCreateNotes(context, questionId ?? "", notes ?? "");
    _getNotesData(filteredSolutionReport?[_currentQuestionIndex].questionId ?? "");
    BottomToast.showBottomToastOverlay(
      context: context,
      errorMessage: "Notes Added Successfully!",
      backgroundColor: Theme.of(context).primaryColor,
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

  void _showDialog(BuildContext context, String questionId, String questionText, String allOption) {
    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (BuildContext context) {
    //     TextEditingController queryController = TextEditingController();
    //     String errorText = '';
    //
    //     return AlertDialog(
    //       title: Text('Have a Query?',
    //         style: interRegular.copyWith(
    //           fontSize: Dimensions.fontSizeExtraLarge,
    //           fontWeight: FontWeight.w500,
    //           color: ThemeManager.black,
    //         ),),
    //       content: Form(
    //         child: SizedBox(
    //           width: MediaQuery.of(context).size.width * 0.9,
    //           height: MediaQuery.of(context).size.height * 0.2,
    //           child: TextFormField(
    //             cursorColor: Theme.of(context).primaryColor,
    //             controller: queryController,
    //             maxLines: 7,
    //             decoration: InputDecoration(
    //               enabledBorder: UnderlineInputBorder(
    //                 borderSide: BorderSide(color: Theme.of(context).primaryColor),
    //               ),
    //               focusedBorder: UnderlineInputBorder(
    //                 borderSide: BorderSide(color:Theme.of(context).primaryColor),
    //               ),
    //               hintText: 'Enter your query...',
    //               hintStyle: interRegular.copyWith(
    //                 fontSize: Dimensions.fontSizeLarge,
    //                 fontWeight: FontWeight.w400,
    //                 color: Theme.of(context).hintColor,
    //               ),
    //               errorText: 'Please enter your query',
    //               errorStyle: interRegular.copyWith(
    //                 fontSize: Dimensions.fontSizeLarge,
    //                 fontWeight: FontWeight.w400,
    //                 color: Theme.of(context).hintColor,
    //               ),
    //             ),
    //             style: interRegular.copyWith(
    //               fontSize: Dimensions.fontSizeLarge,
    //               fontWeight: FontWeight.w400,
    //               color: ThemeManager.black,
    //             ),
    //           ),
    //         ),
    //       ),
    //       actions: [
    //         Row(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             SizedBox(
    //               height: Dimensions.PADDING_SIZE_LARGE * 2,
    //               child: ElevatedButton(
    //                 onPressed: () {
    //                   Navigator.of(context).pop();
    //                 },
    //                 style: ElevatedButton.styleFrom(
    //                     shape: RoundedRectangleBorder(
    //                       borderRadius: BorderRadius.circular(8),
    //                     ),
    //                     backgroundColor: Theme.of(context).hintColor
    //                 ),
    //                 child: Text('Cancel',
    //                   style: interRegular.copyWith(
    //                     fontSize: Dimensions.fontSizeLarge,
    //                     fontWeight: FontWeight.w400,
    //                     color: Colors.white,
    //                   ),),
    //               ),
    //             ),
    //             const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT,),
    //             SizedBox(
    //               height: Dimensions.PADDING_SIZE_LARGE * 2,
    //               child: ElevatedButton(
    //                 style: ElevatedButton.styleFrom(
    //                     shape: RoundedRectangleBorder(
    //                       borderRadius: BorderRadius.circular(8),
    //                     ),
    //                     backgroundColor: Theme.of(context).primaryColor
    //                 ),
    //                 onPressed: () {
    //                   String enteredText = queryController.text;
    //                   if (enteredText.isEmpty) {
    //                     setState(() {
    //                       errorText = 'Please enter your query';
    //                     });
    //                   } else {
    //                     addQuery(questionId, enteredText,context);
    //                   }
    //                 },
    //                 child: Text('Submit',
    //                   style: interRegular.copyWith(
    //                     fontSize: Dimensions.fontSizeLarge,
    //                     fontWeight: FontWeight.w400,
    //                     color: Colors.white,
    //                   ),),
    //               ),
    //             ),
    //           ],
    //         ),
    //         const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
    //       ],
    //     );
    //   },
    // );
    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: ThemeManager.mainBackground,
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
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          context: context,
          builder: (BuildContext context) {
            // return CustomBottomRaiseQuery(questionId: questionId);
            return MockBottomRaiseQuery(
              questionId: questionId,
              questionText: questionText,
              allOptions: allOption,
            );
          });
    }
  }

  void _showNotesDialog(BuildContext context, String questionId, String notes) {
    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (BuildContext context) {
    //     TextEditingController queryController = TextEditingController();
    //     queryController.text = notes;
    //     return AlertDialog(
    //       title: Text('Add Notes',
    //         style: interRegular.copyWith(
    //           fontSize: Dimensions.fontSizeExtraLarge,
    //           fontWeight: FontWeight.w500,
    //           color: ThemeManager.black,
    //         ),),
    //       content: Form(
    //         child: SizedBox(
    //           width: MediaQuery.of(context).size.width * 0.9,
    //           height: MediaQuery.of(context).size.height * 0.2,
    //           child: TextFormField(
    //             cursorColor: Theme.of(context).primaryColor,
    //             controller: queryController,
    //             maxLines: 50,
    //             keyboardType: TextInputType.multiline,
    //             decoration: InputDecoration(
    //               enabledBorder: UnderlineInputBorder(
    //                 borderSide: BorderSide(color: Theme.of(context).primaryColor),
    //               ),
    //               focusedBorder: UnderlineInputBorder(
    //                 borderSide: BorderSide(color:Theme.of(context).primaryColor),
    //               ),
    //               hintText: 'Enter your notes...',
    //               hintStyle: interRegular.copyWith(
    //                 fontSize: Dimensions.fontSizeLarge,
    //                 fontWeight: FontWeight.w400,
    //                 color: Theme.of(context).hintColor,
    //               ),
    //             ),
    //             style: interRegular.copyWith(
    //               fontSize: Dimensions.fontSizeLarge,
    //               fontWeight: FontWeight.w400,
    //               color: ThemeManager.black,
    //             ),
    //           ),
    //         ),
    //       ),
    //       actions: [
    //         Row(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             SizedBox(
    //               height: Dimensions.PADDING_SIZE_LARGE * 2,
    //               child: ElevatedButton(
    //                 onPressed: () {
    //                   Navigator.of(context).pop();
    //                 },
    //                 style: ElevatedButton.styleFrom(
    //                     shape: RoundedRectangleBorder(
    //                       borderRadius: BorderRadius.circular(8),
    //                     ),
    //                     backgroundColor: Theme.of(context).hintColor
    //                 ),
    //                 child: Text('Cancel',
    //                   style: interRegular.copyWith(
    //                     fontSize: Dimensions.fontSizeLarge,
    //                     fontWeight: FontWeight.w400,
    //                     color: Colors.white,
    //                   ),),
    //               ),
    //             ),
    //             const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT,),
    //             SizedBox(
    //               height: Dimensions.PADDING_SIZE_LARGE * 2,
    //               child: ElevatedButton(
    //                 style: ElevatedButton.styleFrom(
    //                     shape: RoundedRectangleBorder(
    //                       borderRadius: BorderRadius.circular(8),
    //                     ),
    //                     backgroundColor: Theme.of(context).primaryColor
    //                 ),
    //                 onPressed: () {
    //                   String notes = queryController.text;
    //                   debugPrint('enterTxt$notes');
    //                   addNotes(filteredSolutionReport?[_currentQuestionIndex].questionId,notes);
    //                   Navigator.of(context).pop();
    //                 },
    //                 child: Text('Submit',
    //                   style: interRegular.copyWith(
    //                     fontSize: Dimensions.fontSizeLarge,
    //                     fontWeight: FontWeight.w400,
    //                     color: Colors.white,
    //                   ),),
    //               ),
    //             ),
    //           ],
    //         ),
    //         const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
    //       ],
    //     );
    //   },
    // );
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

  final ScrollController _scrollController = ScrollController();

  void _scrollToIndex(int index) {
    double totalWidth = (filteredSolutionReport?.length ?? 0) *
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

  void _questionChange(int index) {
    Delta delta = _quillController.document.toDelta();
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    store.saveChangeExaplanation(context, {
      "question_id": filteredSolutionReport?[_currentQuestionIndex].questionId,
      "annotation_data": delta.toJson()
    });
    filteredSolutionReport?[_currentQuestionIndex].isHighlight = true;
    filteredSolutionReport?[_currentQuestionIndex].annotationData = delta.toJson();
    setState(() {
      _currentQuestionIndex = index;
      isbutton = false;
      isprocess = false;
      firstQue = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    explanationWidget = getExplanationText(context);
    questionWidget = getQuestionText(context);

    List<String> changeTopic = [
      'All topics', // Adding "View All" at the start
      ...(widget.solutionReport?.map((e) => e.topicName).toList() ?? []).cast<String>()
    ];

    List<DropdownMenuItem<String>> dropdownItems = [
      const DropdownMenuItem<String>(
        value: 'All topics',
        child: Text('All topics'),
      ),
      ...(widget.solutionReport?.map((item) {
            final topicName = item.topicName;
            return DropdownMenuItem<String>(
              value: topicName,
              child: Text(topicName!),
            );
          }) ??
          []),
    ];

    return Scaffold(
      backgroundColor: ThemeManager.white,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: ThemeManager.white,
        title: Row(
          children: [
            InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: SvgPicture.asset(
                  "assets/image/arrow_back.svg",
                  color: ThemeManager.currentTheme == AppTheme.Dark ? AppColors.white : null,
                )),
            // const SizedBox(width: Dimensions.RADIUS_EXTRA_LARGE*1.1,),
            // InkWell(
            //   onTap: (){},
            //   child: Image.asset("assets/image/questionplatte.png",color: ThemeManager.currentTheme == AppTheme.Dark ? AppColors.white : null,),
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
                  if (Platform.isWindows || Platform.isMacOS) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: ThemeManager.mainBackground,
                          actionsPadding: EdgeInsets.zero,
                          // insetPadding:
                          //     const EdgeInsets.symmetric(horizontal: 100),
                          actions: [
                            CustomBottomSheetWindow(
                                // heightSize:
                                //     MediaQuery.of(context).size.height * 0.56,
                                selectedVal: filterValue,
                                radioItems: const [
                                  'View all',
                                  'Correct',
                                  'Incorrect',
                                  'Skipped',
                                  'Marked for review',
                                  'Guessed',
                                ])
                          ],
                        );
                      },
                    ).then((selectedValued) {
                      log(selectedValued.isNotEmpty.toString());
                      if (selectedValued != null) {
                        setState(() {
                          filterValue = selectedValued;
                          _currentQuestionIndex = 0;

                          if (selectedValue.isEmpty || selectedValue == "All topics") {
                            if (filterValue.isNotEmpty && filterValue != "View all") {
                              filteredSolutionReport = allData?.where((report) {
                                log(report.markedforreview ?? "");
                                log(filterValue);
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
                              filteredSolutionReport = allData;
                            }
                          } else {
                            widget.solutionReport?.forEach((topicJson) {
                              if (topicJson.topicName == selectedValue) {
                                debugPrint("topicJson.questions:${topicJson.questions?[0].topicName}");
                                filterAllData?.clear();
                                filterAllData?.addAll(topicJson.questions as Iterable<Questions>);
                              }
                            });
                            log(filterValue.isNotEmpty.toString());
                            if (filterValue.isNotEmpty && filterValue != "View all") {
                              filteredSolutionReport = filterAllData?.where((report) {
                                log(filterValue);
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
                              filteredSolutionReport = filterAllData;
                            }
                          }
                          debugPrint('Selected value: $filterValue');
                        });
                      }
                    });
                  } else {
                    showModalBottomSheet<String>(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(25),
                        ),
                      ),
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      isScrollControlled: true,
                      context: context,
                      builder: (BuildContext context) {
                        return CustomBottomSheet(
                            heightSize: MediaQuery.of(context).size.height * 0.6,
                            selectedVal: filterValue,
                            radioItems: const [
                              'View all',
                              'Correct',
                              'Incorrect',
                              'Skipped',
                              'Marked for review',
                              'Guessed'
                            ]);
                      },
                    ).then((selectedValued) {
                      if (selectedValued != null) {
                        setState(() {
                          filterValue = selectedValued;
                          _currentQuestionIndex = 0;
                          if (selectedValue.isEmpty || selectedValue == "All topics") {
                            if (filterValue.isNotEmpty && filterValue != "View all") {
                              filteredSolutionReport = allData?.where((report) {
                                log(report.markedforreview.toString());
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
                              filteredSolutionReport = allData;
                            }
                          } else {
                            widget.solutionReport?.forEach((topicJson) {
                              if (topicJson.topicName == selectedValue) {
                                debugPrint("topicJson.questions:${topicJson.questions?[0].topicName}");
                                filterAllData?.clear();
                                filterAllData?.addAll(topicJson.questions as Iterable<Questions>);
                              }
                            });

                            if (filterValue.isNotEmpty && filterValue != "View all") {
                              filteredSolutionReport = filterAllData?.where((report) {
                                log(report.toJson().toString());
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
                              filteredSolutionReport = filterAllData;
                            }
                          }
                          debugPrint('Selected value: $filterValue');
                          firstQue = true;
                          isbutton = false;
                          lastQue = false;
                        });
                      }
                    });
                  }
                },
                child: SvgPicture.asset("assets/image/fillter.svg")),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Question and options
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (filteredSolutionReport?.isEmpty ?? true)
                    Center(
                      child: Text(
                        "No filtered data available",
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          fontWeight: FontWeight.w400,
                          color: ThemeManager.black,
                        ),
                      ),
                    ),
                  if (filteredSolutionReport?.isNotEmpty ?? false)
                    Column(
                      children: [
                        if (filteredSolutionReport?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: Dimensions.PADDING_SIZE_LARGE * 0.2,
                              left: Dimensions.PADDING_SIZE_SMALL * 1.6,
                              right: Dimensions.PADDING_SIZE_SMALL * 1.4,
                              bottom: Dimensions.PADDING_SIZE_DEFAULT * 1,
                            ),
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(filteredSolutionReport?.length ?? 0, (index) {
                                  Questions? solutionReport = filteredSolutionReport?[index];
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(right: Dimensions.PADDING_SIZE_SMALL * 1.7),
                                    child: GestureDetector(
                                      onTap: () {
                                        _questionChange(index);
                                      },
                                      child: Container(
                                        height: Dimensions.PADDING_SIZE_SMALL * 2.675,
                                        width: Dimensions.PADDING_SIZE_SMALL * 2.675,
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
                                          "${filteredSolutionReport?[index].questionNumber}",
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
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),

                        if (filteredSolutionReport?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(
                              // top: Dimensions.PADDING_SIZE_LARGE*2,
                              left: Dimensions.PADDING_SIZE_SMALL * 1.6,
                              right: Dimensions.PADDING_SIZE_SMALL * 1.5,
                              bottom: Dimensions.PADDING_SIZE_DEFAULT * 0.5,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedValue.isNotEmpty
                                      ? selectedValue
                                      : "${filteredSolutionReport?[_currentQuestionIndex].topicName}",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    fontWeight: FontWeight.w700,
                                    color: ThemeManager.black,
                                  ),
                                ),

                                InkWell(
                                  onTap: () {
                                    if (Platform.isWindows || Platform.isMacOS) {
                                      showDialog<String>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor: ThemeManager.mainBackground,
                                            actionsPadding: EdgeInsets.zero,
                                            // insetPadding: const EdgeInsets.symmetric(
                                            //     horizontal: 250),
                                            actions: [
                                              CustomTopicBottomSheetWindow(
                                                  heightSize: MediaQuery.of(context).size.height * 0.56,
                                                  selectedVal: selectedValue,
                                                  radioItems: changeTopic),
                                            ],
                                          );
                                        },
                                      ).then((selectedValued) {
                                        if (selectedValued != null) {
                                          setState(() {
                                            isbutton = false;
                                            selectedValue = selectedValued;
                                            // final selectedItem = widget.solutionReport?.firstWhere(
                                            //       (item) => item.topicName == selectedValue,
                                            // );
                                            // topicName = selectedItem?.topicName;
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
                                            _currentQuestionIndex = 0;
                                            filterValue = 'View all';
                                          });
                                        }
                                      });
                                    } else {
                                      showModalBottomSheet<String>(
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(25),
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAliasWithSaveLayer,
                                        context: context,
                                        builder: (BuildContext context) {
                                          return CustomTopicBottomSheet(
                                              heightSize: MediaQuery.of(context).size.height * 0.4,
                                              selectedVal: selectedValue,
                                              radioItems: changeTopic);
                                        },
                                      ).then((selectedValued) {
                                        if (selectedValued != null) {
                                          setState(() {
                                            isbutton = false;
                                            selectedValue = selectedValued;
                                            // final selectedItem = widget.solutionReport?.firstWhere(
                                            //       (item) => item.topicName == selectedValue,
                                            // );
                                            // topicName = selectedItem?.topicName;
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
                                      });
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Text(
                                        "Change Topic",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeManager.primaryColor,
                                        ),
                                      ),
                                      Icon(
                                        Icons.keyboard_arrow_down_outlined,
                                        color: ThemeManager.primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                                // DropdownButtonFormField<String>(
                                //   key: _topicNameKey,
                                //   dropdownColor:ThemeManager.white,
                                //   value: selectedValue.isNotEmpty ? selectedValue : null,
                                //   validator: (value) {
                                //     if (value == null || value.isEmpty) {
                                //       setState(() {
                                //         _isTopicNameValid = false;
                                //       });
                                //       return 'Please choose one.';
                                //     }
                                //     setState(() {
                                //       _isTopicNameValid = true;
                                //     });
                                //     return null;
                                //   },
                                //   decoration: InputDecoration(
                                //     // filled: true,
                                //     fillColor: Colors.transparent,
                                //     enabledBorder:InputBorder.none,
                                //     focusedBorder: InputBorder.none,
                                //     labelText: 'Change Topic',
                                //     errorBorder: InputBorder.none,
                                //     labelStyle: interRegular.copyWith(
                                //       fontSize: Dimensions.fontSizeSmall,
                                //       color: ThemeManager.black,
                                //     ),
                                //     hintText: 'Change Topic',
                                //     hintStyle: interRegular.copyWith(
                                //       fontSize: Dimensions.fontSizeSmall,
                                //       color: ThemeManager.black,
                                //     ),
                                //    // contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                //   ),
                                //   items: dropdownItems,
                                //   onChanged: (value) {
                                //     setState(() {
                                //       selectedValue = value!;
                                //       // final selectedItem = widget.solutionReport?.firstWhere(
                                //       //       (item) => item.topicName == selectedValue,
                                //       // );
                                //       // topicName = selectedItem?.topicName;
                                //
                                //       if(selectedValue == "All topics"){
                                //         filteredSolutionReport = allData;
                                //       }else{
                                //         for (var topicJson in widget.solutionReport ?? []){
                                //           if (topicJson.topicName == selectedValue) {
                                //             data?.clear();
                                //             data?.addAll(topicJson.questions as Iterable<Questions>);
                                //             break;
                                //           }
                                //         }
                                //         filteredSolutionReport = data;
                                //       }
                                //       _currentQuestionIndex = 0;
                                //       filterValue = 'View all';
                                //     });
                                //     debugPrint("selectedValue:${selectedValue}");
                                //   },
                                //   icon: Icon(Icons.keyboard_arrow_down,
                                //     color: Theme.of(context).disabledColor,),
                                //   iconSize: 24,
                                //   elevation: 16,
                                //   style: interRegular.copyWith(
                                //     fontSize: Dimensions.fontSizeSmall,
                                //     color: ThemeManager.black,
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),

                        Padding(
                          padding: const EdgeInsets.only(
                            // top: Dimensions.PADDING_SIZE_LARGE*1.5,
                            left: Dimensions.PADDING_SIZE_SMALL * 1.6,
                            right: Dimensions.PADDING_SIZE_SMALL * 1.5,
                            // bottom: Dimensions.PADDING_SIZE_LARGE*1.4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (filteredSolutionReport?[_currentQuestionIndex].timePerQuestion != null &&
                                  filteredSolutionReport?[_currentQuestionIndex].timePerQuestion != "") ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      color: ThemeManager.blackColor,
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      "Time Spent - ${filteredSolutionReport?[_currentQuestionIndex].timePerQuestion == null || filteredSolutionReport?[_currentQuestionIndex].timePerQuestion == "" ? "" : formatTimeString(filteredSolutionReport?[_currentQuestionIndex].timePerQuestion?.toString() ?? "00:00:00")}",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeLarge,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w700,
                                        color: ThemeManager.blackColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                              ],
                              Row(
                                children: [
                                  Text(
                                    "${_currentQuestionIndex + 1}.",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeOverLarge,
                                      fontWeight: FontWeight.w500,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: Dimensions.PADDING_SIZE_EXTRA_SMALL * 1.2,
                                  ),
                                  filteredSolutionReport?[_currentQuestionIndex].guess != ""
                                      ? Container(
                                          height: Dimensions.PADDING_SIZE_SMALL * 2.7,
                                          width: Dimensions.PADDING_SIZE_LARGE * 3.85,
                                          alignment: Alignment.center,
                                          //padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_DEFAULT,vertical: Dimensions.PADDING_SIZE_SMALL),
                                          decoration: BoxDecoration(
                                              color: ThemeManager.skipColor,
                                              borderRadius: BorderRadius.circular(60.87)),
                                          child: Text(
                                            "Guessed",
                                            style: interRegular.copyWith(
                                              fontSize: Dimensions.fontSizeSmall,
                                              fontWeight: FontWeight.w500,
                                              color: ThemeManager.black,
                                            ),
                                          ),
                                        )
                                      : filteredSolutionReport?[_currentQuestionIndex].skipped == true
                                          ? Container(
                                              height: Dimensions.PADDING_SIZE_SMALL * 2.7,
                                              width: Dimensions.PADDING_SIZE_LARGE * 3.85,
                                              alignment: Alignment.center,
                                              //padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_DEFAULT,vertical: Dimensions.PADDING_SIZE_SMALL),
                                              decoration: BoxDecoration(
                                                  color: ThemeManager.skipColor,
                                                  borderRadius: BorderRadius.circular(60.87)),
                                              child: Text(
                                                "Skipped",
                                                style: interRegular.copyWith(
                                                  fontSize: Dimensions.fontSizeSmall,
                                                  fontWeight: FontWeight.w500,
                                                  color: ThemeManager.black,
                                                ),
                                              ),
                                            )
                                          : const SizedBox(),
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
                                          if (filteredSolutionReport != null &&
                                              _currentQuestionIndex >= 0 &&
                                              _currentQuestionIndex < (filteredSolutionReport?.length ?? 0)) {
                                            putBookMarkApiCall(
                                                filteredSolutionReport?[_currentQuestionIndex].examId ?? "",
                                                filteredSolutionReport?[_currentQuestionIndex].questionId,
                                                "");
                                          }
                                        },
                                        child: BookmarkWidget(
                                          isSelected:
                                              filteredSolutionReport?[_currentQuestionIndex].bookmarks ??
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
                                                  MockBottomAskFaculty(
                                                    questionId: filteredSolutionReport?[_currentQuestionIndex]
                                                            .questionId ??
                                                        "",
                                                    questionText:
                                                        filteredSolutionReport?[_currentQuestionIndex]
                                                                .questionText ??
                                                            '',
                                                    allOptions:
                                                        "a) ${filteredSolutionReport?[_currentQuestionIndex].options?[0].answerTitle}\nb) ${filteredSolutionReport?[_currentQuestionIndex].options?[1].answerTitle}\nc) ${filteredSolutionReport?[_currentQuestionIndex].options?[2].answerTitle}\nd) ${filteredSolutionReport?[_currentQuestionIndex].options?[3].answerTitle}",
                                                  ),
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
                                                return MockBottomAskFaculty(
                                                  questionId: filteredSolutionReport?[_currentQuestionIndex]
                                                          .questionId ??
                                                      "",
                                                  questionText: filteredSolutionReport?[_currentQuestionIndex]
                                                          .questionText ??
                                                      '',
                                                  allOptions:
                                                      "a) ${filteredSolutionReport?[_currentQuestionIndex].options?[0].answerTitle}\nb) ${filteredSolutionReport?[_currentQuestionIndex].options?[1].answerTitle}\nc) ${filteredSolutionReport?[_currentQuestionIndex].options?[2].answerTitle}\nd) ${filteredSolutionReport?[_currentQuestionIndex].options?[3].answerTitle}",
                                                );
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
                                                  MockBottomReportIssue(
                                                    questionId: filteredSolutionReport?[_currentQuestionIndex]
                                                            .questionId ??
                                                        "",
                                                    questionText:
                                                        filteredSolutionReport?[_currentQuestionIndex]
                                                                .questionText ??
                                                            '',
                                                    allOptions:
                                                        "a) ${filteredSolutionReport?[_currentQuestionIndex].options?[0].answerTitle}\nb) ${filteredSolutionReport?[_currentQuestionIndex].options?[1].answerTitle}\nc) ${filteredSolutionReport?[_currentQuestionIndex].options?[2].answerTitle}\nd) ${filteredSolutionReport?[_currentQuestionIndex].options?[3].answerTitle}",
                                                  ),
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
                                                return MockBottomReportIssue(
                                                  questionId: filteredSolutionReport?[_currentQuestionIndex]
                                                          .questionId ??
                                                      "",
                                                  questionText: filteredSolutionReport?[_currentQuestionIndex]
                                                          .questionText ??
                                                      '',
                                                  allOptions:
                                                      "a) ${filteredSolutionReport?[_currentQuestionIndex].options?[0].answerTitle}\nb) ${filteredSolutionReport?[_currentQuestionIndex].options?[1].answerTitle}\nc) ${filteredSolutionReport?[_currentQuestionIndex].options?[2].answerTitle}\nd) ${filteredSolutionReport?[_currentQuestionIndex].options?[3].answerTitle}",
                                                );
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
                                      Questions? solutionReport =
                                          filteredSolutionReport?[_currentQuestionIndex];

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
                                      String concatenatedTitles =
                                          notMatchingAnswerTitles.where((title) => title != null).join(", ");

                                      String question =
                                          "Explain why $currentAnswerTitle is the answer to the Question $questionText and why the remaining $concatenatedTitles are not correct answer";
                                      isbutton == false ? await _getExplanationData(question ?? '') : null;
                                    },
                                    child: isprocess
                                        ? CupertinoActivityIndicator(
                                            color: ThemeManager.black,
                                          )
                                        : SvgPicture.asset('assets/image/ai.svg'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(
                    height: Dimensions.PADDING_SIZE_DEFAULT,
                  ),
                  if (filteredSolutionReport?.isNotEmpty ?? false)
                    Padding(
                      padding: EdgeInsets.only(
                        left: Dimensions.PADDING_SIZE_SMALL * 1.5,
                        right: Dimensions.PADDING_SIZE_SMALL * 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          questionWidget ?? const SizedBox(),
                          ListView.builder(
                            padding: EdgeInsets.only(),
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredSolutionReport?[_currentQuestionIndex].options?.length,
                            itemBuilder: (BuildContext context, int index) {
                              Questions? solutionReport = filteredSolutionReport?[_currentQuestionIndex];
                              String showTxt = ((solutionReport?.correctOption ?? "") ==
                                      (solutionReport?.options?[index].value ?? ""))
                                  ? "Correct Answer"
                                  : ((solutionReport?.selectedOption ?? "") ==
                                          (solutionReport?.options?[index].value ?? ""))
                                      ? "Incorrect Answer"
                                      : ((solutionReport?.guess ?? "") ==
                                              (solutionReport?.options?[index].value ?? ""))
                                          ? "Guess"
                                          : "";
                              Color showColor2 = ((solutionReport?.correctOption ?? "") ==
                                      (solutionReport?.options?[index].value ?? ""))
                                  ? ThemeManager.greenSuccess
                                  : ((solutionReport?.selectedOption ?? "") ==
                                          (solutionReport?.options?[index].value ?? ""))
                                      ? ThemeManager.redAlert
                                      : ((solutionReport?.guess ?? "") ==
                                              (solutionReport?.options?[index].value ?? ""))
                                          ? (ThemeManager.currentTheme == AppTheme.Dark
                                              ? ThemeManager.black
                                              : Colors.brown)
                                          : ThemeManager.black;

                              Color showColor = ((solutionReport?.correctOption ?? "") ==
                                      (solutionReport?.options?[index].value ?? ""))
                                  ? ThemeManager.correctChart
                                  : ((solutionReport?.selectedOption ?? "") ==
                                          (solutionReport?.options?[index].value ?? ""))
                                      ? ThemeManager.evolveRed
                                      : ((solutionReport?.guess ?? "") ==
                                              (solutionReport?.options?[index].value ?? ""))
                                          ? Colors.brown
                                          : ThemeManager.white;

                              Color showColorBorder = ((solutionReport?.correctOption ?? "") ==
                                      (solutionReport?.options?[index].value ?? ""))
                                  ? ThemeManager.correctChart
                                  : ((solutionReport?.selectedOption ?? "") ==
                                          (solutionReport?.options?[index].value ?? ""))
                                      ? ThemeManager.evolveRed
                                      : ((solutionReport?.guess ?? "") ==
                                              (solutionReport?.options?[index].value ?? ""))
                                          ? Colors.brown
                                          : ThemeManager.grey1;

                              String base64String = solutionReport?.options?[index].answerImg ?? "";
                              String? correctPercentage = solutionReport?.correctPercentage;
                              try {
                                // answerImgBytes = base64Decode(base64String);
                              } catch (e) {
                                print("Error decoding base64 string: $e");
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: Dimensions.PADDING_SIZE_DEFAULT),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: showColorBorder, width: 0.84),
                                        borderRadius: BorderRadius.circular(8),
                                        color: showColor.withOpacity(0.1),
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
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "${solutionReport?.options?[index].value ?? ""}.  ",
                                                          style: TextStyle(
                                                            fontSize: Dimensions.fontSizeLarge,
                                                            fontWeight: FontWeight.w400,
                                                            color: showColor2,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: MediaQuery.of(context).size.width * 0.7,
                                                          child: Text(
                                                            solutionReport?.options?[index].answerTitle ?? "",
                                                            style: TextStyle(
                                                              fontSize: Dimensions.fontSizeLarge,
                                                              fontWeight: FontWeight.w400,
                                                              color: showColor2,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                solutionReport?.options?[index].answerImg != ""
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
                                    if ((solutionReport?.correctOption ?? "") ==
                                        (solutionReport?.options?[index].value ?? ""))
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                                        child: Text(
                                          "${solutionReport?.options?[index].percentage ?? "0"}% Got this answer correct",
                                          style: TextStyle(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: (solutionReport?.correctOption ?? "") ==
                                                    (solutionReport?.options?[index].value ?? "")
                                                ? ThemeManager.greenSuccess
                                                : ThemeManager.orangeColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                    else if (((solutionReport?.selectedOption ?? "") ==
                                        (solutionReport?.options?[index].value ?? "")))
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                                        child: Text(
                                          "${solutionReport?.options?[index].percentage ?? "0"}% Marked this incorrect",
                                          style: TextStyle(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: ThemeManager.redAlert,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                    else if (((solutionReport?.correctOption ?? "") !=
                                            (solutionReport?.options?[index].value ?? "")) &&
                                        !((solutionReport?.selectedOption ?? "") ==
                                            (solutionReport?.options?[index].value ?? "")))
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                                        child: Text(
                                          "${solutionReport?.options?[index].percentage ?? "0"}% Marked this",
                                          style: TextStyle(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: ThemeManager.orangeColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(
                            height: Dimensions.PADDING_SIZE_SMALL * 1.7,
                          ),
                          Observer(
                            builder: (BuildContext context) {
                              GetNotesSolutionModel? noteModel = store.notesData.value;
                              return Row(
                                children: [
                                  Text(
                                    "Explanation:",
                                    style: interBlack.copyWith(
                                      fontSize: Dimensions.fontSizeExLarge,
                                      fontWeight: FontWeight.w700,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  const Spacer(),
                                  // InkWell(
                                  //   onTap: () {
                                  //     _showNotesDialog(
                                  //         context,
                                  //         filteredSolutionReport?[
                                  //                     _currentQuestionIndex]
                                  //                 .questionId ??
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
                                  // GestureDetector(
                                  //   onTap: () {},
                                  //   child: SvgPicture.asset(
                                  //     "assets/image/helight.svg",
                                  //   ),
                                  // ),
                                  // const SizedBox(
                                  //   width: 10,
                                  // ),
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
                                        Delta delta = _quillController.document.toDelta();
                                        final store = Provider.of<TestCategoryStore>(context, listen: false);
                                        store.saveChangeExaplanation(context, {
                                          "question_id":
                                              filteredSolutionReport?[_currentQuestionIndex].questionId,
                                          "annotation_data": delta.toJson()
                                        });
                                        filteredSolutionReport?[_currentQuestionIndex].isHighlight = true;
                                        filteredSolutionReport?[_currentQuestionIndex].annotationData =
                                            delta.toJson();
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
                                          filteredSolutionReport?[_currentQuestionIndex].questionId ?? "",
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

                                  //       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,onPressed: (){
                                  //   _showNotesDialog(context, filteredSolutionReport?[_currentQuestionIndex].questionId ?? "", noteModel?.notes??"");
                                  // }, icon: Icon(Icons.edit_note_sharp,color: Theme.of(context).hintColor,)),
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
                              );
                            },
                          ),
                          Column(
                            children: [
                              explanationWidget ?? const SizedBox(),
                              const SizedBox(
                                height: Dimensions.PADDING_SIZE_DEFAULT,
                              ),
                              isbutton == true
                                  ? Observer(
                                      builder: (BuildContext context) {
                                        GetExplanationModel? getExplainModel = store.getExplanationText.value;
                                        // debugPrint("store.getExplanationText.value.text: ${store.getExplanationText.value?.text}");
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: Dimensions.PADDING_SIZE_LARGE,
                                              vertical: Dimensions.PADDING_SIZE_LARGE),
                                          decoration: BoxDecoration(
                                              color: ThemeManager.explainContainer,
                                              borderRadius: BorderRadius.circular(Dimensions.RADIUS_DEFAULT)),
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
                          )
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: Dimensions.PADDING_SIZE_DEFAULT,
          ),

          //next and previous buttons
          if (filteredSolutionReport?.isNotEmpty ?? false)
            if (!isButtonVisible2) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isButtonVisible) ...[
                    CommonTool(
                      onTap: () {
                        Delta delta = _quillController.document.toDelta();
                        final store = Provider.of<TestCategoryStore>(context, listen: false);
                        store.saveChangeExaplanation(context, {
                          "question_id": filteredSolutionReport?[_currentQuestionIndex].questionId,
                          "annotation_data": delta.toJson()
                        });
                        filteredSolutionReport?[_currentQuestionIndex].isHighlight = true;
                        filteredSolutionReport?[_currentQuestionIndex].annotationData = delta.toJson();
                      },
                      controller: _quillController,
                    ),
                    const SizedBox(
                      width: 0,
                    ),
                  ],
                  InkWell(
                      onTap: () {
                        if (filteredSolutionReport != null &&
                            _currentQuestionIndex >= 0 &&
                            _currentQuestionIndex < (filteredSolutionReport?.length ?? 0)) {
                          putBookMarkApiCall(filteredSolutionReport?[_currentQuestionIndex].examId ?? "",
                              filteredSolutionReport?[_currentQuestionIndex].questionId, "");
                        }
                      },
                      child: BookmarkWidget(
                        isSelected: filteredSolutionReport?[_currentQuestionIndex].bookmarks ?? false,
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
                                        filteredSolutionReport?[_currentQuestionIndex].questionId ?? "",
                                    questionText:
                                        filteredSolutionReport?[_currentQuestionIndex].questionText ?? '',
                                    allOptions:
                                        "a) ${filteredSolutionReport?[_currentQuestionIndex].options?[0].answerTitle}\nb) ${filteredSolutionReport?[_currentQuestionIndex].options?[1].answerTitle}\nc) ${filteredSolutionReport?[_currentQuestionIndex].options?[2].answerTitle}\nd) ${filteredSolutionReport?[_currentQuestionIndex].options?[3].answerTitle}",
                                  ),
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
                                  questionId: filteredSolutionReport?[_currentQuestionIndex].questionId ?? "",
                                  questionText:
                                      filteredSolutionReport?[_currentQuestionIndex].questionText ?? '',
                                  allOptions:
                                      "a) ${filteredSolutionReport?[_currentQuestionIndex].options?[0].answerTitle}\nb) ${filteredSolutionReport?[_currentQuestionIndex].options?[1].answerTitle}\nc) ${filteredSolutionReport?[_currentQuestionIndex].options?[2].answerTitle}\nd) ${filteredSolutionReport?[_currentQuestionIndex].options?[3].answerTitle}",
                                );
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
                                        filteredSolutionReport?[_currentQuestionIndex].questionId ?? "",
                                    questionText:
                                        filteredSolutionReport?[_currentQuestionIndex].questionText ?? '',
                                    allOptions:
                                        "a) ${filteredSolutionReport?[_currentQuestionIndex].options?[0].answerTitle}\nb) ${filteredSolutionReport?[_currentQuestionIndex].options?[1].answerTitle}\nc) ${filteredSolutionReport?[_currentQuestionIndex].options?[2].answerTitle}\nd) ${filteredSolutionReport?[_currentQuestionIndex].options?[3].answerTitle}",
                                  ),
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
                                  questionId: filteredSolutionReport?[_currentQuestionIndex].questionId ?? "",
                                  questionText:
                                      filteredSolutionReport?[_currentQuestionIndex].questionText ?? '',
                                  allOptions:
                                      "a) ${filteredSolutionReport?[_currentQuestionIndex].options?[0].answerTitle}\nb) ${filteredSolutionReport?[_currentQuestionIndex].options?[1].answerTitle}\nc) ${filteredSolutionReport?[_currentQuestionIndex].options?[2].answerTitle}\nd) ${filteredSolutionReport?[_currentQuestionIndex].options?[3].answerTitle}",
                                );
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
                      Questions? solutionReport = filteredSolutionReport?[_currentQuestionIndex];

                      final questionText = solutionReport?.questionText;
                      final currentOption = solutionReport?.correctOption;

                      final answerTitle = solutionReport?.options?.map((e) => e.answerTitle);

                      int currentIndex =
                          solutionReport?.options?.indexWhere((e) => e.value == currentOption) ?? -1;
                      String? currentAnswerTitle = answerTitle?.elementAt(currentIndex);

                      List<String?> notMatchingAnswerTitles =
                          answerTitle?.where((title) => title != currentAnswerTitle).toList() ?? [];
                      String concatenatedTitles =
                          notMatchingAnswerTitles.where((title) => title != null).join(", ");

                      String question =
                          "Explain why $currentAnswerTitle is the answer to the Question $questionText and why the remaining $concatenatedTitles are not correct answer";
                      isbutton == false ? await _getExplanationData(question ?? '') : null;
                    },
                    child: isprocess
                        ? CupertinoActivityIndicator(
                            color: ThemeManager.black,
                          )
                        : SvgPicture.asset('assets/image/ai.svg'),
                  ),
                  if (!isButtonVisible) ...[
                    const SizedBox(
                      width: 10,
                    ),
                    GestureDetector(
                      onTap: () {
                        GetNotesSolutionModel? noteModel = store.notesData.value;
                        _showNotesDialog(
                            context,
                            filteredSolutionReport?[_currentQuestionIndex].questionId ?? "",
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
          if (filteredSolutionReport?.isNotEmpty ?? false)
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
                      onTap: isprocess == true ? null : (lastQue ? null : _showNextQuestion),
                      text: "Next",
                    ),
                  ),
                ],
              ),
            ),
        ],
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
}
