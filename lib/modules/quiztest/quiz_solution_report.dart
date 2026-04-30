import 'dart:io';
import 'dart:typed_data';
import 'package:shusruta_lms/services/daily_review_recorder.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_svg/svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/comman_widget.dart';
import 'package:shusruta_lms/models/get_explanation_model.dart';
import 'package:shusruta_lms/modules/quiztest/quiz_bottom_raise_query.dart';
import 'package:shusruta_lms/modules/reports/explanation_common_widget.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/modules/widgets/bottom_stick_notes_window.dart';
import 'package:shusruta_lms/modules/widgets/custom_bottom_sheet_winow.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:typewritertext/typewritertext.dart';

import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/get_notes_solution_model.dart';
import '../widgets/bottom_stick_notes.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_bottom_sheet.dart';
import '../widgets/custom_button.dart';
import 'model/quiz_solution_reports_model.dart';

class QuizSolutionReportScreen extends StatefulWidget {
  final List<QuizSolutionReportsModel>? solutionReport;
  final String filter;
  final String userExamId;
  const QuizSolutionReportScreen(
      {super.key, this.solutionReport, required this.filter, required this.userExamId});

  @override
  State<QuizSolutionReportScreen> createState() => _QuizSolutionReportScreenState();
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
  bool lastQue = false, firstQue = true, isBookmarked = false, isbutton = false, isprocess = false;
  List<QuizSolutionReportsModel>? filteredSolutionReport;
  Widget? explanationWidget;
  Widget? questionWidget;
  final _controller = SuperTooltipController();
  Key _viewerKey = GlobalKey();
  double _textSize = Dimensions.fontSizeDefault;
  double showfontSize = 100;
  late QuillController _quillController = QuillController.basic();

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
        }
        return false;
      }).toList();
    } else {
      filteredSolutionReport = widget.solutionReport;
    }
    _getNotesData(filteredSolutionReport?[_currentQuestionIndex].questionId ?? "");

    // Sync solution report into daily-review pools.
    if (widget.solutionReport != null) {
      // ignore: discarded_futures
      DailyReviewRecorder.ingestQuizSolutionReport(widget.solutionReport!);
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

    _getNotesData(filteredSolutionReport?[_currentQuestionIndex].questionId ?? "");
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
    _getNotesData(filteredSolutionReport?[_currentQuestionIndex].questionId ?? "");
  }

  // Widget getExplanationText(BuildContext context) {
  //   if (filteredSolutionReport == null ||
  //       _currentQuestionIndex < 0 ||
  //       _currentQuestionIndex >= (filteredSolutionReport?.length ?? 0)) {
  //     return Center(
  //       child: Text(
  //         "No filtered data available",
  //         style: interRegular.copyWith(
  //           fontSize: Dimensions.fontSizeDefault,
  //           fontWeight: FontWeight.w400,
  //           color: ThemeManager.black,
  //         ),
  //       ),
  //     );
  //   }
  //
  //   String explanation =
  //       filteredSolutionReport?[_currentQuestionIndex].explanation ?? "";
  //   explanation = explanation.replaceAllMapped(
  //       RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
  //   List<String> splittedText = explanation.split("splittedImage");
  //   List<Widget> columns = [];
  //   int index = 0;
  //   for (String text in splittedText) {
  //     List<Widget> explanationImageWidget = [];
  //     if (filteredSolutionReport?[_currentQuestionIndex]
  //             .explanationImg
  //             ?.isNotEmpty ??
  //         false) {
  //       for (String base64String
  //           in filteredSolutionReport![_currentQuestionIndex].explanationImg!) {
  //         try {
  //           // Uint8List explanationImgBytes = base64Decode(base64String);
  //           explanationImageWidget.add(
  //             GestureDetector(
  //               onTap: () {
  //                 showDialog(
  //                   context: context,
  //                   builder: (context) {
  //                     return Dialog(
  //                       child: PhotoView(
  //                         // imageProvider: MemoryImage(explanationImgBytes),
  //                         imageProvider: NetworkImage(base64String),
  //                         minScale: PhotoViewComputedScale.contained,
  //                         maxScale: PhotoViewComputedScale.covered * 2,
  //                       ),
  //                     );
  //                   },
  //                 );
  //               },
  //               child: Row(
  //                 children: [
  //                   Expanded(
  //                     child: InteractiveViewer(
  //                       // minScale: 1.0,
  //                       // maxScale: 3.0,
  //                       scaleEnabled: false,
  //                       child: Center(
  //                         child: Container(
  //                           padding: const EdgeInsets.only(bottom: 8.0),
  //                           // width: MediaQuery.of(context).size.width,
  //                           // height: MediaQuery.of(context).size.height * 0.3,
  //                           child: Stack(
  //                             children: [
  //                               // Image.memory(explanationImgBytes),
  //                               Image.network(base64String, fit: BoxFit.cover),
  //                               Container(color: Colors.transparent),
  //                             ],
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         } catch (e) {
  //           debugPrint("Error decoding base64 string: $e");
  //         }
  //       }
  //     }
  //     columns.add(
  //       Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           // Html(
  //           //   data:  text.replaceAll("			--", "                 •").replaceAll("		--", "           •").replaceAll("	--", "     •").replaceAll("--", "•"),
  //           // ),
  //           Text(
  //             text
  //                 .trim()
  //                 .replaceAll("			--", "                 •")
  //                 .replaceAll("		--", "           •")
  //                 .replaceAll("	--", "     •")
  //                 .replaceAll("--", "•"),
  //             textAlign: TextAlign.justify,
  //             style: interBlack.copyWith(
  //               fontSize: _textSize,
  //               fontWeight: FontWeight.w400,
  //               color: ThemeManager.black,
  //             ),
  //           ),
  //           const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
  //           Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: explanationImageWidget,
  //           ),
  //           const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
  //           explanationImageWidget.isNotEmpty
  //               ? Text(
  //                   "Tap the image to zoom In/Out",
  //                   style: interBlack.copyWith(
  //                     fontSize: Dimensions.fontSizeSmall,
  //                     fontWeight: FontWeight.w400,
  //                     color: ThemeManager.black,
  //                   ),
  //                 )
  //               : const SizedBox(),
  //         ],
  //       ),
  //     );
  //     index++;
  //
  //     if (index >=
  //         (filteredSolutionReport?[_currentQuestionIndex]
  //                     .explanationImg
  //                     ?.length ??
  //                 0) -
  //             1) {
  //       break;
  //     }
  //   }
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: columns,
  //   );
  // }

  Widget getExplanationText(BuildContext context) {
    if (filteredSolutionReport == null ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= filteredSolutionReport!.length) {
      return const Center(
        child: Text("No data available"),
      );
    }

    final currentData = filteredSolutionReport![_currentQuestionIndex];

    List<Widget> columns = [];

    /// TEXT
    String explanation = currentData.explanation ?? "";
    final documentContent = preprocessDocument(explanation);

    Document document;

    /// ✅ ⭐ MOST IMPORTANT PART
    final parsed = documentContent.trim().isEmpty ? null : parseCustomSyntax(documentContent);

    document = (parsed == null || parsed.isEmpty)
        ? (Document()..insert(0, "No explanation available\n"))
        : Document.fromJson(parsed);

    debugPrint("⚪ Loaded ORIGINAL content");

    /// ✅ IMPORTANT: recreate controller with document

    _quillController = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    columns.add(
      CommonExplanationWidget(
        textPercentage: showfontSize.toInt(),
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
      DailyReviewRecorder.bookmarkToggleQuizSolution(q, isBookmarkedNow);
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
    if ((Platform.isWindows || Platform.isMacOS)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: ThemeManager.mainBackground,
            actionsPadding: EdgeInsets.zero,
            insetPadding: const EdgeInsets.symmetric(horizontal: 250),
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
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          context: context,
          builder: (BuildContext context) {
            // return CustomBottomRaiseQuery(questionId: questionId);
            return CustomQuizBottomRaiseQuery(
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
    setState(() {
      _currentQuestionIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    explanationWidget = getExplanationText(context);
    questionWidget = getQuestionText(context);

    return Scaffold(
      backgroundColor: ThemeManager.white,
      // appBar: AppBar(
      //   elevation: 0,
      //   automaticallyImplyLeading: false,
      //   backgroundColor: ThemeManager.white,
      //   leading: Padding(
      //     padding: const EdgeInsets.only(left: Dimensions.PADDING_SIZE_SMALL),
      //     child:       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,
      //       icon:  Icon(Icons.arrow_back_ios, color: ThemeManager.iconColor),
      //       onPressed: () {
      //         Navigator.pop(context);
      //       },
      //     ),
      //   ),
      //   title: Padding(
      //     padding: const EdgeInsets.only(right: Dimensions.PADDING_SIZE_DEFAULT),
      //     child: Row(
      //       children: [
      //         Expanded(
      //           child: Column(
      //             children: [
      //               Text(
      //                 "Solution Report",
      //                 style: interRegular.copyWith(
      //                   fontSize: Dimensions.fontSizeLarge,
      //                   fontWeight: FontWeight.w500,
      //                   color: ThemeManager.black,
      //                 ),),
      //               Text(
      //                 "${widget.solutionReport?.length} Questions",
      //                 style: interRegular.copyWith(
      //                   fontSize: Dimensions.fontSizeExtraSmall,
      //                   fontWeight: FontWeight.w400,
      //                   color: Theme.of(context).hintColor,
      //                 ),
      //               ),
      //             ],
      //           ),
      //         ),
      //         const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT,),
      //         //filter
      //         InkWell(
      //             onTap: (){
      //               showModalBottomSheet<String>(
      //                 shape: const RoundedRectangleBorder(
      //                   borderRadius: BorderRadius.vertical(
      //                     top: Radius.circular(25),
      //                   ),
      //                 ),
      //                 clipBehavior: Clip.antiAliasWithSaveLayer,
      //                 context: context,
      //                 builder: (BuildContext context) {
      //                   return CustomBottomSheet(
      //                       heightSize: MediaQuery.of(context).size.height * 0.3,
      //                       selectedVal: filterValue,
      //                       radioItems: const ['View all', 'Correct','Incorrect']);
      //                 },
      //               ).then((selectedValue) {
      //                 if (selectedValue != null) {
      //                   setState(() {
      //                     filterValue = selectedValue;
      //                     _currentQuestionIndex = 0;
      //                     if (filterValue.isNotEmpty && filterValue != "View all") {
      //                       filteredSolutionReport = widget.solutionReport
      //                           ?.where((report) {
      //                         if (filterValue == "Correct") {
      //                           return report.isCorrect == true;
      //                         } else if (filterValue == "Incorrect") {
      //                           return report.isCorrect == false;
      //                         }
      //                         return false;
      //                       })
      //                           .toList();
      //                     } else {
      //                       filteredSolutionReport = widget.solutionReport;
      //                     }
      //                     debugPrint('Selected value: $filterValue');
      //                   });
      //                 }
      //               });
      //             },
      //             child: SvgPicture.asset("assets/image/filter_icon.svg",color:ThemeManager.currentTheme==AppTheme.Dark ?ThemeManager.black : null,)),
      //       ],
      //     ),
      //   ),
      // ),
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: ThemeManager.white,
        title: Row(
          children: [
            // Text(
            //   widget.testExamPaper?.examName??"Test",
            //   style: interRegular.copyWith(
            //     fontSize: Dimensions.fontSizeLarge,
            //     fontWeight: FontWeight.w500,
            //     color: Colors.white,
            //   ),
            // ),
            InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: SvgPicture.asset(
                  "assets/image/arrow_back.svg",
                  color: ThemeManager.currentTheme == AppTheme.Dark ? AppColors.white : null,
                )),
            // const Spacer(),
            //       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,onPressed: (){
            //   showDialog(
            //     context: context,
            //     builder: (context) => CustomTestCancelDialogBox(timer,remainingTimeNotifier,false),
            //   );
            // }, icon: const Icon(Icons.close,color: Colors.white,)),
            // const SizedBox(width: Dimensions.RADIUS_EXTRA_LARGE*1.1,),
            // InkWell(
            //   onTap: (){
            //     //_scaffoldKey.currentState?.openDrawer();
            //   },
            //   child: Image.asset("assets/image/questionplatte.png",color: ThemeManager.currentTheme == AppTheme.Dark ? AppColors.white : null,),
            // ),
            // const Spacer(),
            // SvgPicture.asset("assets/image/testTimeIcon.svg",color: ThemeManager.currentTheme == AppTheme.Dark ? AppColors.white : null,),
            // ValueListenableBuilder<Duration>(
            //   valueListenable: remainingTimeNotifier,
            //   builder: (context, remainingTime, child) {
            //     return Text(
            //       " ${remainingTime!.inHours.toString().padLeft(2, '0')}:${remainingTime!.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTime!.inSeconds.remainder(60).toString().padLeft(2, '0')}",
            //       style: interRegular.copyWith(
            //         fontSize: Dimensions.fontSizeDefault,
            //         fontWeight: FontWeight.w500,
            //         color: ThemeManager.black,
            //       ),
            //     );
            //   },
            // ),
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
            // InkWell(
            //   onTap: (){
            //     putBookMarkApiCall(filteredSolutionReport?[_currentQuestionIndex].examId??"",filteredSolutionReport?[_currentQuestionIndex].questionId,"");
            //   },
            //   child: Container(
            //     height: Dimensions.PADDING_SIZE_LARGE*1.2,
            //     width: Dimensions.PADDING_SIZE_LARGE*1.2,
            //     alignment: Alignment.center,
            //     decoration: BoxDecoration(
            //       color: filteredSolutionReport?[_currentQuestionIndex].bookmarks??false ? ThemeManager.primaryColor : ThemeManager.primaryColor.withOpacity(0.4),
            //       shape: BoxShape.circle,
            //     ),
            //     child: Icon(filteredSolutionReport?[_currentQuestionIndex].bookmarks??false ? Icons.bookmark : Icons.bookmark_border,color: ThemeManager.white,size: 18,),
            //   ),
            // ),
            // const SizedBox(width: Dimensions.PADDING_SIZE_LARGE,),
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
                          CustomBottomSheetWindow(
                              selectedVal: filterValue,
                              radioItems: const ['View all', 'Correct', 'Incorrect']),
                        ],
                      );
                    },
                  ).then((selectedValue) {
                    if (selectedValue != null) {
                      setState(() {
                        filterValue = selectedValue;
                        _currentQuestionIndex = 0;
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
                        debugPrint('Selected value: $filterValue');
                      });
                    }
                  });
                } else {
                  showModalBottomSheet<String>(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28.72),
                      ),
                    ),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    context: context,
                    builder: (BuildContext context) {
                      return CustomBottomSheet(
                          heightSize: MediaQuery.of(context).size.height * 0.4,
                          selectedVal: filterValue,
                          radioItems: const ['View all', 'Correct', 'Incorrect']);
                    },
                  ).then((selectedValue) {
                    if (selectedValue != null) {
                      setState(() {
                        filterValue = selectedValue;
                        _currentQuestionIndex = 0;
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
                        debugPrint('Selected value: $filterValue');
                      });
                    }
                  });
                }
              },
              child: Container(
                height: Dimensions.PADDING_SIZE_SMALL * 2.7,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_LARGE),
                decoration: BoxDecoration(
                    border: Border.all(
                      color: ThemeManager.blueFinal,
                    ),
                    borderRadius: BorderRadius.circular(60)),
                child: Text(
                  "Filter",
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (filteredSolutionReport?.isNotEmpty ?? false)
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
                  children: List.generate(filteredSolutionReport?.length ?? 0, (index) {
                    QuizSolutionReportsModel? solutionReport = filteredSolutionReport?[index];
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

                    return Padding(
                      padding: const EdgeInsets.only(right: Dimensions.PADDING_SIZE_SMALL * 1.7),
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
            //   Row(
            //   children: [
            //     // Row(
            //     //   crossAxisAlignment: CrossAxisAlignment.center,
            //     //   children: [
            //     //     Container(
            //     //       height: Dimensions.PADDING_SIZE_DEFAULT * 2,
            //     //       width: Dimensions.PADDING_SIZE_DEFAULT * 5,
            //     //       decoration: BoxDecoration(
            //     //           color: ThemeManager.borderBlue,
            //     //           borderRadius: BorderRadius.circular(Dimensions.RADIUS_LARGE)
            //     //       ),
            //     //       child: Center(
            //     //         child: Text("Q-${(filteredSolutionReport?[_currentQuestionIndex].questionNumber ??
            //     //             (widget.solutionReport?[_currentQuestionIndex].questionNumber ?? "").toString().padLeft(2, '0'))}",
            //     //           style: interRegular.copyWith(
            //     //             fontSize: Dimensions.fontSizeDefault,
            //     //             fontWeight: FontWeight.w400,
            //     //             color: ThemeManager.black,
            //     //           ),
            //     //         ),
            //     //       ),
            //     //     ),
            //     //     const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
            //     //     Text("Out of ${filteredSolutionReport?.length}",
            //     //       style: interRegular.copyWith(
            //     //         fontSize: Dimensions.fontSizeDefault,
            //     //         fontWeight: FontWeight.w400,
            //     //         color: Theme.of(context).hintColor,
            //     //       ),),
            //     //   ],
            //     // ),
            //     Text("Q-${(filteredSolutionReport?[_currentQuestionIndex].questionNumber ??
            //         (widget.solutionReport?[_currentQuestionIndex].questionNumber ?? "").toString().padLeft(2, '0'))} /(${_currentQuestionIndex +1}/${filteredSolutionReport?.length})",
            //       style: interRegular.copyWith(
            //         fontSize: Dimensions.fontSizeSmall,
            //         fontWeight: FontWeight.w600,
            //         color: ThemeManager.black,
            //       ),
            //     ),
            //     const Spacer(),
            //     InkWell(
            //       onTap: () async {
            //         if( !isbutton){
            //           setState(() {
            //             isprocess = true;
            //           });
            //         }
            //                   SolutionReportsModel? solutionReport = filteredSolutionReport?[_currentQuestionIndex];
            //
            //                   final questionText =solutionReport?.questionText;
            //                   final currentOption = solutionReport?.correctOption;
            //
            //                   final answerTitle = solutionReport?.options?.map((e) => e.answerTitle);
            //
            //                   int currentIndex = solutionReport?.options?.indexWhere((e) => e.value == currentOption) ?? -1;
            //                   String? currentAnswerTitle = answerTitle?.elementAt(currentIndex);
            //
            //                   List<String?> notMatchingAnswerTitles = answerTitle?.where((title) => title != currentAnswerTitle).toList() ?? [];
            //                   String concatenatedTitles = notMatchingAnswerTitles.where((title) => title != null).join(", ");
            //
            //                   String question = "Explain why $currentAnswerTitle is the answer to the Question $questionText and why the remaining $concatenatedTitles are not correct answer";
            //                   isbutton == false ? await _getExplanationData(question ??'') : null;
            //       },
            //       child: Container(
            //         height: MediaQuery.of(context).size.height*0.048,
            //         width: MediaQuery.of(context).size.width*0.32,
            //         alignment: Alignment.center,
            //         padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_DEFAULT,vertical: Dimensions.PADDING_SIZE_SMALL),
            //         decoration: BoxDecoration(
            //             color: ThemeManager.primaryColor,
            //             borderRadius: BorderRadius.circular(20)
            //         ),
            //         child:isprocess == true ? Center(child: SizedBox(height: 25,width: 25,child: CircularProgressIndicator(color: ThemeManager.white,))) : Text("Ask Cortex.AI",
            //           style: interRegular.copyWith(
            //             fontSize: Dimensions.fontSizeSmall,
            //             fontWeight: FontWeight.w400,
            //             color: ThemeManager.white,
            //           ),
            //         ),
            //       ),
            //     ),
            //     SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT,),
            //     InkWell(
            //       onTap: (){
            //         _showDialog(context,filteredSolutionReport?[_currentQuestionIndex].questionId??"");
            //       },
            //       child: Container(
            //         height: MediaQuery.of(context).size.height*0.048,
            //         width: MediaQuery.of(context).size.width*0.32,
            //         alignment: Alignment.center,
            //         padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_DEFAULT,vertical: Dimensions.PADDING_SIZE_SMALL),
            //         decoration: BoxDecoration(
            //             color: ThemeManager.primaryColor,
            //             borderRadius: BorderRadius.circular(20)
            //         ),
            //         child:Text("Raise Query?",
            //           style: interRegular.copyWith(
            //             fontSize: Dimensions.fontSizeSmall,
            //             fontWeight: FontWeight.w400,
            //             color: ThemeManager.white,
            //           ),
            //         ),
            //       ),
            //     ),
            //     // Row(
            //     //   crossAxisAlignment: CrossAxisAlignment.center,
            //     //   children: [
            //     //           IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,onPressed: (){
            //     //         putBookMarkApiCall(filteredSolutionReport?[_currentQuestionIndex].examId??"",filteredSolutionReport?[_currentQuestionIndex].questionId,"");
            //     //     }, icon: Icon(filteredSolutionReport?[_currentQuestionIndex].bookmarks??false ? Icons.bookmark : Icons.bookmark_add_outlined,color: Theme.of(context).hintColor,)),
            //     //
            //     //     TextButton(onPressed: (){
            //     //       _showDialog(context,filteredSolutionReport?[_currentQuestionIndex].questionId??"");
            //     //     },
            //     //         child: Column(
            //     //           children: [
            //     //             Icon(Icons.question_mark, color: Theme.of(context).hintColor),
            //     //             Text('Raise Query',
            //     //               style: interRegular.copyWith(
            //     //                 fontSize: Dimensions.fontSizeDefault,
            //     //                 fontWeight: FontWeight.w400,
            //     //                 color: Theme.of(context).hintColor,
            //     //               ),),
            //     //           ],
            //     //         )),
            //     //
            //     //           IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,
            //     //         onPressed:()async{
            //     //           SolutionReportsModel? solutionReport = filteredSolutionReport?[_currentQuestionIndex];
            //     //
            //     //           final questionText =solutionReport?.questionText;
            //     //           final currentOption = solutionReport?.correctOption;
            //     //
            //     //           final answerTitle = solutionReport?.options?.map((e) => e.answerTitle);
            //     //
            //     //           int currentIndex = solutionReport?.options?.indexWhere((e) => e.value == currentOption) ?? -1;
            //     //           String? currentAnswerTitle = answerTitle?.elementAt(currentIndex);
            //     //
            //     //           List<String?> notMatchingAnswerTitles = answerTitle?.where((title) => title != currentAnswerTitle).toList() ?? [];
            //     //           String concatenatedTitles = notMatchingAnswerTitles.where((title) => title != null).join(", ");
            //     //
            //     //           String question = "Explain why $currentAnswerTitle is the answer to the Question $questionText and why the remaining $concatenatedTitles are not correct answer";
            //     //           isbutton == false ? await _getExplanationData(question ??'') : null;
            //     //         },
            //     //
            //     //         icon: Icon(Icons.lightbulb)),
            //     //   ],
            //     // ),
            //   ],
            // ),
            Padding(
              padding: const EdgeInsets.only(
                top: Dimensions.PADDING_SIZE_LARGE * 2,
                left: Dimensions.PADDING_SIZE_SMALL * 1.6,
                right: Dimensions.PADDING_SIZE_SMALL * 1.5,
                // bottom: Dimensions.PADDING_SIZE_LARGE*1.4,
              ),
              child: Row(
                children: [
                  // Row(
                  //   crossAxisAlignment: CrossAxisAlignment.center,
                  //   children: [
                  //     Container(
                  //       height: Dimensions.PADDING_SIZE_DEFAULT * 2,
                  //       width: Dimensions.PADDING_SIZE_DEFAULT * 5,
                  //       decoration: BoxDecoration(
                  //           color: ThemeManager.borderBlue,
                  //           borderRadius: BorderRadius.circular(Dimensions.RADIUS_LARGE)
                  //       ),
                  //       child: Center(
                  //         child: Text("Q-${(filteredSolutionReport?[_currentQuestionIndex].questionNumber ??
                  //             (widget.solutionReport?[_currentQuestionIndex].questionNumber ?? "").toString().padLeft(2, '0'))}",
                  //           style: interRegular.copyWith(
                  //             fontSize: Dimensions.fontSizeDefault,
                  //             fontWeight: FontWeight.w400,
                  //             color: ThemeManager.black,
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //     const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
                  //     Text("Out of ${filteredSolutionReport?.length}",
                  //       style: interRegular.copyWith(
                  //         fontSize: Dimensions.fontSizeDefault,
                  //         fontWeight: FontWeight.w400,
                  //         color: Theme.of(context).hintColor,
                  //       ),),
                  //   ],
                  // ),
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
                              color: ThemeManager.skipColor, borderRadius: BorderRadius.circular(60.87)),
                          child: Text(
                            "Guessed",
                            style: interRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              fontWeight: FontWeight.w500,
                              color: ThemeManager.black,
                            ),
                          ),
                        )
                      : filteredSolutionReport?[_currentQuestionIndex].selectedOption == ""
                          ? Container(
                              height: Dimensions.PADDING_SIZE_SMALL * 2.7,
                              width: Dimensions.PADDING_SIZE_LARGE * 3.85,
                              alignment: Alignment.center,
                              //padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_DEFAULT,vertical: Dimensions.PADDING_SIZE_SMALL),
                              decoration: BoxDecoration(
                                  color: ThemeManager.skipColor, borderRadius: BorderRadius.circular(60.87)),
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
                  InkWell(
                    onTap: () async {
                      if (!isbutton) {
                        setState(() {
                          isprocess = true;
                        });
                      }
                      QuizSolutionReportsModel? solutionReport =
                          filteredSolutionReport?[_currentQuestionIndex];

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
                    child: Container(
                      height: Dimensions.PADDING_SIZE_SMALL * 2.7,
                      width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 4,
                      alignment: Alignment.center,
                      // padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_DEFAULT),
                      decoration: BoxDecoration(
                          color: ThemeManager.primaryWhite, borderRadius: BorderRadius.circular(18.71)),
                      child: isprocess == true
                          ? Center(
                              child: SizedBox(
                                  height: 25,
                                  width: 25,
                                  child: CircularProgressIndicator(
                                    color: ThemeManager.white,
                                  )))
                          : Text(
                              "Ask Cortex.AI",
                              style: interRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                fontWeight: FontWeight.w500,
                                color: ThemeManager.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(
                    width: Dimensions.PADDING_SIZE_EXTRA_SMALL * 1.6,
                  ),
                  InkWell(
                    onTap: () {
                      // debugPrint("filteredSolutionReport?[_currentQuestionIndex].questionId:${filteredSolutionReport?[_currentQuestionIndex].questionId}");
                      _showDialog(
                          context,
                          filteredSolutionReport?[_currentQuestionIndex].questionId ?? "",
                          filteredSolutionReport?[_currentQuestionIndex].questionText ?? '',
                          "a) ${filteredSolutionReport?[_currentQuestionIndex].options?[0].answerTitle}\nb) ${filteredSolutionReport?[_currentQuestionIndex].options?[1].answerTitle}\nc) ${filteredSolutionReport?[_currentQuestionIndex].options?[2].answerTitle}\nd) ${filteredSolutionReport?[_currentQuestionIndex].options?[3].answerTitle}");
                    },
                    child: Container(
                      height: Dimensions.PADDING_SIZE_SMALL * 2.7,
                      width: Dimensions.PADDING_SIZE_LARGE * 4.7,
                      alignment: Alignment.center,
                      //padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_DEFAULT,vertical: Dimensions.PADDING_SIZE_SMALL),
                      decoration: BoxDecoration(
                          color: ThemeManager.whitePrimary,
                          borderRadius: BorderRadius.circular(18.71),
                          border: Border.all(
                            color: ThemeManager.primaryColor,
                          )),
                      child: Text(
                        "Raise Query",
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          fontWeight: FontWeight.w400,
                          color: ThemeManager.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),

          //Question and options
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: Dimensions.PADDING_SIZE_SMALL * 1.5,
                right: Dimensions.PADDING_SIZE_SMALL * 2,
                // bottom: Dimensions.PADDING_SIZE_LARGE*1.4,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // if (filteredSolutionReport?.isEmpty ?? true)
                    //   Center(
                    //     child: Text(
                    //       "No filtered data available",
                    //       style: interRegular.copyWith(
                    //         fontSize: Dimensions.fontSizeDefault,
                    //         fontWeight: FontWeight.w400,
                    //         color: ThemeManager.black,
                    //       ),
                    //     ),
                    //   )
                    // else
                    //   filteredSolutionReport?[_currentQuestionIndex].guess != ""
                    //       ? Text(
                    //     "You have Guessed this question",
                    //     style: interRegular.copyWith(
                    //       fontSize: Dimensions.fontSizeDefault,
                    //       fontWeight: FontWeight.w400,
                    //       color: ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.black : Colors.brown,
                    //     ),
                    //   ): filteredSolutionReport?[_currentQuestionIndex].selectedOption == ""
                    //       ? Text(
                    //     "You have skipped this question",
                    //     style: interRegular.copyWith(
                    //       fontSize: Dimensions.fontSizeDefault,
                    //       fontWeight: FontWeight.w400,
                    //       color: Colors.orangeAccent,
                    //     ),
                    //   ): const SizedBox(),
                    const SizedBox(
                      height: Dimensions.PADDING_SIZE_SMALL * 1.2,
                    ),

                    if (filteredSolutionReport?.isNotEmpty ?? false)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text(
                          //   filteredSolutionReport?[_currentQuestionIndex].questionText ??
                          //       (widget.solutionReport?[_currentQuestionIndex].questionText ?? ""),
                          //   style: interRegular.copyWith(
                          //     fontSize: Dimensions.fontSizeDefault,
                          //     fontWeight: FontWeight.w400,
                          //     color: ThemeManager.black,
                          //   ),
                          // ),
                          // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
                          //
                          // //Question Image
                          // (filteredSolutionReport?[_currentQuestionIndex].questionImg?.isNotEmpty ?? false)?
                          // // filteredSolutionReport?[_currentQuestionIndex].questionImg?[0] != ""?
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

                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   crossAxisAlignment: CrossAxisAlignment.start,
                          //   children: [
                          //     Expanded(child: questionWidget??const SizedBox()),
                          //               IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,onPressed: (){
                          //             putBookMarkApiCall(filteredSolutionReport?[_currentQuestionIndex].examId??"",filteredSolutionReport?[_currentQuestionIndex].questionId,"");
                          //         }, icon: Icon(filteredSolutionReport?[_currentQuestionIndex].bookmarks??false ? Icons.bookmark : Icons.bookmark_border,color: Theme.of(context).hintColor,)),
                          //   ],
                          // ),

                          //Questions and options
                          questionWidget ?? const SizedBox(),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredSolutionReport?[_currentQuestionIndex].options?.length,
                            itemBuilder: (BuildContext context, int index) {
                              QuizSolutionReportsModel? solutionReport =
                                  filteredSolutionReport?[_currentQuestionIndex];
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
                                        borderRadius: BorderRadius.circular(33.44),
                                        color: showColor.withOpacity(0.1),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: Dimensions.PADDING_SIZE_LARGE,
                                          vertical: Dimensions.PADDING_SIZE_SMALL * 1.3,
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Container(
                                            //   height: Dimensions.PADDING_SIZE_DEFAULT * 2,
                                            //   width: Dimensions.PADDING_SIZE_DEFAULT * 2,
                                            //   decoration: BoxDecoration(
                                            //       color: ThemeManager.borderBlue,
                                            //       borderRadius: BorderRadius.circular(Dimensions.RADIUS_LARGE)
                                            //   ),
                                            //   child: Center(
                                            //     child: Text(solutionReport?.options?[index].value??"",
                                            //       style: interRegular.copyWith(
                                            //         fontSize: Dimensions.fontSizeDefault,
                                            //         fontWeight: FontWeight.w400,
                                            //         color: ThemeManager.black,
                                            //       ),
                                            //     ),
                                            //   ),
                                            // ),
                                            // Text(solutionReport?.options?[index].value??"",
                                            //   style: interRegular.copyWith(
                                            //     fontSize: Dimensions.fontSizeDefault,
                                            //     fontWeight: FontWeight.w400,
                                            //     color: ThemeManager.black,
                                            //   ),
                                            // ),
                                            // const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT,),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // SizedBox(
                                                //   width: MediaQuery.of(context).size.width * 0.6,
                                                //   child: Text(
                                                //     "${solutionReport?.options?[index].value??""}.  ${solutionReport?.options?[index].answerTitle??""}",
                                                //     style: TextStyle(
                                                //       fontSize: Dimensions.fontSizeLarge,
                                                //       fontWeight: FontWeight.w500,
                                                //       color: showColor2,
                                                //     ),
                                                //   ),
                                                // ),
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                      width: MediaQuery.of(context).size.width * 0.6,
                                                      child: Text(
                                                        solutionReport?.options?[index].answerTitle ?? "",
                                                        style: TextStyle(
                                                          fontSize: Dimensions.fontSizeLarge,
                                                          fontWeight: FontWeight.w400,
                                                          color: showColor2,
                                                        ),
                                                      ),
                                                    )
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
                              );
                            },
                          ),
                          const SizedBox(
                            height: Dimensions.PADDING_SIZE_SMALL * 1.7,
                          ),
                          //Solution Explanation
                          Observer(
                            builder: (BuildContext context) {
                              GetNotesSolutionModel? noteModel = store.notesData.value;
                              return Row(
                                children: [
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
                                  IconButton(
                                    icon: Image.asset("assets/image/stickyIcon.png",
                                        width: Dimensions.PADDING_SIZE_LARGE * 1.6,
                                        height: Dimensions.PADDING_SIZE_LARGE * 1.6),
                                    onPressed: () {
                                      _showNotesDialog(
                                          context,
                                          filteredSolutionReport?[_currentQuestionIndex].questionId ?? "",
                                          noteModel?.notes ?? "");
                                    },
                                  ),
                                  const SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
                                  IconButton(
                                    icon: Image.asset("assets/image/font_icon.png",
                                        width: Dimensions.PADDING_SIZE_LARGE * 1.6,
                                        height: Dimensions.PADDING_SIZE_LARGE * 1.6),
                                    onPressed: () => _showBottomSheet(context),
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
                          const SizedBox(
                            height: Dimensions.PADDING_SIZE_DEFAULT,
                          ),
                          // Text(modifiedExplanation,
                          //   style: interBlack.copyWith(
                          //     fontSize: Dimensions.fontSizeDefault,
                          //     fontWeight: FontWeight.w400,
                          //     color: ThemeManager.black,
                          //   ),),
                          // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
                          // (filteredSolutionReport?[_currentQuestionIndex].explanationImg?.isNotEmpty ?? false)?
                          // InteractiveViewer(
                          //   minScale: 1.0,
                          //   maxScale: 3.0,
                          //   child: Center(
                          //     child: SizedBox(
                          //       width: MediaQuery.of(context).size.width * 0.6,
                          //       height: 250,
                          //       child: Stack(
                          //         children: [
                          //           if (explanationImgBytes != null)
                          //             Image.memory(explanationImgBytes!),
                          //           Container(color: Colors.transparent),
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          // ):const SizedBox(),

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
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: Dimensions.PADDING_SIZE_DEFAULT,
          ),

          //next and previous buttons
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
                  InkWell(
                    onTap: isprocess == true ? null : (firstQue ? null : _showPreviousQuestion),
                    child: Container(
                      height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.14,
                      width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.14,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                firstQue ? ThemeManager.nextButtonBorder : ThemeManager.previousNextPrimary,
                          )),
                      child: SvgPicture.asset(
                        "assets/image/arrow_back.svg",
                        color: firstQue ? ThemeManager.nextButtonBorder : ThemeManager.previousNextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: Dimensions.PADDING_SIZE_DEFAULT * 1.1,
                  ),
                  InkWell(
                    onTap: isprocess == true ? null : (lastQue ? null : _showNextQuestion),
                    child: Container(
                      height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.14,
                      width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.14,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: ThemeManager.previousNextPrimary)),
                      child: Transform.flip(
                          flipX: true,
                          child: SvgPicture.asset(
                            "assets/image/arrow_back.svg",
                            color: ThemeManager.previousNextPrimary,
                          )),
                    ),
                  ),
                ],
              ),
            ),
          //   Row(
          //   children: [
          //     Expanded(
          //       child: SizedBox(
          //         height: Dimensions.PADDING_SIZE_EXTRA_LARGE*2,
          //         child: ElevatedButton(
          //             style: ElevatedButton.styleFrom(
          //                 shape: RoundedRectangleBorder(
          //                   borderRadius: BorderRadius.circular(8),
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
          //                   borderRadius: BorderRadius.circular(8),
          //                 ),
          //                 backgroundColor: Theme.of(context).primaryColor
          //             ),
          //             onPressed:isprocess == true ? null : (lastQue?null:_showNextQuestion),
          //             child: Text("Next",
          //               style: TextStyle(
          //                 fontSize: Dimensions.fontSizeDefault,
          //                 fontWeight: FontWeight.w400,
          //                 color: ThemeManager.home1,
          //               ),)),
          //       ),
          //     ),
          //   ],
          // ),
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
      final double? selectedFontSize = await showModalBottomSheet<double>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        builder: (BuildContext context) {
          double currentFontSize = _textSize;
          double showCurrFontSize = showfontSize;

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
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
                ),
              );
            },
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
}
