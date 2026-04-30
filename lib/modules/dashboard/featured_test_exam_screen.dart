import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shusruta_lms/services/smart_resume_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:vibration/vibration.dart';
import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/featured_list_model.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_test_cancel_dialogbox.dart';
import 'featured_question_pallet.dart';

class FeaturedTestExamPage extends StatefulWidget {
  final TestsPaper? featuredTestExamPaper;
  final String? userExamId;
  final int? queNo;
  final ValueNotifier<Duration>? remainingTime;
  final bool? fromPallete;

  const FeaturedTestExamPage(
      {super.key,
      this.fromPallete,
      this.featuredTestExamPaper,
      this.userExamId,
      this.queNo,
      this.remainingTime});

  @override
  State<FeaturedTestExamPage> createState() => _FeaturedTestExamPageState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => FeaturedTestExamPage(
        featuredTestExamPaper: arguments['featuredTestData'],
        userExamId: arguments['userexamId'],
        queNo: arguments['queNo'],
        remainingTime: arguments['remainingTime'],
        fromPallete: arguments['fromPallete'],
      ),
    );
  }
}

class _FeaturedTestExamPageState extends State<FeaturedTestExamPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? timer;
  Duration? remainingTime;
  int _selectedIndex = -1;
  late ValueNotifier<Duration> remainingTimeNotifier;
  int _currentQuestionIndex = 0;
  bool isLastQues = false, firstQue = true;
  bool isAttempted = false;
  bool isMarkedForReview = false;
  bool isGuess = false;
  bool isAttemptedAndMarkedForReview = false;
  bool isSkipped = false;

  Uint8List? answerImgBytes;
  Uint8List? quesImgBytes;
  Duration? duration;
  String? usedExamTime;
  Widget? questionWidget;
  final ScrollController scrollController = ScrollController();
  @override
  void initState() {
    super.initState();

    updateTimer();

    int matchingIndex = widget.featuredTestExamPaper?.questions
            ?.indexWhere((e) => e.questionNumber == widget.queNo) ??
        -1;
    if (matchingIndex != -1) {
      String? matchingQueId =
          widget.featuredTestExamPaper?.questions?[matchingIndex].sId;
      _getSelectedAnswer(matchingQueId!);
      _currentQuestionIndex = matchingIndex;
      setState(() {
        firstQue = false;
      });
      if (_currentQuestionIndex >=
          (widget.featuredTestExamPaper?.questions?.length ?? 0) - 1) {
        isLastQues = true;
      } else {
        isLastQues = false;
      }
    }

    // Smart Resume hook — push this in-progress featured/mock test
    // into SmartResumeService so the home banner can offer a 1-tap
    // resume.
    final userExamId = widget.userExamId ?? '';
    final examName = widget.featuredTestExamPaper?.examName ?? 'Mock test';
    final totalQs = widget.featuredTestExamPaper?.questions?.length ?? 0;
    if (userExamId.isNotEmpty) {
      // ignore: discarded_futures
      SmartResumeService.instance.recordMockExam(
        userExamId: userExamId,
        examName: examName,
        currentQuestion: _currentQuestionIndex + 1,
        totalQuestions: totalQs,
        remainingSeconds: remainingTimeNotifier.value.inSeconds,
        examId: widget.featuredTestExamPaper?.sid,
      );
    }
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      updateTimer();
      debugPrint("app is resumed");
      debugPrint("remaining time bg${remainingTimeNotifier.value}");
      debugPrint("timer bg$timer");
    } else if (state == AppLifecycleState.paused) {
      debugPrint("app is paused");
      debugPrint("remaining time bg${remainingTimeNotifier.value}");
      debugPrint("timer bg$timer");
    }
  }

  void updateTimer() {
    if (widget.featuredTestExamPaper?.timeDuration != null &&
        widget.fromPallete != true) {
      List<String>? timeParts =
          widget.featuredTestExamPaper?.timeDuration?.split(":");
      duration = Duration(
        hours: int.parse(timeParts![0]),
        minutes: int.parse(timeParts[1]),
        seconds: int.parse(timeParts[2]),
      );
      remainingTime = duration;
      remainingTimeNotifier = ValueNotifier<Duration>(remainingTime!);
    } else {
      List<String>? timeParts =
          widget.featuredTestExamPaper?.timeDuration?.split(":");
      duration = Duration(
        hours: int.parse(timeParts![0]),
        minutes: int.parse(timeParts[1]),
        seconds: int.parse(timeParts[2]),
      );
      remainingTime = widget.remainingTime?.value;
      remainingTimeNotifier = ValueNotifier<Duration>(remainingTime!);
    }

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTimeNotifier.value.inSeconds > 0) {
        remainingTimeNotifier.value =
            remainingTimeNotifier.value - const Duration(seconds: 1);
      } else {
        timer.cancel();
        remainingTimeNotifier.dispose();
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: "Your Exam Time is Up!",
          backgroundColor: Theme.of(context).primaryColor,
        );
        _getCount2(widget.userExamId);
        // Navigator.of(context).pushNamed(Routes.reportsCategoryList,
        //     arguments: {
        //       'fromhome':true
        //     });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    remainingTimeNotifier.dispose();
    super.dispose();
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
    await store.userAnswerTest(
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
    await store.questionAnswerById(widget.userExamId ?? "", queId);
    setState(() {
      String? nextOption =
          (store.userAnswerExam.value?.guess?.isNotEmpty ?? false)
              ? store.userAnswerExam.value?.guess
              : store.userAnswerExam.value?.selectedOption;
      _selectedIndex = widget.featuredTestExamPaper
              ?.questions?[_currentQuestionIndex].optionsData
              ?.indexWhere((option) => option.value == nextOption) ??
          -1;
      isGuess = (store.userAnswerExam.value?.guess?.isNotEmpty ?? false)
          ? true
          : false;
      isMarkedForReview = store.userAnswerExam.value?.markedForReview ?? false;
      isAttemptedAndMarkedForReview =
          store.userAnswerExam.value?.attemptedMarkedForReview ?? false;
    });
  }

  Future<void> _getCount(String? userExamId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.getQuestionPalleteCount(userExamId ?? "").then((_) {
      openBottomSheet(store);
    });
  }

  Future<void> _getCount2(String? userExamId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.getQuestionPalleteCount(userExamId ?? "").then((_) {
      openBottomSheet2(store);
    });
  }

  Future<void> _generateReport(String? userExamId) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onReportExamApiCall(widget.userExamId ?? "").then((_) {
      Navigator.of(context).pushNamed(Routes.testReportScreen, arguments: {
        'report': store.reportsExam.value,
        'title': widget.featuredTestExamPaper?.examName,
        'examId': userExamId
      });
    });
  }

  void openBottomSheet(TestCategoryStore store) {
    showModalBottomSheet<void>(
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      context: context,
      builder: (BuildContext context) {
        String attempted = "0",
            markedForReview = "0",
            skipped = "0",
            attemptedandMarkedForReview = "0",
            guess = "0",
            notVisited = "0";
        attempted = store.testQuePalleteCount.value?.isAttempted
                .toString()
                .padLeft(2, '0') ??
            "0";
        markedForReview = store.testQuePalleteCount.value?.isMarkedForReview
                .toString()
                .padLeft(2, '0') ??
            "0";
        skipped = store.testQuePalleteCount.value?.isSkipped
                .toString()
                .padLeft(2, '0') ??
            "0";
        attemptedandMarkedForReview = store
                .testQuePalleteCount.value?.isAttemptedMarkedForReview
                .toString()
                .padLeft(2, '0') ??
            "0";
        notVisited = store.testQuePalleteCount.value?.notVisited
                .toString()
                .padLeft(2, '0') ??
            "0";
        guess = store.testQuePalleteCount.value?.isGuess
                .toString()
                .padLeft(2, '0') ??
            "0";
        return Container(
          // height: MediaQuery.of(context).size.height * 0.50,
          color: ThemeManager.reportContainer,
          child: Padding(
            padding: const EdgeInsets.only(
                top: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                bottom: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                left: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                right: Dimensions.PADDING_SIZE_EXTRA_LARGE),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Test Submission",
                  style: interSemiBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    fontWeight: FontWeight.w600,
                    color: ThemeManager.black,
                  ),
                ),
                const SizedBox(
                  height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                ),
                Expanded(
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Time Left",
                                  style: interSemiBold.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                Text(
                                  "${remainingTimeNotifier.value.inHours.toString().padLeft(2, '0')}:${remainingTimeNotifier.value.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTimeNotifier.value.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                                  style: interSemiBold.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w600,
                                    color: ThemeManager.greenSuccess,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: Dimensions.PADDING_SIZE_DEFAULT,
                            ),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 5.0,
                                  backgroundColor: Colors.green,
                                ),
                                const SizedBox(
                                  width: Dimensions.PADDING_SIZE_SMALL,
                                ),
                                Text(
                                  "Attempted",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  attempted,
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(
                              height: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                            ),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 5.0,
                                  backgroundColor: Colors.blue,
                                ),
                                const SizedBox(
                                  width: Dimensions.PADDING_SIZE_SMALL,
                                ),
                                Text(
                                  "Marked for Review",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  markedForReview,
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 5.0,
                                  backgroundColor: Colors.orange,
                                ),
                                const SizedBox(
                                  width: Dimensions.PADDING_SIZE_SMALL,
                                ),
                                Text(
                                  "Attempted and Marked for Review",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  attemptedandMarkedForReview,
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 5.0,
                                  backgroundColor: Colors.red,
                                ),
                                const SizedBox(
                                  width: Dimensions.PADDING_SIZE_SMALL,
                                ),
                                Text(
                                  "Skipped",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  skipped,
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 5.0,
                                  backgroundColor: Colors.brown,
                                ),
                                const SizedBox(
                                  width: Dimensions.PADDING_SIZE_SMALL,
                                ),
                                Text(
                                  "Guess",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  guess,
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 5.0,
                                  backgroundColor: ThemeManager.lightBlue,
                                ),
                                const SizedBox(
                                  width: Dimensions.PADDING_SIZE_SMALL,
                                ),
                                Text(
                                  "Not Visited",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  notVisited,
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_LARGE * 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: Dimensions.PADDING_SIZE_DEFAULT * 2,
                      right: Dimensions.PADDING_SIZE_LARGE * 2),
                  child: Text(
                    "Are you sure you want to submit the test?",
                    style: interSemiBold.copyWith(
                      fontSize: Dimensions.fontSizeExtraLarge,
                      fontWeight: FontWeight.w600,
                      color: ThemeManager.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // const Spacer(),
                const SizedBox(
                  height: Dimensions.PADDING_SIZE_SMALL,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: MediaQuery.of(context).size.height * 0.055,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: ThemeManager.btnGrey),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            "Resume",
                            style: TextStyle(
                              fontSize: Dimensions.fontSizeDefault,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          )),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: MediaQuery.of(context).size.height * 0.055,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: Theme.of(context).primaryColor),
                          onPressed: () async {
                            if (await Vibration.hasVibrator() ?? false) {
                              Vibration.vibrate();
                            }
                            timer?.cancel();
                            _generateReport(widget.userExamId);
                          },
                          child: Text(
                            "Submit",
                            style: TextStyle(
                              fontSize: Dimensions.fontSizeDefault,
                              fontWeight: FontWeight.w400,
                              color: ThemeManager.currentTheme == AppTheme.Dark
                                  ? ThemeManager.white
                                  : Colors.white,
                            ),
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void openBottomSheet2(TestCategoryStore store) {
    showModalBottomSheet<void>(
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      context: context,
      builder: (BuildContext context) {
        String attempted = "0",
            markedForReview = "0",
            skipped = "0",
            attemptedandMarkedForReview = "0",
            guess = "0",
            notVisited = "0";
        attempted = store.testQuePalleteCount.value?.isAttempted
                .toString()
                .padLeft(2, '0') ??
            "0";
        markedForReview = store.testQuePalleteCount.value?.isMarkedForReview
                .toString()
                .padLeft(2, '0') ??
            "0";
        skipped = store.testQuePalleteCount.value?.isSkipped
                .toString()
                .padLeft(2, '0') ??
            "0";
        attemptedandMarkedForReview = store
                .testQuePalleteCount.value?.isAttemptedMarkedForReview
                .toString()
                .padLeft(2, '0') ??
            "0";
        notVisited = store.testQuePalleteCount.value?.notVisited
                .toString()
                .padLeft(2, '0') ??
            "0";
        guess = store.testQuePalleteCount.value?.isGuess
                .toString()
                .padLeft(2, '0') ??
            "0";
        return Container(
          // height: MediaQuery.of(context).size.height * 0.50,
          color: ThemeManager.reportContainer,
          child: Padding(
            padding: const EdgeInsets.only(
                top: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                bottom: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                left: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                right: Dimensions.PADDING_SIZE_EXTRA_LARGE),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Test Submission",
                  style: interSemiBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    fontWeight: FontWeight.w600,
                    color: ThemeManager.black,
                  ),
                ),
                const SizedBox(
                  height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                ),
                Expanded(
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //   children: [
                            //     Text("Time Left",
                            //       style: interSemiBold.copyWith(
                            //         fontSize: Dimensions.fontSizeSmall,
                            //         fontWeight: FontWeight.w500,
                            //         color: Theme.of(context).hintColor,
                            //       ),),
                            //     Text("${remainingTimeNotifier.value!.inHours.toString().padLeft(2, '0')}:${remainingTimeNotifier.value!.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTimeNotifier.value!.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                            //       style: interSemiBold.copyWith(
                            //         fontSize: Dimensions.fontSizeSmall,
                            //         fontWeight: FontWeight.w600,
                            //         color: ThemeManager.greenSuccess,
                            //       ),),
                            //   ],
                            // ),
                            // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 5.0,
                                  backgroundColor: Colors.green,
                                ),
                                const SizedBox(
                                  width: Dimensions.PADDING_SIZE_SMALL,
                                ),
                                Text(
                                  "Attempted",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  attempted,
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(
                              height: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                            ),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 5.0,
                                  backgroundColor: Colors.blue,
                                ),
                                const SizedBox(
                                  width: Dimensions.PADDING_SIZE_SMALL,
                                ),
                                Text(
                                  "Marked for Review",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  markedForReview,
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 5.0,
                                  backgroundColor: Colors.orange,
                                ),
                                const SizedBox(
                                  width: Dimensions.PADDING_SIZE_SMALL,
                                ),
                                Text(
                                  "Attempted and Marked for Review",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  attemptedandMarkedForReview,
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 5.0,
                                  backgroundColor: Colors.red,
                                ),
                                const SizedBox(
                                  width: Dimensions.PADDING_SIZE_SMALL,
                                ),
                                Text(
                                  "Skipped",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  skipped,
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 5.0,
                                  backgroundColor: Colors.brown,
                                ),
                                const SizedBox(
                                  width: Dimensions.PADDING_SIZE_SMALL,
                                ),
                                Text(
                                  "Guess",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  guess,
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 5.0,
                                  backgroundColor: ThemeManager.lightBlue,
                                ),
                                const SizedBox(
                                  width: Dimensions.PADDING_SIZE_SMALL,
                                ),
                                Text(
                                  "Not Visited",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  notVisited,
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).hintColor,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_LARGE * 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.only(left: Dimensions.PADDING_SIZE_DEFAULT * 2,
                //       right: Dimensions.PADDING_SIZE_LARGE * 2),
                //   child: Text("Are you sure you want to submit the test?",
                //     style: interSemiBold.copyWith(
                //       fontSize: Dimensions.fontSizeExtraLarge,
                //       fontWeight: FontWeight.w600,
                //       color: ThemeManager.black,
                //     ),
                //     textAlign: TextAlign.center,),
                // ),
                // // const Spacer(),
                // const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
                Row(
                  children: [
                    // SizedBox(
                    //   width: MediaQuery.of(context).size.width * 0.4,
                    //   height: MediaQuery.of(context).size.height * 0.055,
                    //   child: ElevatedButton(
                    //       style: ElevatedButton.styleFrom(
                    //           shape: RoundedRectangleBorder(
                    //             borderRadius: BorderRadius.circular(8),
                    //           ),
                    //           backgroundColor: ThemeManager.btnGrey
                    //       ),
                    //       onPressed: (){
                    //         Navigator.of(context).pop();
                    //       },
                    //       child: Text("Resume",
                    //         style: TextStyle(
                    //           fontSize: Dimensions.fontSizeDefault,
                    //           fontWeight: FontWeight.w400,
                    //           color: Colors.white,
                    //         ),)),
                    // ),
                    // const Spacer(),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: MediaQuery.of(context).size.height * 0.055,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: Theme.of(context).primaryColor),
                          onPressed: () {
                            timer?.cancel();
                            _generateReport(widget.userExamId);
                          },
                          child: Text(
                            "Submit",
                            style: TextStyle(
                              fontSize: Dimensions.fontSizeDefault,
                              fontWeight: FontWeight.w400,
                              color: ThemeManager.currentTheme == AppTheme.Dark
                                  ? ThemeManager.white
                                  : Colors.white,
                            ),
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showNextQuestion() async {
    firstQue = false;
    String? questionId =
        widget.featuredTestExamPaper?.questions?[_currentQuestionIndex].sId;

    String? selectedOption = _selectedIndex == -1
        ? ""
        : widget.featuredTestExamPaper?.questions?[_currentQuestionIndex]
            .optionsData?[_selectedIndex].value;
    if (selectedOption == "" && !isMarkedForReview) {
      isSkipped = true;
      isAttempted = false;
      isAttemptedAndMarkedForReview = false;
      isMarkedForReview = false;
      isGuess = false;
    } else if (selectedOption != "" && isAttemptedAndMarkedForReview) {
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
    } else if (selectedOption != "" && isGuess) {
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
    }

    // String time = "${remainingTime!.inHours.toString().padLeft(2, '0')}:${remainingTime!.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingTime!.inSeconds.remainder(60).toString().padLeft(2, '0')}";
    if (duration != null) {
      Duration timeDifference = duration! - remainingTimeNotifier.value;
      usedExamTime =
          "${timeDifference.inHours.toString().padLeft(2, '0')}:${timeDifference.inMinutes.remainder(60).toString().padLeft(2, '0')}:${timeDifference.inSeconds.remainder(60).toString().padLeft(2, '0')}";
      debugPrint('usedtime $usedExamTime');
    } else {
      debugPrint('Duration values are null.');
    }
    if (isGuess == true) {
      await _postSelectedAnswerApiCall(
          widget.userExamId,
          "",
          questionId,
          isAttempted,
          isAttemptedAndMarkedForReview,
          isSkipped,
          isMarkedForReview,
          selectedOption!,
          usedExamTime ?? "00:00:00");
    } else {
      await _postSelectedAnswerApiCall(
          widget.userExamId,
          selectedOption,
          questionId,
          isAttempted,
          isAttemptedAndMarkedForReview,
          isSkipped,
          isMarkedForReview,
          "",
          usedExamTime ?? "00:00:00");
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
      if (_currentQuestionIndex >=
          (widget.featuredTestExamPaper?.questions?.length ?? 0) - 1) {
        isLastQues = true;
        _currentQuestionIndex =
            (widget.featuredTestExamPaper?.questions?.length ?? 0) - 1;
      } else {
        isLastQues = false;
      }

      String? questionId1 =
          widget.featuredTestExamPaper?.questions?[_currentQuestionIndex].sId;
      _getSelectedAnswer(questionId1 ?? "");

      questionWidget = getQuestionText(context);
    });

    // String base64String = widget.featuredTestExamPaper?.questions?[_currentQuestionIndex].questionImg?[0] ?? "";
    // try {
    //   quesImgBytes = base64Decode(base64String);
    // } catch (e) {
    //   print("Error decoding base64 string: $e");
    // }
  }

  void _showPreviousQuestion() {
    setState(() {
      _selectedIndex = -1;
      isLastQues = false;
      if (widget.featuredTestExamPaper?.questions?.length == 1) {
        _currentQuestionIndex = 0;
        firstQue = true;
      } else if (_currentQuestionIndex > 0) {
        _currentQuestionIndex--;
      } else {
        firstQue = true;
      }
      String? questionId =
          widget.featuredTestExamPaper?.questions?[_currentQuestionIndex].sId;
      _getSelectedAnswer(questionId ?? "");

      questionWidget = getQuestionText(context);
    });
  }

  Widget getQuestionText(BuildContext context) {
    if (widget.featuredTestExamPaper?.questions == null ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >=
            (widget.featuredTestExamPaper?.questions?.length ?? 0)) {
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

    String questionTxt = widget.featuredTestExamPaper
            ?.questions?[_currentQuestionIndex].questionText ??
        "";
    questionTxt = questionTxt.replaceAllMapped(
        RegExp(r'----(.*?)----', multiLine: true), (match) => 'splittedImage');
    List<String> splittedText = questionTxt.split("splittedImage");
    List<Widget> columns = [];
    int index = 0;
    for (String text in splittedText) {
      List<Widget> questionImageWidget = [];
      if (widget.featuredTestExamPaper?.questions?[_currentQuestionIndex]
              .questionImg?.isNotEmpty ??
          false) {
        for (String base64String in widget.featuredTestExamPaper!
            .questions![_currentQuestionIndex].questionImg!) {
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
                            // width: MediaQuery.of(context).size.width * 0.9,
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
                .replaceAll(RegExp(r'\n{2,}'), '\n')
                .trim()
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
      if (index >=
          (widget.featuredTestExamPaper?.questions?[_currentQuestionIndex]
                      .questionImg?.length ??
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

  Future<bool> _onBackPressed() async {
    if (_currentQuestionIndex > 0) {
      _showPreviousQuestion();
      return false;
    } else {
      bool confirmExit = await showDialog(
        context: context,
        builder: (context) =>
            CustomTestCancelDialogBox(timer, remainingTimeNotifier, false),
      );
      return confirmExit ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    questionWidget = getQuestionText(context);

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppTokens.scaffold(context),
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: AppTokens.scaffold(context),
            title: Text(
              widget.featuredTestExamPaper?.examName ?? "Test",
              style: AppTokens.titleLg(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                tooltip: 'Cancel test',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => CustomTestCancelDialogBox(
                        timer, remainingTimeNotifier, false),
                  );
                },
                icon: Icon(Icons.close_rounded,
                    color: AppTokens.ink(context), size: 22),
              ),
              IconButton(
                tooltip: 'Question palette',
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                icon: Icon(Icons.grid_view_rounded,
                    color: AppTokens.ink(context), size: 20),
              ),
              const SizedBox(width: AppTokens.s8),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_EXTRA_LARGE),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s12, vertical: 6),
                      decoration: BoxDecoration(
                          color: AppTokens.accentSoft(context),
                          borderRadius: AppTokens.radius20),
                      child: Text(
                        "Q ${_currentQuestionIndex + 1}",
                        style: AppTokens.titleSm(context).copyWith(
                          color: AppTokens.accent(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Text(
                      "of ${widget.featuredTestExamPaper?.questions?.length.toString().padLeft(2, '0') ?? 0}",
                      style: AppTokens.caption(context),
                    ),
                    const Spacer(),
                    ValueListenableBuilder<Duration>(
                      valueListenable: remainingTimeNotifier,
                      builder: (context, remainingTime, child) {
                        final hours = remainingTime.inHours
                            .toString()
                            .padLeft(2, '0');
                        final mins = remainingTime.inMinutes
                            .remainder(60)
                            .toString()
                            .padLeft(2, '0');
                        final secs = remainingTime.inSeconds
                            .remainder(60)
                            .toString()
                            .padLeft(2, '0');
                        // Switch to warning color when less than 5 min left.
                        final warning = remainingTime.inMinutes < 5;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.s12, vertical: 6),
                          decoration: BoxDecoration(
                            color: warning
                                ? AppTokens.dangerSoft(context)
                                : AppTokens.successSoft(context),
                            borderRadius: AppTokens.radius20,
                          ),
                          child: Text(
                            "$hours:$mins:$secs",
                            style: AppTokens.numeric(context, size: 14)
                                .copyWith(
                              color: warning
                                  ? AppTokens.danger(context)
                                  : AppTokens.success(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(
                  height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text(widget.featuredTestExamPaper?.questions?[_currentQuestionIndex].questionText??"",
                        //   style: interRegular.copyWith(
                        //     fontSize: Dimensions.fontSizeDefault,
                        //     fontWeight: FontWeight.w400,
                        //     color: ThemeManager.black,
                        //   ),),
                        // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
                        //
                        // widget.featuredTestExamPaper?.questions?[_currentQuestionIndex].questionImg?[0]!=""?
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

                        questionWidget ?? const SizedBox(),

                        const SizedBox(
                          height: Dimensions.PADDING_SIZE_DEFAULT,
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: widget
                              .featuredTestExamPaper
                              ?.questions?[_currentQuestionIndex]
                              .optionsData
                              ?.length,
                          itemBuilder: (BuildContext context, int index) {
                            FeaturedTestData? testExamPaper = widget
                                .featuredTestExamPaper
                                ?.questions?[_currentQuestionIndex];
                            String base64String =
                                testExamPaper?.optionsData?[index].answerImg ??
                                    "";
                            try {
                              // answerImgBytes = base64Decode(base64String);
                            } catch (e) {
                              debugPrint("Error decoding base64 string: $e");
                            }
                            bool isSelected = index == _selectedIndex;
                            return Padding(
                              padding: const EdgeInsets.only(
                                  top: Dimensions.PADDING_SIZE_DEFAULT),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedIndex = -1;
                                      isAttemptedAndMarkedForReview = false;
                                      isMarkedForReview = false;
                                      isGuess = false;
                                    } else {
                                      _selectedIndex = index;
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: isSelected
                                              ? Colors.green
                                              : ThemeManager.borderBlue),
                                      borderRadius: BorderRadius.circular(
                                          Dimensions.RADIUS_DEFAULT)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        Dimensions.PADDING_SIZE_SMALL),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height:
                                              Dimensions.PADDING_SIZE_DEFAULT *
                                                  2,
                                          width:
                                              Dimensions.PADDING_SIZE_DEFAULT *
                                                  2,
                                          decoration: BoxDecoration(
                                              color: ThemeManager.borderBlue,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Dimensions.RADIUS_LARGE)),
                                          child: Center(
                                            child: Text(
                                              testExamPaper?.optionsData?[index]
                                                      .value ??
                                                  "",
                                              style: interRegular.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeDefault,
                                                fontWeight: FontWeight.w400,
                                                color: ThemeManager.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width:
                                              Dimensions.PADDING_SIZE_DEFAULT,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.6,
                                              child: Html(
                                                data: '''
                                                    <div style="color: ${ThemeManager.currentTheme == AppTheme.Dark ? 'white' : 'black'};">
                                                    ${testExamPaper?.optionsData?[index].answerTitle ?? ""}
                                                    </div>
                                                    ''',
                                                // data: testExamPaper?.optionsData?[index].answerTitle??"",
                                                // style: TextStyle(
                                                //   fontSize: Dimensions.fontSizeDefault,
                                                //   fontWeight: FontWeight.w400,
                                                //   color: ThemeManager.black,
                                                // ),
                                              ),
                                            ),
                                            testExamPaper?.optionsData?[index]
                                                        .answerImg !=
                                                    ""
                                                ? Row(
                                                    children: [
                                                      InteractiveViewer(
                                                        minScale: 1.0,
                                                        maxScale: 3.0,
                                                        child: Center(
                                                          child: SizedBox(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.6,
                                                            height: 250,
                                                            child: Stack(
                                                              children: [
                                                                // if (answerImgBytes != null)
                                                                //   Image.memory(answerImgBytes!),
                                                                if (base64String !=
                                                                    '')
                                                                  Image.network(
                                                                      base64String),
                                                                Container(
                                                                    color: Colors
                                                                        .transparent),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : const SizedBox(),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: Dimensions.PADDING_SIZE_DEFAULT,
                ),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor:
                                    Theme.of(context).primaryColor),
                            onPressed: firstQue ? null : _showPreviousQuestion,
                            child: Text(
                              "Previous",
                              style: TextStyle(
                                fontSize: Dimensions.fontSizeDefault,
                                fontWeight: FontWeight.w400,
                                color: firstQue
                                    ? ThemeManager.black
                                    : ThemeManager.home1,
                              ),
                            )),
                      ),
                    ),
                    const SizedBox(
                      width: Dimensions.PADDING_SIZE_DEFAULT,
                    ),
                    Expanded(
                      child: SizedBox(
                        height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor:
                                    Theme.of(context).primaryColor),
                            onPressed: _showNextQuestion,
                            child: isLastQues == true
                                ? Text(
                                    "Submit",
                                    style: TextStyle(
                                      fontSize: Dimensions.fontSizeDefault,
                                      fontWeight: FontWeight.w400,
                                      color: ThemeManager.home1,
                                    ),
                                  )
                                : Text(
                                    "Next",
                                    style: TextStyle(
                                      fontSize: Dimensions.fontSizeDefault,
                                      fontWeight: FontWeight.w400,
                                      color: ThemeManager.home1,
                                    ),
                                  )),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: Dimensions.PADDING_SIZE_DEFAULT,
                ),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        onPressed: () {
                          setState(() {
                            isGuess = false;
                            if (_selectedIndex != -1) {
                              isAttemptedAndMarkedForReview =
                                  !isAttemptedAndMarkedForReview;
                            } else {
                              isMarkedForReview = !isMarkedForReview;
                            }
                          });
                          // isMarkedForReview=true;
                          // _showNextQuestion();
                          // Navigator.of(context).pushNamed(Routes.questionPallet);
                        },
                        buttonText: "Mark for review",
                        height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                        textAlign: TextAlign.center,
                        radius: Dimensions.RADIUS_DEFAULT,
                        transparent: true,
                        bgColor: (isMarkedForReview
                            ? Colors.blue
                            : (isAttemptedAndMarkedForReview
                                ? Colors.orangeAccent
                                : Theme.of(context).primaryColor)),
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                    ),
                    const SizedBox(
                      width: Dimensions.PADDING_SIZE_DEFAULT,
                    ),
                    Expanded(
                      child: CustomButton(
                        onPressed: () {
                          if (_selectedIndex != -1) {
                            setState(() {
                              isGuess = !isGuess;
                              isAttemptedAndMarkedForReview = false;
                              isMarkedForReview = false;
                            });
                            debugPrint("isGuess:$isGuess");
                            // _showNextQuestion();
                            // Navigator.of(context).pushNamed(Routes.questionPallet);
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('Please Select Option'),
                            ));
                          }
                        },
                        buttonText: "Guess",
                        height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                        textAlign: TextAlign.center,
                        radius: Dimensions.RADIUS_DEFAULT,
                        transparent: true,
                        bgColor: isGuess == true
                            ? Colors.brown
                            : Theme.of(context).primaryColor,
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          drawer: Drawer(
            backgroundColor: Colors.white,
            child: FeaturedQuestionPallet(widget.featuredTestExamPaper,
                widget.userExamId, remainingTimeNotifier),
          )),
    );
  }
}
