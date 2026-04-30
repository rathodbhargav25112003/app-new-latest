import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:shusruta_lms/services/daily_review_recorder.dart';
import 'package:shusruta_lms/services/smart_resume_service.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_svg/svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/comman_widget.dart';
import 'package:shusruta_lms/modules/masterTest/question_master_pallet.dart';
import 'package:shusruta_lms/modules/reports/explanation_common_widget.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/widgets/bottom_stick_notes_window.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:typewritertext/typewritertext.dart';

import '../../app/routes.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/get_explanation_model.dart';
import '../../models/get_notes_solution_model.dart';
import '../../models/test_exampaper_list_model.dart';
import '../reports/master reports/master_bottom_raise_query.dart';
import '../reports/store/report_by_category_store.dart';
import '../widgets/bottom_stick_notes.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';

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
  State<PracticeMasterTestExamScreen> createState() => _PracticeMasterTestExamScreenState();
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

class _PracticeMasterTestExamScreenState extends State<PracticeMasterTestExamScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
  bool isTapped = false;
  // Duration? duration;
  // String? usedExamTime;
  Widget? explanationWidget;
  Widget? questionWidget;
  final _controller = SuperTooltipController();
  bool isbutton = false, isprocess = false;
  double _textSize = Dimensions.fontSizeDefault;
  late QuillController _quillController = QuillController.basic();
  double showfontSize = 100;

  @override
  void initState() {
    super.initState();
    // updateTimer();
    isTapped = false;
    int matchingIndex = widget.testExamPaper?.test?.indexWhere((e) => e.questionNumber == widget.queNo) ?? -1;
    if (matchingIndex != -1) {
      String? matchingQueId = widget.testExamPaper?.test?[matchingIndex].sId;
      _getSelectedAnswer(matchingQueId!);
      _currentQuestionIndex = matchingIndex;
      setState(() {
        firstQue = false;
      });
    }

    _getNotesData(widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "");

    // Smart Resume hook — push this in-progress mock test into
    // SmartResumeService so the home banner can offer a 1-tap
    // resume. Fire-and-forget; failures don't block the test.
    final userExamId = widget.userExamId ?? '';
    final examName = widget.testExamPaper?.examName ?? 'Mock test';
    final totalQs = widget.testExamPaper?.test?.length ?? 0;
    if (userExamId.isNotEmpty) {
      // ignore: discarded_futures
      SmartResumeService.instance.recordMockExam(
        userExamId: userExamId,
        examName: examName,
        currentQuestion: _currentQuestionIndex + 1,
        totalQuestions: totalQs,
        examId: widget.testExamPaper?.examId,
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
    super.dispose();
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
    await store.userAnswerMasterTest(context, userExamId ?? "", questionId ?? "", selectedOption ?? "",
        isAttempted, isAttemptedAndMarkedForReview, isSkipped, isMarkedForReview, guess, time, "00:00:00");
  }

  Future<void> _getSelectedAnswer(String queId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.questionAnswerById(widget.userExamId ?? "", queId);
    setState(() {
      String? nextOption = store.userAnswerExam.value?.selectedOption;
      _selectedIndex = widget.testExamPaper?.test?[_currentQuestionIndex].optionsData
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
    final question = widget.testExamPaper?.test?[_currentQuestionIndex];
    String? questionId = question?.sId;

    String? selectedOption = _selectedIndex == -1
        ? ""
        : question?.optionsData?[_selectedIndex].value;

    // Daily-review pool sync — push to incorrect pool on wrong, pull
    // when right (e.g. retake).
    if (question != null &&
        selectedOption != null &&
        selectedOption.isNotEmpty &&
        (question.correctOption ?? '').isNotEmpty) {
      if (selectedOption != question.correctOption) {
        // ignore: discarded_futures
        DailyReviewRecorder.recordWrong(
            question, question.examId, selectedOption);
      } else {
        // ignore: discarded_futures
        DailyReviewRecorder.recordCorrect(question);
      }
    }
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
    await _postSelectedAnswerApiCall(widget.userExamId, selectedOption, questionId, isAttempted,
        isAttemptedAndMarkedForReview, isSkipped, isMarkedForReview, selectedOption!, "");
  }

  void openBottomSheet(TestCategoryStore store) {
    // showModalBottomSheet<void>(
    //   shape: const RoundedRectangleBorder(
    //     borderRadius: BorderRadius.vertical(
    //       top: Radius.circular(25),
    //     ),
    //   ),
    //   clipBehavior: Clip.antiAliasWithSaveLayer,
    //   context: context,
    //   builder: (BuildContext context) {
    //     String attempted="0",markedForReview="0",skipped="0",attemptedandMarkedForReview="0",notVisited="0";
    //     attempted = store.testQuePalleteCount.value?.isAttempted.toString().padLeft(2,'0')??"0";
    //     markedForReview = store.testQuePalleteCount.value?.isMarkedForReview.toString().padLeft(2,'0')??"0";
    //     skipped = store.testQuePalleteCount.value?.isSkipped.toString().padLeft(2,'0')??"0";
    //     attemptedandMarkedForReview = store.testQuePalleteCount.value?.isAttemptedMarkedForReview.toString().padLeft(2,'0')??"0";
    //     notVisited = store.testQuePalleteCount.value?.notVisited.toString().padLeft(2,'0')??"0";
    //     return Container(
    //       height: MediaQuery.of(context).size.height * 0.30,
    //       color: ThemeManager.reportContainer,
    //       child: Padding(
    //         padding: const EdgeInsets.only(
    //             top: Dimensions.PADDING_SIZE_EXTRA_LARGE,
    //             bottom: Dimensions.PADDING_SIZE_EXTRA_LARGE,
    //             left: Dimensions.PADDING_SIZE_EXTRA_LARGE,
    //             right: Dimensions.PADDING_SIZE_EXTRA_LARGE),
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: <Widget>[
    //             Text("Do you want to exit the practice mode?",
    //               style: interSemiBold.copyWith(
    //                 fontSize: Dimensions.fontSizeExtraLarge,
    //                 fontWeight: FontWeight.w600,
    //                 color: ThemeManager.black,
    //               ),
    //               textAlign: TextAlign.center,),
    //             const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_LARGE,),
    //             // Row(
    //             //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //             //   children: [
    //             //     Text("Time Left",
    //             //       style: interSemiBold.copyWith(
    //             //         fontSize: Dimensions.fontSizeSmall,
    //             //         fontWeight: FontWeight.w500,
    //             //         color: Theme.of(context).hintColor,
    //             //       ),),
    //             //     Text("${remainingTimeNotifier.value.inHours.toString().padLeft(2, '0')}:${remainingTimeNotifier.value.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTimeNotifier.value.inSeconds.remainder(60).toString().padLeft(2, '0')}",
    //             //       style: interSemiBold.copyWith(
    //             //         fontSize: Dimensions.fontSizeSmall,
    //             //         fontWeight: FontWeight.w600,
    //             //         color: ThemeManager.greenSuccess,
    //             //       ),),
    //             //   ],
    //             // ),
    //             // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
    //             // Row(
    //             //   children: [
    //             //     const CircleAvatar(
    //             //       radius: 5.0,
    //             //       backgroundColor: Colors.green,
    //             //     ),
    //             //     const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
    //             //     Text("Attempted",
    //             //       style: interRegular.copyWith(
    //             //         fontSize: Dimensions.fontSizeSmall,
    //             //         fontWeight: FontWeight.w400,
    //             //         color: Theme.of(context).hintColor,
    //             //       ),),
    //             //     const Spacer(),
    //             //     Text(attempted, style: interRegular.copyWith(
    //             //       fontSize: Dimensions.fontSizeSmall,
    //             //       fontWeight: FontWeight.w400,
    //             //       color: Theme.of(context).hintColor,
    //             //     ),)
    //             //   ],
    //             // ),
    //             // const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL,),
    //             // Row(
    //             //   children: [
    //             //     const CircleAvatar(
    //             //       radius: 5.0,
    //             //       backgroundColor: Colors.blue,
    //             //     ),
    //             //     const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
    //             //     Text("Marked for Review",
    //             //       style: interRegular.copyWith(
    //             //         fontSize: Dimensions.fontSizeSmall,
    //             //         fontWeight: FontWeight.w400,
    //             //         color: Theme.of(context).hintColor,
    //             //       ),),
    //             //     const Spacer(),
    //             //     Text(markedForReview, style: interRegular.copyWith(
    //             //       fontSize: Dimensions.fontSizeSmall,
    //             //       fontWeight: FontWeight.w400,
    //             //       color: Theme.of(context).hintColor,
    //             //     ),)
    //             //   ],
    //             // ),
    //             // const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
    //             // Row(
    //             //   children: [
    //             //     const CircleAvatar(
    //             //       radius: 5.0,
    //             //       backgroundColor: Colors.orange,
    //             //     ),
    //             //     const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
    //             //     Text("Attempted and Marked for Review",
    //             //       style: interRegular.copyWith(
    //             //         fontSize: Dimensions.fontSizeSmall,
    //             //         fontWeight: FontWeight.w400,
    //             //         color: Theme.of(context).hintColor,
    //             //       ),),
    //             //     const Spacer(),
    //             //     Text(attemptedandMarkedForReview, style: interRegular.copyWith(
    //             //       fontSize: Dimensions.fontSizeSmall,
    //             //       fontWeight: FontWeight.w400,
    //             //       color: Theme.of(context).hintColor,
    //             //     ),)
    //             //   ],
    //             // ),
    //             // const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
    //             // Row(
    //             //   children: [
    //             //     const CircleAvatar(
    //             //       radius: 5.0,
    //             //       backgroundColor: Colors.red,
    //             //     ),
    //             //     const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
    //             //     Text("Skipped",
    //             //       style: interRegular.copyWith(
    //             //         fontSize: Dimensions.fontSizeSmall,
    //             //         fontWeight: FontWeight.w400,
    //             //         color: Theme.of(context).hintColor,
    //             //       ),),
    //             //     const Spacer(),
    //             //     Text(skipped, style: interRegular.copyWith(
    //             //       fontSize: Dimensions.fontSizeSmall,
    //             //       fontWeight: FontWeight.w400,
    //             //       color: Theme.of(context).hintColor,
    //             //     ),)
    //             //   ],
    //             // ),
    //             // const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
    //             // Row(
    //             //   children: [
    //             //     const CircleAvatar(
    //             //       radius: 5.0,
    //             //       backgroundColor: ThemeManager.lightBlue,
    //             //     ),
    //             //     const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
    //             //     Text("Not Visited",
    //             //       style: interRegular.copyWith(
    //             //         fontSize: Dimensions.fontSizeSmall,
    //             //         fontWeight: FontWeight.w400,
    //             //         color: Theme.of(context).hintColor,
    //             //       ),),
    //             //     const Spacer(),
    //             //     Text(notVisited, style: interRegular.copyWith(
    //             //       fontSize: Dimensions.fontSizeSmall,
    //             //       fontWeight: FontWeight.w400,
    //             //       color: Theme.of(context).hintColor,
    //             //     ),)
    //             //   ],
    //             // ),
    //             // const SizedBox(height: Dimensions.PADDING_SIZE_LARGE * 2),
    //             const Spacer(),
    //             Row(
    //               children: [
    //                 SizedBox(
    //                   width: MediaQuery.of(context).size.width * 0.4,
    //                   height: MediaQuery.of(context).size.height * 0.055,
    //                   child: ElevatedButton(
    //                       style: ElevatedButton.styleFrom(
    //                           shape: RoundedRectangleBorder(
    //                             borderRadius: BorderRadius.circular(8),
    //                           ),
    //                           backgroundColor: ThemeManager.btnGrey
    //                       ),
    //                       onPressed: (){
    //                         Navigator.of(context).pop();
    //                         setState(() {
    //                           _currentQuestionIndex=0;
    //                           isLastQues=false;
    //                         });
    //                       },
    //                       child: Text("Resume",
    //                         style: TextStyle(
    //                           fontSize: Dimensions.fontSizeDefault,
    //                           fontWeight: FontWeight.w400,
    //                           color: Colors.white,
    //                         ),)),
    //                 ),
    //                 const Spacer(),
    //                 SizedBox(
    //                   width: MediaQuery.of(context).size.width * 0.4,
    //                   height: MediaQuery.of(context).size.height * 0.055,
    //                   child: ElevatedButton(
    //                       style: ElevatedButton.styleFrom(
    //                           shape: RoundedRectangleBorder(
    //                             borderRadius: BorderRadius.circular(8),
    //                           ),
    //                           backgroundColor:ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.white : Theme.of(context).primaryColor,
    //                       ),
    //                       onPressed: (){
    //                         // remainingTimeNotifier.dispose();
    //                         Navigator.of(context).pushNamed(Routes.testCategory);
    //                       },
    //                       child: Text("End Practice",
    //                         style: TextStyle(
    //                           fontSize: Dimensions.fontSizeDefault,
    //                           fontWeight: FontWeight.w400,
    //                           color: ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.white : Colors.white,
    //                         ),)),
    //                 ),
    //               ],
    //             ),
    //           ],
    //         ),
    //       ),
    //     );
    //   },
    // );
    getCountReportPractice(context);
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
                    '${store.getMockReportPracticeCountData.value?.correctAnswers}',
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
                    '${store.getMockReportPracticeCountData.value?.incorrectAnswers}',
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
                    '${store.getMockReportPracticeCountData.value?.notVisited}',
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
            onTap: () => Navigator.of(context).pushNamed(Routes.allTestCategory),
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
    String? questionId = widget.testExamPaper?.test?[_currentQuestionIndex].sId;

    String? selectedOption = _selectedIndex == -1
        ? ""
        : widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[_selectedIndex].value;
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
    await _postSelectedAnswerApiCall(widget.userExamId, selectedOption, questionId, isAttempted,
        isAttemptedAndMarkedForReview, isSkipped, isMarkedForReview, selectedOption!, "");
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
      if (_currentQuestionIndex >= (widget.testExamPaper?.test?.length ?? 0) - 1) {
        isLastQues = true;
        _currentQuestionIndex = (widget.testExamPaper?.test?.length ?? 0) - 1;
      } else {
        isLastQues = false;
      }

      String? questionId1 = widget.testExamPaper?.test?[_currentQuestionIndex].sId;
      _getSelectedAnswer(questionId1 ?? "");

      explanationWidget = getExplanationText(context);
      questionWidget = getQuestionText(context);
      _getNotesData(widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "");
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

      String? questionId = widget.testExamPaper?.test?[_currentQuestionIndex].sId;
      _getSelectedAnswer(questionId ?? "");

      explanationWidget = getExplanationText(context);
      questionWidget = getQuestionText(context);
      _getNotesData(widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "");
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

  // Widget getExplanationText(BuildContext context) {
  //   String explanation =
  //       widget.testExamPaper?.test?[_currentQuestionIndex].explanation ?? "";
  //   explanation = explanation.replaceAllMapped(
  //       RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
  //   List<String> splittedText = explanation.split("splittedImage");
  //   List<Widget> columns = [];
  //   int index = 0;
  //
  //   for (String text in splittedText) {
  //     List<Widget> explanationImageWidget = [];
  //     if (widget.testExamPaper?.test?[_currentQuestionIndex].explanationImg
  //             ?.isNotEmpty ??
  //         false) {
  //       for (String base64String in widget
  //           .testExamPaper!.test![_currentQuestionIndex].explanationImg!) {
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
  //             ? Text(
  //                 "Tap the image to zoom In/Out",
  //                 style: interBlack.copyWith(
  //                   fontSize: Dimensions.fontSizeSmall,
  //                   fontWeight: FontWeight.w400,
  //                   color: ThemeManager.black,
  //                 ),
  //               )
  //             : const SizedBox(),
  //         ],
  //       ),
  //     );
  //     index++;
  //
  //     if (index >=
  //         (widget.testExamPaper?.test?[_currentQuestionIndex].explanationImg
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
    final currentData = widget.testExamPaper?.test![_currentQuestionIndex];

    List<Widget> columns = [];

    /// TEXT
    String explanation = currentData?.explanation ?? "";
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
    if (currentData?.explanationImg != null && currentData!.explanationImg!.isNotEmpty) {
      columns.add(const SizedBox(height: 12));

      columns.add(
        Column(
          children: currentData!.explanationImg!.map<Widget>((imageUrl) {
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
    if (widget.testExamPaper?.test == null ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= (widget.testExamPaper?.test?.length ?? 0)) {
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

    String questionTxt = widget.testExamPaper?.test?[_currentQuestionIndex].questionText ?? "";
    questionTxt =
        questionTxt.replaceAllMapped(RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    List<String> splittedText = questionTxt.split("splittedImage");
    List<Widget> columns = [];
    int index = 0;
    for (String text in splittedText) {
      List<Widget> questionImageWidget = [];
      if (widget.testExamPaper?.test?[_currentQuestionIndex].questionImg?.isNotEmpty ?? false) {
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
            const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
            Column(
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
      if (index >= (widget.testExamPaper?.test?[_currentQuestionIndex].questionImg?.length ?? 0) - 1) {
        break;
      }
    }
    return Column(
      children: columns,
    );
  }

  final ScrollController _scrollController = ScrollController();

  void _scrollToIndex(int index) {
    double totalWidth = (widget.testExamPaper?.test?.length ?? 0) *
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
          backgroundColor: ThemeManager.white,
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
          //             builder: (context) => const CustomMasterTestCancelDialogBox(null,null,true),
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
          appBar: AppBar(
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: ThemeManager.white,
            title: Row(
              children: [
                InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed(Routes.allTestCategory);
                    },
                    child: SvgPicture.asset(
                      "assets/image/arrow_back.svg",
                      color: ThemeManager.currentTheme == AppTheme.Dark ? AppColors.white : null,
                    )),

                const SizedBox(
                  width: Dimensions.RADIUS_EXTRA_LARGE * 1.1,
                ),
                Text(
                  "${widget.testExamPaper?.examName}",
                  style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                      color: ThemeManager.black,
                      decorationColor: ThemeManager.black),
                ),
                if (!(MediaQuery.of(context).size.width > 1160 && MediaQuery.of(context).size.height > 670))
                  const SizedBox(
                    width: Dimensions.RADIUS_EXTRA_LARGE * 1.1,
                  ),
                if (!(MediaQuery.of(context).size.width > 1160 && MediaQuery.of(context).size.height > 670))
                  InkWell(
                    onTap: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    child: Image.asset(
                      "assets/image/questionplatte.png",
                      width: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                    ),
                  ),
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
                    _putBookMarkApiCall(widget.testExamPaper?.examId ?? "",
                        widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "");
                  },
                  child: Container(
                    height: Dimensions.PADDING_SIZE_LARGE * 1.2,
                    width: Dimensions.PADDING_SIZE_LARGE * 1.2,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.testExamPaper?.test?[_currentQuestionIndex].bookmarks ?? false
                          ? ThemeManager.primaryWhite
                          : ThemeManager.primaryWhite.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.testExamPaper?.test?[_currentQuestionIndex].bookmarks ?? false
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: ThemeManager.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(
                  width: Dimensions.RADIUS_EXTRA_LARGE,
                ),
                InkWell(
                  onTap: () async {
                    // showDialog(
                    //   context: context,
                    //   builder: (context) => const CustomTestCancelDialogBox(null,null,true),
                    // );
                    await getCountReportPractice(context);
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
                          child: Observer(builder: (context) {
                            return Column(
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
                                      decoration: const BoxDecoration(
                                          color: Color(0xFF329B62), shape: BoxShape.circle),
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
                                      '${store2.getMockReportPracticeCountData.value?.correctAnswers}',
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
                                      decoration: const BoxDecoration(
                                          color: Color(0xFFFF0000), shape: BoxShape.circle),
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
                                      '${store2.getMockReportPracticeCountData.value?.incorrectAnswers}',
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
                                      decoration: const BoxDecoration(
                                          color: Color(0xFFFFD53F), shape: BoxShape.circle),
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
                                      '${store2.getMockReportPracticeCountData.value?.notVisited}',
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefaultLarge,
                                        fontWeight: FontWeight.w700,
                                        color: ThemeManager.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }),
                        ),
                        actions: [
                          InkWell(
                            onTap: () => Navigator.of(context).pushNamed(Routes.allTestCategory),
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
                  },
                  child: Container(
                    height: Dimensions.PADDING_SIZE_SMALL * 2.7,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_LARGE),
                    decoration: BoxDecoration(
                        color: ThemeManager.transPrimary,
                        border: Border.all(
                          color: ThemeManager.blueFinalTrans,
                        ),
                        borderRadius: BorderRadius.circular(60)),
                    child: Text(
                      "Save & Exit",
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
          body: Row(
            children: [
              /*
              if (MediaQuery.of(context).size.width > 1160 &&
                  MediaQuery.of(context).size.height > 690)
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.22,
                  child: QuestionMasterPalletDrawer(
                    key: UniqueKey(),
                    widget.testExamPaper,
                    widget.userExamId,
                    null,
                    widget.isPracticeExam,
                    callBack: (testMasterExamData) {

                    },
                  ),
                ),
                */
              SizedBox(
                width: MediaQuery.of(context).size.width,
                // width: (MediaQuery.of(context).size.width > 1160 &&
                //         MediaQuery.of(context).size.height > 690)
                //     ? MediaQuery.of(context).size.width * 0.78
                //     : MediaQuery.of(context).size.width,
                child: Column(
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
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(
                          children: List.generate(widget.testExamPaper?.test?.length ?? 0, (index) {
                            TestData? solutionReport = widget.testExamPaper?.test?[index];

                            // Determine the background color for each question
                            Color determineBackgroundColor() {
                              if (solutionReport?.selectedOption != null) {
                                // Determine if the selected answer is correct or incorrect for this question
                                bool isCorrect = (solutionReport?.correctOption ?? "") ==
                                    (solutionReport?.selectedOption ?? "");
                                return isCorrect ? ThemeManager.greenBorder : ThemeManager.redText;
                              } else if (_currentQuestionIndex == index) {
                                // Apply the primary color for the current question if no answer is selected
                                return _selectedIndex == -1
                                    ? ThemeManager.primaryColor
                                    : ((solutionReport?.correctOption ?? "") ==
                                            (solutionReport?.optionsData?[_selectedIndex].value ?? "")
                                        ? ThemeManager.greenBorder
                                        : ThemeManager.redText);
                              } else {
                                return ThemeManager.white;
                              }
                            }

                            Color determineTextColor() {
                              if (solutionReport?.selectedOption != null &&
                                  solutionReport!.selectedOption!.isNotEmpty) {
                                return ThemeManager
                                    .white; // Text color white for both correct and incorrect answers
                              } else {
                                return _currentQuestionIndex == index
                                    ? ThemeManager.white
                                    : ThemeManager.black;
                              }
                            }

                            Color determineBorderColor() {
                              if (solutionReport?.selectedOption != null &&
                                  solutionReport!.selectedOption!.isNotEmpty) {
                                bool isCorrect =
                                    (solutionReport.correctOption ?? "") == solutionReport.selectedOption;
                                return isCorrect ? ThemeManager.greenBorder : ThemeManager.redText;
                              } else {
                                return _currentQuestionIndex == index
                                    ? ThemeManager.primaryColor
                                    : ThemeManager.black;
                              }
                            }

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
                                    color: determineBackgroundColor(),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: determineBorderColor(),
                                    )),
                                child: Text(
                                  "${index + 1}",
                                  style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      fontWeight: FontWeight.w500,
                                      color: determineTextColor()),
                                ),
                              ),
                            );
                          }),
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
                          //     child: Text("Q-${(widget.testExamPaper?.test?[_currentQuestionIndex].questionNumber??"").toString().padLeft(2, '0')}",
                          //       style: interRegular.copyWith(
                          //         fontSize: Dimensions.fontSizeDefault,
                          //         fontWeight: FontWeight.w400,
                          //         color: ThemeManager.black,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          // const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
                          // Text("Q-${(widget.testExamPaper?.test?[_currentQuestionIndex].questionNumber??"").toString().padLeft(2, '0')}/${widget.testExamPaper?.test?.length.toString().padLeft(2, '0') ?? 0}",
                          // Text("Q-${_currentQuestionIndex + 1}/${widget.testExamPaper?.test?.length.toString().padLeft(2, '0') ?? 0}",
                          //   style: interRegular.copyWith(
                          //     fontSize: Dimensions.fontSizeDefault,
                          //     fontWeight: FontWeight.w400,
                          //     color: Theme.of(context).hintColor,
                          //   ),),
                          // const Spacer(),
                          //       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,onPressed: (){
                          //   _putBookMarkApiCall(widget.testExamPaper?.examId??"",widget.testExamPaper?.test?[_currentQuestionIndex].sId??"");
                          // }, icon: Icon(widget.testExamPaper?.test?[_currentQuestionIndex].bookmarks ??false ? Icons.bookmark : Icons.bookmark_add_outlined,color: Theme.of(context).hintColor,)),
                          // Row(
                          //   crossAxisAlignment: CrossAxisAlignment.start,
                          //   children: [
                          //     TextButton(onPressed: (){
                          //       _showDialog(context,widget.testExamPaper?.test?[_currentQuestionIndex].sId??"");
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
                          // InkWell(
                          //   onTap: () async {
                          //     if( !isbutton){
                          //       setState(() {
                          //         isprocess = true;
                          //       });
                          //     }
                          //     TestData? solutionReport = widget.testExamPaper?.test?[_currentQuestionIndex];
                          //
                          //     final questionText =solutionReport?.questionText;
                          //     final currentOption = solutionReport?.correctOption;
                          //
                          //     final answerTitle = solutionReport?.optionsData?.map((e) => e.answerTitle);
                          //
                          //     int currentIndex = solutionReport?.optionsData?.indexWhere((e) => e.value == currentOption) ?? -1;
                          //     String? currentAnswerTitle = answerTitle?.elementAt(currentIndex);
                          //
                          //     List<String?> notMatchingAnswerTitles = answerTitle?.where((title) => title != currentAnswerTitle).toList() ?? [];
                          //     String concatenatedTitles = notMatchingAnswerTitles.where((title) => title != null).join(", ");
                          //
                          //     String question = "Explain why $currentAnswerTitle is the answer to the Question $questionText and why the remaining $concatenatedTitles are not correct answer";
                          //     debugPrint("question12 :${question}");
                          //     isbutton == false ? await _getExplanationData(question ??'') : null;
                          //   },
                          //   child: Container(
                          //     height: MediaQuery.of(context).size.height*0.048,
                          //     width: MediaQuery.of(context).size.width*0.32,
                          //     alignment: Alignment.center,
                          //     padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_DEFAULT,vertical: Dimensions.PADDING_SIZE_SMALL),
                          //     decoration: BoxDecoration(
                          //         color: ThemeManager.primaryColor,
                          //         borderRadius: BorderRadius.circular(20)
                          //     ),
                          //     child:isprocess == true ? Center(child: SizedBox(height: 25,width: 25,child: CircularProgressIndicator(color: ThemeManager.white,))) : Text("Ask Cortex.AI",
                          //       style: interRegular.copyWith(
                          //         fontSize: Dimensions.fontSizeSmall,
                          //         fontWeight: FontWeight.w400,
                          //         color: ThemeManager.white,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          // SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT,),
                          // InkWell(
                          //   onTap: (){
                          //     _showDialog(context,widget.testExamPaper?.test?[_currentQuestionIndex].sId??"");
                          //   },
                          //   child: Container(
                          //     height: MediaQuery.of(context).size.height*0.048,
                          //     width: MediaQuery.of(context).size.width*0.32,
                          //     alignment: Alignment.center,
                          //     padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_DEFAULT,vertical: Dimensions.PADDING_SIZE_SMALL),
                          //     decoration: BoxDecoration(
                          //         color: ThemeManager.primaryColor,
                          //         borderRadius: BorderRadius.circular(20)
                          //     ),
                          //     child:Text("Raise Query?",
                          //       style: interRegular.copyWith(
                          //         fontSize: Dimensions.fontSizeSmall,
                          //         fontWeight: FontWeight.w400,
                          //         color: ThemeManager.white,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          Text(
                            "${_currentQuestionIndex + 1}.",
                            style: interRegular.copyWith(
                              fontSize: Dimensions.fontSizeExtraExtraLarge,
                              fontWeight: FontWeight.w500,
                              color: ThemeManager.black,
                            ),
                          ),
                          const Spacer(),
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
                                  solutionReport?.optionsData?.indexWhere((e) => e.value == currentOption) ??
                                      -1;
                              String? currentAnswerTitle = answerTitle?.elementAt(currentIndex);

                              List<String?> notMatchingAnswerTitles =
                                  answerTitle?.where((title) => title != currentAnswerTitle).toList() ?? [];
                              String concatenatedTitles =
                                  notMatchingAnswerTitles.where((title) => title != null).join(", ");

                              String question =
                                  "Explain why $currentAnswerTitle is the answer to the Question $questionText and why the remaining $concatenatedTitles are not correct answer";
                              debugPrint("question12 :$question");
                              isbutton == false ? await _getExplanationData(question ?? '') : null;
                            },
                            child: Container(
                              height: Dimensions.PADDING_SIZE_SMALL * 2.7,
                              width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 4,
                              alignment: Alignment.center,
                              // padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_DEFAULT),
                              decoration: BoxDecoration(
                                  color: ThemeManager.primaryWhite,
                                  borderRadius: BorderRadius.circular(18.71)),
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
                            width: Dimensions.PADDING_SIZE_DEFAULT,
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
                                        MockBottomRaiseQuery(
                                            questionId:
                                                widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "",
                                            questionText: widget.testExamPaper?.test?[_currentQuestionIndex]
                                                    .questionText ??
                                                '',
                                            allOptions:
                                                "a) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[0].answerTitle}\nb) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[1].answerTitle}\nc) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[2].answerTitle}\nd) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[3].answerTitle}"),
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
                                          questionId:
                                              widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "",
                                          questionText: widget
                                                  .testExamPaper?.test?[_currentQuestionIndex].questionText ??
                                              '',
                                          allOptions:
                                              "a) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[0].answerTitle}\nb) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[1].answerTitle}\nc) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[2].answerTitle}\nd) ${widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?[3].answerTitle}");
                                      // return MockBottomRaiseQuery(questionId: widget.testExamPaper?.test?[_currentQuestionIndex].sId??"",);
                                    });
                              }
                              // _showDialog(context,widget.testExamPaper?.test?[_currentQuestionIndex].sId??"");
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
                    const SizedBox(
                      height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                    ),
                    Expanded(
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
                            //   widget.testExamPaper?.test?[_currentQuestionIndex].questionText??"",
                            //   style: interRegular.copyWith(
                            //     fontSize: Dimensions.fontSizeDefault,
                            //     fontWeight: FontWeight.w400,
                            //     color: ThemeManager.black,
                            //   ),),
                            // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
                            //
                            // widget.testExamPaper?.test?[_currentQuestionIndex].questionImg?.isNotEmpty ?? false?
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
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //   crossAxisAlignment: CrossAxisAlignment.start,
                            //   children: [
                            //     Expanded(child: questionWidget??const SizedBox()),
                            //           IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,onPressed: (){
                            //       _putBookMarkApiCall(widget.testExamPaper?.examId??"",widget.testExamPaper?.test?[_currentQuestionIndex].sId??"");
                            //     }, icon: Icon(widget.testExamPaper?.test?[_currentQuestionIndex].bookmarks??false ? Icons.bookmark : Icons.bookmark_border,color: Theme.of(context).hintColor,)),
                            //   ],
                            // ),
                            questionWidget ?? const SizedBox(),
                            const SizedBox(
                              height: Dimensions.PADDING_SIZE_DEFAULT,
                            ),

                            ListView.builder(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              itemCount:
                                  widget.testExamPaper?.test?[_currentQuestionIndex].optionsData?.length,
                              itemBuilder: (BuildContext context, int index) {
                                TestData? testExamPaper = widget.testExamPaper?.test?[_currentQuestionIndex];
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
                                      setState(() {
                                        if (widget.isPracticeExam == true) {
                                          if (!isTapped) {
                                            isTapped = true;
                                            _selectedIndex = index;
                                            widget.testExamPaper?.test?[_currentQuestionIndex]
                                                .selectedOption = testExamPaper?.optionsData?[index].value;
                                            _postPracticeData();
                                          }
                                        } else {
                                          if (isSelected) {
                                            _selectedIndex = -1;
                                          } else {
                                            _selectedIndex = index;
                                            widget.testExamPaper?.test?[_currentQuestionIndex]
                                                .selectedOption = testExamPaper?.optionsData?[index].value;
                                          }
                                        }
                                      });
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: isTapped ? showColorBorder : ThemeManager.grey1,
                                                width: 0.84),
                                            borderRadius: BorderRadius.circular(33.44),
                                            color: isTapped ? showColor.withOpacity(0.1) : ThemeManager.white,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: Dimensions.PADDING_SIZE_LARGE,
                                              vertical: Dimensions.PADDING_SIZE_SMALL * 1.3,
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Column(
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          "${testExamPaper?.optionsData?[index].value ?? ""}.  ",
                                                          style: TextStyle(
                                                            fontSize: Dimensions.fontSizeLarge,
                                                            fontWeight: FontWeight.w400,
                                                            color: showColor2,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: MediaQuery.of(context).size.width * 0.6,
                                                          child: Text(
                                                            testExamPaper?.optionsData?[index].answerTitle ??
                                                                "",
                                                            style: TextStyle(
                                                              fontSize: Dimensions.fontSizeLarge,
                                                              fontWeight: FontWeight.w400,
                                                              color: showColor2,
                                                            ),
                                                          ),
                                                        ),
                                                        if ((isTapped == true &&
                                                            widget.isPracticeExam == true))
                                                          Text(
                                                              "[${testExamPaper?.optionsData?[index].percentage ?? 0}%]")
                                                      ],
                                                    ),
                                                    testExamPaper?.optionsData?[index].answerImg != ""
                                                        ? InteractiveViewer(
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
                                                          )
                                                        : const SizedBox(),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if ((testExamPaper?.correctOption ?? "") ==
                                                (testExamPaper?.optionsData?[index].value ?? "") &&
                                            (isTapped == true && widget.isPracticeExam == true))
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                                            child: Text(
                                              "${correctPercentage ?? "0"}% Got this answer correct",
                                              style: TextStyle(
                                                fontSize: Dimensions.fontSizeSmall,
                                                color: ThemeManager.greenSuccess,
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
                            (isTapped == true && widget.isPracticeExam == true)
                                ? Observer(
                                    builder: (BuildContext context) {
                                      GetNotesSolutionModel? noteModel = store.notesData.value;
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(
                                            height: Dimensions.PADDING_SIZE_DEFAULT,
                                          ),
                                          //Solution Explanation
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
                                              //     _showNotesDialog(context, widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "", noteModel?.notes??"");
                                              //   },
                                              //   child: SvgPicture.asset("assets/image/penIcon.svg"),
                                              // ),
                                              //       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,onPressed: (){
                                              //   _showNotesDialog(context, widget.testExamPaper?.test?[_currentQuestionIndex].sId ?? "", noteModel?.notes??"");
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
                                              //         widget
                                              //                 .testExamPaper
                                              //                 ?.test?[
                                              //                     _currentQuestionIndex]
                                              //                 .sId ??
                                              //             "",
                                              //         noteModel?.notes ?? "");
                                              //   },
                                              //   child: Container(
                                              //     padding: const EdgeInsets
                                              //         .symmetric(
                                              //         horizontal: 17,
                                              //         vertical: 6),
                                              //     decoration: BoxDecoration(
                                              //         color: ThemeManager
                                              //             .whiteTrans,
                                              //         borderRadius:
                                              //             BorderRadius.circular(
                                              //                 18.71),
                                              //         border: Border.all(
                                              //             color: ThemeManager
                                              //                 .blueFinal)),
                                              //     child: Text(
                                              //       "Stick Notes",
                                              //       style: interBlack.copyWith(
                                              //         fontSize: Dimensions
                                              //             .fontSizeSmall,
                                              //         fontWeight:
                                              //             FontWeight.w400,
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
                                                      widget.testExamPaper?.test?[_currentQuestionIndex]
                                                              .sId ??
                                                          "",
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

                                          explanationWidget ?? const SizedBox(),
                                          const SizedBox(
                                            height: Dimensions.PADDING_SIZE_DEFAULT,
                                          ),

                                          isbutton == true
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
                                                          borderRadius: BorderRadius.circular(
                                                              Dimensions.RADIUS_DEFAULT)),
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
                                : const SizedBox()
                          ],
                        ),
                      ),
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
                          InkWell(
                            onTap: isprocess == true ? null : (firstQue ? null : _showPreviousQuestion),
                            child: Container(
                              height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.14,
                              width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.14,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: firstQue
                                        ? ThemeManager.nextButtonBorder
                                        : ThemeManager.previousNextPrimary,
                                  )),
                              child: SvgPicture.asset(
                                "assets/image/arrow_back.svg",
                                color: firstQue
                                    ? ThemeManager.nextButtonBorder
                                    : ThemeManager.previousNextPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: Dimensions.PADDING_SIZE_DEFAULT * 1.1,
                          ),
                          InkWell(
                            onTap: isprocess == true ? null : _showNextQuestion,
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
              ),
            ],
          ),
          drawer: Drawer(
            backgroundColor: Colors.white,
            child: QuestionMasterPallet(widget.testExamPaper, widget.userExamId, null, widget.isPracticeExam),
          )),
    );
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
    //                   addNotes(widget.testExamPaper?.test?[_currentQuestionIndex].sId,notes);
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
