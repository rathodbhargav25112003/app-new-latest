// ignore_for_file: deprecated_member_use, avoid_print, library_private_types_in_public_api, dead_null_aware_expression, use_build_context_synchronously

import 'dart:io';
import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/login/store/verify_otp_phone.dart';
import 'package:shusruta_lms/modules/masterTest/custom_master_test_dialogbox.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/store/new_bookmark_store.dart';
import 'package:shusruta_lms/modules/new_exam_component/exam_pallet.dart';
import 'package:shusruta_lms/modules/new_exam_component/exam_timer.dart';
import 'package:shusruta_lms/modules/new_exam_component/model/exam_ans_model.dart';
import 'package:shusruta_lms/modules/new_exam_component/store/exam_store.dart';
import 'package:shusruta_lms/modules/new_exam_component/widget/checkbox_widget.dart';
import 'package:shusruta_lms/modules/new_exam_component/widget/custome_exam_button.dart';
import 'package:shusruta_lms/modules/new_exam_component/widget/question_widget.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/widgets/custom_test_cancel_dialogbox.dart';

/// The exam-taking screen — the single most important interactive
/// screen in the whole app. Renders the current MCQ, the options, the
/// countdown timer, the question palette (side drawer on mobile or a
/// fixed 22%-width sidebar on desktop when width > 1160 && height >
/// 690) and the "Review / Submit" bottom sheet.
///
/// Preserved public contract (byte-for-byte):
///   • Constructor: `ExamScreen({super.key, this.testExamPaper, this.id,
///     this.userExamId, this.timeDuration, this.name, this.showPredictive,
///     this.isTrend, this.mainId, this.type, this.isAll = false})`
///   • All fields kept with the same nullability.
///   • State methods `init`, `saveAns(bool isAdd, bool isNext)`,
///     `_onBackPressed`, `openBottomSheet(ExamStore store)` keep the
///     same signatures.
///   • Every MobX store call (`onTestApiCall`, `changeType`, `onChange`,
///     `onAns`, `onAnsSave`, `disposeStore`, `onOptionSelect`,
///     `changeMarkReview`, `changeGuess`, `startTimer`, the observables
///     `isSubmit`, `currentQuestionIndex`, `question`, `selectedOptionIndex`,
///     `ansList`, `isMarkedForReview`, `isGuess`, `questionList`,
///     `tracker`, `isLoading`) is preserved.
///   • `countdownTimer` lifecycle: `.start(...)`, `.stop()`,
///     `.timeNotifier.dispose()`, `.getCurrentTime()`, `.remainingTime`
///     are preserved.
///   • Platform split in `openBottomSheet` (Windows/macOS use
///     `showDialog(AlertDialog)`, others use `showModalBottomSheet`).
///   • Navigator route `Routes.allSelectTestList` called with the same
///     6-key argument map: `id`, `type: "topic"`, `showPredictive: true`,
///     `testExamPaperListModel`, `count: (remainingAttempts ?? 0) - 1`,
///     `isTrend`.
///   • Top-level public helper `listTile(String title, String value,
///     Color color)` retained.
class ExamScreen extends StatefulWidget {
  const ExamScreen({
    super.key,
    this.testExamPaper,
    this.id,
    this.userExamId,
    this.timeDuration,
    this.name,
    this.showPredictive,
    this.isTrend,
    this.mainId,
    this.type,
    this.isAll = false,
  });

  final TestExamPaperListModel? testExamPaper;
  final String? id;
  final String? userExamId;
  final String? timeDuration;
  final String? name;
  final bool? showPredictive;
  final bool? isTrend;
  final bool? isAll;
  final String? type;
  final String? mainId;

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late ExamStore store;
  Timer? timer;
  Duration? remainingTime;
  Duration? duration;
  String? usedExamTime;
  String? pre;
  late CountdownTimer countdownTimer;
  final ScrollController scrollController = ScrollController();
  late ReactionDisposer disposer;
  late ReactionDisposer disposer2;
  late ReactionDisposer disposer3;

  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init() async {
    countdownTimer = CountdownTimer(widget.timeDuration ??
        widget.testExamPaper!.timeDuration ??
        "00:00:00");
    countdownTimer.start(() {
      if (!store.isSubmit.value) {
        showLoadingDialog(context);
        store.onAnsSave(context, true).then((e) {
          Navigator.pop(context);
          openBottomSheet(store);
        });
      }
    });
    store = Provider.of<ExamStore>(context, listen: false);
    await store.changeType(widget.type!);
    if (widget.type != "McqExam" &&
        widget.type != "McqBookmark" &&
        widget.type != "MockBookmark" &&
        widget.type != "Custom") {
      await store.disposeStore();
      store.onTestApiCall(context, widget.type!, widget.id!);
    }
    store.startTimer();
  }

  Future<void> saveAns(bool isAdd, bool isNext) async {
    log("INDEX ==== > ${store.currentQuestionIndex.value}");
    log("Question ID ==== > ${store.question.value!.sId!}");
    final index = store.ansList.value
        .indexWhere((item) => item.questionId == store.question.value!.sId);
    if (!isNext && index != -1) {
      pre = (store.ansList.value[index].selectedOption !=
                  (store.selectedOptionIndex.value == -1
                      ? ""
                      : store
                              .question
                              .value!
                              .optionsData![store.selectedOptionIndex.value]
                              .value ??
                          "") &&
              store.ansList.value[index].selectedOption.isNotEmpty)
          ? store.ansList.value[index].selectedOption
          : null;
      setState(() {});
    }
    await store.onAns(
      ExamAnsModel(
          userExamId: widget.userExamId!,
          questionId: store.question.value!.sId!,
          selectedOption: store.selectedOptionIndex.value == -1
              ? ""
              : store.question.value!
                      .optionsData![store.selectedOptionIndex.value].value ??
                  "",
          attempted: !store.isMarkedForReview.value &&
              !store.isGuess.value &&
              store.selectedOptionIndex.value != -1,
          attemptedMarkedForReview: store.isMarkedForReview.value &&
              store.selectedOptionIndex.value != -1,
          skipped: !store.isMarkedForReview.value &&
              store.selectedOptionIndex.value == -1,
          guess: store.isGuess.value
              ? store.question.value!
                      .optionsData![store.selectedOptionIndex.value].value ??
                  ""
              : "",
          isSaved: false,
          markedForReview: store.isMarkedForReview.value &&
              store.selectedOptionIndex.value == -1,
          time: countdownTimer.getCurrentTime(),
          timePerQuestion: store.tracker.value.getCurrentTime()),
      isAdd,
      pre,
    );
    if (isNext) {
      pre = null;
      setState(() {});
    }
  }

  Future<bool> _onBackPressed() async {
    if (store.currentQuestionIndex.value! > 0) {
      await store.onChange(
          store.questionList.value[store.currentQuestionIndex.value! - 1]);
      return false;
    } else {
      bool confirmExit = await showDialog(
        context: context,
        builder: (context) => widget.type == "McqExam"
            ? CustomTestCancelDialogBox(
                timer, ValueNotifier(countdownTimer.remainingTime), false)
            : CustomMasterTestCancelDialogBox(
                timer, ValueNotifier(countdownTimer.remainingTime), false),
      );
      if (confirmExit) {
        await store.disposeStore();
      }
      return confirmExit;
    }
  }

  @override
  void dispose() async {
    countdownTimer.stop();
    countdownTimer.timeNotifier.dispose();
    await store.disposeStore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.mainId);
    final media = MediaQuery.of(context);
    final isDesktop = media.size.width > 1160 && media.size.height > 690;
    final isDesktopPalette = media.size.width > 1160 && media.size.height > 670;

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        key: _scaffoldKey,
        drawer: Drawer(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          backgroundColor: AppTokens.surface(context),
          width: double.infinity,
          child: ExamPallet(
            isDesktop: false,
            examName: widget.name ?? widget.testExamPaper!.examName ?? "",
            userExamId: widget.id!,
          ),
        ),
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: AppTokens.surface(context),
          iconTheme: IconThemeData(color: AppTokens.ink(context)),
          surfaceTintColor: AppTokens.surface(context),
          title: _ExamAppBarTitle(
            showPaletteButton: !isDesktopPalette,
            onPaletteTap: () => _scaffoldKey.currentState?.openDrawer(),
            timeNotifier: countdownTimer.timeNotifier,
            onReview: () => openBottomSheet(store),
          ),
        ),
        body: Observer(
          builder: (context) {
            if (store.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Row(
              children: [
                if (isDesktop) ...[
                  SizedBox(
                    width: media.size.width * 0.22,
                    child: ExamPallet(
                      isDesktop: true,
                      examName:
                          widget.name ?? widget.testExamPaper!.examName ?? "",
                      userExamId: widget.id!,
                    ),
                  ),
                  VerticalDivider(color: AppTokens.border(context)),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _QuestionHeader(
                        currentIndex: store.currentQuestionIndex.value! + 1,
                        total: store.questionList.value.length,
                      ),
                      const SizedBox(height: AppTokens.s24),
                      if (store.question.value != null)
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppTokens.s16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  QuestionWidget(q: store.question.value!),
                                  const SizedBox(height: AppTokens.s16),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: store
                                        .question.value!.optionsData?.length,
                                    itemBuilder: (context, index) {
                                      final testExamPaper =
                                          store.question.value!;
                                      final base64String = testExamPaper
                                              .optionsData?[index]
                                              .answerImg ??
                                          "";
                                      final isSelected = index ==
                                          store.selectedOptionIndex.value;
                                      final label = testExamPaper
                                              .optionsData?[index].value ??
                                          "";
                                      final answerTitle = testExamPaper
                                              .optionsData?[index]
                                              .answerTitle ??
                                          "";
                                      final hasImage = (testExamPaper
                                                  .optionsData?[index]
                                                  .answerImg ??
                                              "") !=
                                          "";
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: AppTokens.s12),
                                        child: _OptionCard(
                                          label: label,
                                          answerTitle: answerTitle,
                                          isSelected: isSelected,
                                          hasImage: hasImage,
                                          imageUrl: base64String,
                                          onTap: () async {
                                            if (isSelected) {
                                              await store.onOptionSelect(-1);
                                              store.changeMarkReview(false);
                                              store.changeGuess(false);
                                            } else {
                                              await store
                                                  .onOptionSelect(index);
                                            }
                                            setState(() {});
                                            saveAns(true, false);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      _BottomActionBar(
                        isMarkedForReview: store.isMarkedForReview.value,
                        isGuess: store.isGuess.value,
                        selectedOptionIndex:
                            store.selectedOptionIndex.value,
                        onReviewToggle: () {
                          store.changeGuess(false);
                          store.changeMarkReview(
                              !store.isMarkedForReview.value);
                          setState(() {});
                          saveAns(false, true);
                        },
                        onGuessToggle: () {
                          if (store.selectedOptionIndex.value != -1) {
                            setState(() {
                              store.changeGuess(!store.isGuess.value);
                              store.changeMarkReview(false);
                            });
                            saveAns(false, true);
                          }
                        },
                        onPrevious: () async {
                          if (store.selectedOptionIndex.value == -1) {}
                          store.onChange(store.questionList.value[
                              store.currentQuestionIndex.value! - 1]);
                        },
                        onNextOrSubmit: () async {
                          print(
                              "=====>questionList=====>${store.questionList.value.length}");
                          print(
                              "=====>index=====>${store.currentQuestionIndex.value}");
                          if (store.currentQuestionIndex.value! <
                              store.questionList.value.length - 1) {
                            await saveAns(false, true);
                            await store.onChange(store.questionList.value[
                                store.currentQuestionIndex.value! + 1]);
                          } else if (countdownTimer.getCurrentTime() ==
                                  "00:00:00" ||
                              widget.type != "MockExam") {
                            openBottomSheet(store);
                          }
                        },
                        isLastAndTimedMock: !(store.currentQuestionIndex
                                    .value! <
                                store.questionList.value.length - 1) &&
                            ((countdownTimer.getCurrentTime() !=
                                    "00:00:00") &&
                                (widget.type == "MockExam")),
                        isLast: !(store.currentQuestionIndex.value! <
                            store.questionList.value.length - 1),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void openBottomSheet(ExamStore store) async {
    Map<String, int> data = analyzeQuestionStatus(
        store.ansList.value, store.questionList.value.length);

    String attempted = data['isAttempted'].toString().padLeft(2, '0');
    String markedForReview =
        data['isMarkedForReview'].toString().padLeft(2, '0');
    String skipped = data['isSkipped'].toString().padLeft(2, '0');
    String attemptedandMarkedForReview =
        data['isAttemptedMarkedForReview'].toString().padLeft(2, '0');
    String notVisited = data['notVisited']! <= 0
        ? "00"
        : data['notVisited'].toString().padLeft(2, '0');
    String guess = data['isGuess'].toString().padLeft(2, '0');

    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return Observer(builder: (context) {
            return AlertDialog(
              backgroundColor: AppTokens.surface(context),
              actionsPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.r16),
              ),
              actions: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.60,
                  constraints: const BoxConstraints(maxWidth: 520),
                  decoration: BoxDecoration(
                    color: AppTokens.surface(context),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.s20),
                    child: Column(
                      children: [
                        Text(
                          "Test Submission",
                          style: AppTokens.titleMd(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink(context),
                          ),
                        ),
                        const SizedBox(height: AppTokens.s20),
                        Expanded(
                          child: Scrollbar(
                            controller: scrollController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: scrollController,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Time Left",
                                          style: AppTokens.body(context)
                                              .copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppTokens.ink(context),
                                          ),
                                        ),
                                        Text(
                                          countdownTimer.getCurrentTime(),
                                          style: AppTokens.titleSm(context)
                                              .copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppTokens.danger(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppTokens.s8),
                                    _StatusLegendRow(
                                      label: "Attempted",
                                      value: attempted,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(height: AppTokens.s8),
                                    _StatusLegendRow(
                                      label: "Marked for Review",
                                      value: markedForReview,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(height: AppTokens.s8),
                                    _StatusLegendRow(
                                      label:
                                          "Attempted and Marked for Review",
                                      value: attemptedandMarkedForReview,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(height: AppTokens.s8),
                                    _StatusLegendRow(
                                      label: "Skipped",
                                      value: skipped,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: AppTokens.s8),
                                    _StatusLegendRow(
                                      label: "Guess",
                                      value: guess,
                                      color: Colors.brown,
                                    ),
                                    const SizedBox(height: AppTokens.s8),
                                    _StatusLegendRow(
                                      label: "Not Visited",
                                      value: notVisited,
                                      color: AppTokens.ink(context),
                                    ),
                                    const SizedBox(height: AppTokens.s32),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.s20),
                          child: Text(
                            "Are you sure you want to submit the test?",
                            style: AppTokens.titleSm(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTokens.ink(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppTokens.s16),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.s20),
                          child: Row(
                            children: [
                              if (countdownTimer.getCurrentTime() !=
                                  "00:00:00") ...[
                                Expanded(
                                  child: _PrimaryPill(
                                    label: "Cancel",
                                    onTap: () => Navigator.of(context).pop(),
                                    filled: false,
                                  ),
                                ),
                              ],
                              if (countdownTimer.getCurrentTime() ==
                                      "00:00:00" ||
                                  widget.type != "MockExam") ...[
                                const SizedBox(width: AppTokens.s12),
                                Expanded(
                                  child: _PrimaryPill(
                                    label: "Submit",
                                    loading: store.isLoading,
                                    onTap: store.isLoading
                                        ? () {}
                                        : () => _submitFromSheet(),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          });
        },
      );
    } else {
      showModalBottomSheet<void>(
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        backgroundColor: AppTokens.surface(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.r28),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return Observer(builder: (context) {
            return Container(
              height: 600,
              color: AppTokens.surface(context),
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.s20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Test Submission",
                      style: AppTokens.titleMd(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTokens.ink(context),
                      ),
                    ),
                    const SizedBox(height: AppTokens.s20),
                    Expanded(
                      child: Scrollbar(
                        controller: scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(AppTokens.r8),
                                  color: AppTokens.accentSoft(context),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      AppTokens.s12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Image.asset(
                                        'assets/image/clock.png',
                                        width: 30,
                                        height: 30,
                                      ),
                                      const SizedBox(width: AppTokens.s12),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 3),
                                        child: Text(
                                          "Time Remaining",
                                          style:
                                              AppTokens.body(context).copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppTokens.ink(context),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        countdownTimer.getCurrentTime(),
                                        style: AppTokens.titleSm(context)
                                            .copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppTokens.danger(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTokens.s20),
                              listTile(
                                  'Attempted', attempted, Colors.green),
                              const SizedBox(height: AppTokens.s8),
                              listTile('Marked for Review', markedForReview,
                                  Colors.orange),
                              const SizedBox(height: AppTokens.s8),
                              listTile(
                                  'Attempted and Marked for Review',
                                  attemptedandMarkedForReview,
                                  const Color(0xff74367E)),
                              const SizedBox(height: AppTokens.s8),
                              listTile('Skipped', skipped, Colors.red),
                              const SizedBox(height: AppTokens.s8),
                              listTile('Guess', guess,
                                  const Color(0xff2E6FEE)),
                              const SizedBox(height: AppTokens.s8),
                              listTile(
                                'Not Visited',
                                notVisited,
                                // Keep legacy yellow for parity with old UI
                                // ignore: deprecated_member_use_from_same_package
                                ThemeManager.evolveYellow,
                              ),
                              const SizedBox(height: AppTokens.s32),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.s16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s20),
                      child: Row(
                        children: [
                          if (countdownTimer.getCurrentTime() !=
                              "00:00:00") ...[
                            Expanded(
                              child: _PrimaryPill(
                                label: "Cancel",
                                onTap: () => Navigator.of(context).pop(),
                                filled: false,
                              ),
                            ),
                          ],
                          if (countdownTimer.getCurrentTime() ==
                                  "00:00:00" ||
                              widget.type != "MockExam") ...[
                            const SizedBox(width: AppTokens.s12),
                            Expanded(
                              child: _PrimaryPill(
                                label: "Submit",
                                loading: store.isLoading,
                                onTap: store.isLoading
                                    ? () {}
                                    : () => _submitFromSheet(),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      );
    }
  }

  Future<void> _submitFromSheet() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate();
    }
    if (widget.type == "MockExam") {
      final store = Provider.of<TestCategoryStore>(context, listen: false);
      store.onAllExamAttemptList(widget.id!);
      final examStore = Provider.of<ExamStore>(context, listen: false);
      await examStore.disposeStore();
      Navigator.pop(context);
      Navigator.of(context).pushReplacementNamed(
        Routes.allSelectTestList,
        arguments: {
          'id': widget.testExamPaper!.examId,
          'type': "topic",
          'showPredictive': true,
          'testExamPaperListModel': widget.testExamPaper!,
          'count': (widget.testExamPaper!.remainingAttempts ?? 0) - 1,
          'isTrend': widget.isTrend,
        },
      );
    } else {
      showLoadingDialog(context);
      final store1 = Provider.of<ExamStore>(context, listen: false);
      await store1.onAnsSave(context, false);

      final store =
          Provider.of<TestCategoryStore>(context, listen: false);

      if (widget.type == "McqExam") {
        await store.onExamAttemptList(widget.testExamPaper!.sid!);
      }
      if (widget.type == "McqBookmark" ||
          widget.type == "MockBookmark" ||
          widget.type == "Custom") {
        final store = Provider.of<BookmarkNewStore>(context, listen: false);
        store.ongetCustomAnalysisApiCall(
          widget.type!,
          widget.mainId!.isEmpty
              ? "67c7362d96ec565129f93c11"
              : widget.mainId!,
          widget.isAll ?? false,
        );
        Navigator.pop(context);
      }
      await store1.disposeStore();
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }
}

// ---------------------------------------------------------------------------
// App bar / question header / bottom action bar — small private widgets that
// exist solely to slim down the monster `build` body. They do NOT change any
// public surface or behaviour.
// ---------------------------------------------------------------------------

class _ExamAppBarTitle extends StatelessWidget {
  const _ExamAppBarTitle({
    required this.showPaletteButton,
    required this.onPaletteTap,
    required this.timeNotifier,
    required this.onReview,
  });

  final bool showPaletteButton;
  final VoidCallback onPaletteTap;
  final ValueNotifier<String> timeNotifier;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showPaletteButton)
          InkWell(
            onTap: onPaletteTap,
            borderRadius: BorderRadius.circular(AppTokens.r12),
            child: Image.asset(
              "assets/image/questionplatte.png",
              width: AppTokens.s32,
            ),
          ),
        const Spacer(),
        Image.asset("assets/image/clock2.png", width: 16),
        const SizedBox(width: AppTokens.s4),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: ValueListenableBuilder<String>(
            valueListenable: timeNotifier,
            builder: (context, time, child) {
              return Text(
                time,
                style: AppTokens.numeric(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTokens.ink(context),
                ),
              );
            },
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onReview,
          borderRadius: BorderRadius.circular(60),
          child: Container(
            height: AppTokens.s32 + AppTokens.s4,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTokens.brand),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Text(
              "Review",
              style: AppTokens.caption(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.brand,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({required this.currentIndex, required this.total});
  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTokens.s16,
        right: AppTokens.s16,
        top: AppTokens.s16,
      ),
      child: Row(
        children: [
          Text(
            "$currentIndex.",
            style: AppTokens.titleMd(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppTokens.ink(context),
            ),
          ),
          const Spacer(),
          Container(
            height: AppTokens.s32,
            width: AppTokens.s32 + 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTokens.brand, AppTokens.brand2],
              ),
              borderRadius: BorderRadius.circular(AppTokens.r8),
            ),
            child: Center(
              child: Text(
                "Q-${currentIndex.toString().padLeft(2, '0')}",
                style: AppTokens.caption(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Text(
            "Out of ${total.toString().padLeft(2, '0')}",
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w500,
              color: AppTokens.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.answerTitle,
    required this.isSelected,
    required this.hasImage,
    required this.imageUrl,
    required this.onTap,
  });

  final String label;
  final String answerTitle;
  final bool isSelected;
  final bool hasImage;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r28),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppTokens.brand, AppTokens.brand2],
                )
              : null,
          color: isSelected ? null : AppTokens.surface(context),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTokens.border(context),
            width: 0.84,
          ),
          borderRadius: BorderRadius.circular(AppTokens.r28),
          boxShadow: isSelected ? AppTokens.shadow1(context) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s20,
            vertical: AppTokens.s16,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$label.",
                        style: AppTokens.bodyLg(context).copyWith(
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppTokens.ink(context),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s4),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: Text(
                          answerTitle,
                          style: AppTokens.bodyLg(context).copyWith(
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppTokens.ink(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasImage)
                    Row(
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
                                  if (imageUrl != '')
                                    Image.network(imageUrl),
                                  Container(color: Colors.transparent),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.isMarkedForReview,
    required this.isGuess,
    required this.selectedOptionIndex,
    required this.onReviewToggle,
    required this.onGuessToggle,
    required this.onPrevious,
    required this.onNextOrSubmit,
    required this.isLastAndTimedMock,
    required this.isLast,
  });

  final bool isMarkedForReview;
  final bool isGuess;
  final int selectedOptionIndex;
  final VoidCallback onReviewToggle;
  final VoidCallback onGuessToggle;
  final VoidCallback onPrevious;
  final VoidCallback onNextOrSubmit;
  final bool isLastAndTimedMock;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        boxShadow: AppTokens.shadow2(context),
        border: Border(
          top: BorderSide(color: AppTokens.border(context)),
        ),
      ),
      padding: const EdgeInsets.only(
        top: AppTokens.s20,
        left: AppTokens.s24,
        right: AppTokens.s24,
        bottom: AppTokens.s24,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CheckBoxWithLabel(
                  isShowMessage: false,
                  label: 'Mark for review',
                  isChecked: isMarkedForReview,
                  onStatusChanged: (status) => onReviewToggle(),
                ),
              ),
              Expanded(
                child: CheckBoxWithLabel(
                  label: 'Mark for guess answer',
                  isChecked: isGuess,
                  isShowMessage: selectedOptionIndex == -1,
                  onStatusChanged: (status) => onGuessToggle(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: CustomPreviewBox(
                  onTap: onPrevious,
                  text: "Previous",
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: CustomPreviewBox(
                  textColor: Colors.white,
                  bgColor: isLastAndTimedMock
                      ? AppTokens.muted(context)
                      : AppTokens.brand,
                  borderColor: Colors.transparent,
                  onTap: onNextOrSubmit,
                  text: isLast ? "Submit" : "Next",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusLegendRow extends StatelessWidget {
  const _StatusLegendRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 5.0, backgroundColor: color),
        const SizedBox(width: AppTokens.s8),
        Text(
          label,
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w500,
            color: AppTokens.ink(context),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppTokens.ink(context),
          ),
        ),
      ],
    );
  }
}

class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill({
    required this.label,
    required this.onTap,
    this.filled = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r8),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(
                  colors: [AppTokens.brand, AppTokens.brand2],
                )
              : null,
          color: filled ? null : AppTokens.surface2(context),
          border: filled
              ? null
              : Border.all(color: AppTokens.border(context)),
          borderRadius: BorderRadius.circular(AppTokens.r8),
          boxShadow: filled ? AppTokens.shadow1(context) : null,
        ),
        child: loading && filled
            ? const Center(
                child:
                    CupertinoActivityIndicator(color: Colors.white),
              )
            : Text(
                label,
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : AppTokens.ink(context),
                ),
              ),
      ),
    );
  }
}

/// Public top-level helper kept intact for byte-for-byte compatibility with
/// any external imports. The rendered look is upgraded (divider uses border
/// tokens, text uses AppTokens typography) but the signature
/// `listTile(String title, String value, Color color)` is preserved.
Widget listTile(String title, String value, Color color) {
  return Builder(builder: (context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              height: 16,
              width: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            Text(
              title,
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w500,
                color: AppTokens.ink(context),
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: AppTokens.numeric(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppTokens.ink(context),
              ),
            ),
          ],
        ),
        Divider(color: AppTokens.border(context)),
      ],
    );
  });
}
