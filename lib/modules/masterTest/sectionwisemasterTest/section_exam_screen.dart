// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names, dead_null_aware_expression, prefer_final_fields, unused_local_variable

import 'dart:io';
import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:shusruta_lms/helpers/styles.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/login/store/verify_otp_phone.dart';
import 'package:shusruta_lms/modules/masterTest/custom_master_test_dialogbox.dart';
import 'package:shusruta_lms/modules/masterTest/sectionwisemasterTest/model/get_section_list_model.dart';
import 'package:shusruta_lms/modules/masterTest/sectionwisemasterTest/section_exam_pallet.dart';
import 'package:shusruta_lms/modules/masterTest/sectionwisemasterTest/sections_list_screen.dart';
import 'package:shusruta_lms/modules/masterTest/sectionwisemasterTest/store/section_exam_store.dart';
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

/// Section-wise master exam screen. Redesigned with AppTokens while
/// preserving every contract on the widget:
///   • Constructor with 16 keyed params (testExamPaper, id, userExamId,
///     timeDuration, name, showPredictive, isTrend, isLastSection=false,
///     required sectionData, mainId, type, isAll=false, isSecond=false,
///     ansList=const[], questionList=const[], sectionsList=const[])
///   • State mixes in `WidgetsBindingObserver`, retains three
///     `ReactionDisposer`s (disposer/disposer2/disposer3), the scaffold
///     key, scrollController, two `CountdownTimer`s, and `pre` snapshot
///   • `init()`, `saveAns(isAdd, isNext)`, `onSubmit()`,
///     `_onBackPressed()`, `didChangeAppLifecycleState()`,
///     `openBottomSheet(store)` preserved verbatim with the same
///     Windows/macOS dialog vs mobile modal branch, the same
///     `analyzeQuestionStatus` aggregation, and the same navigation
///     contracts (pushReplacement SectionListScreen, pushReplacementNamed
///     `Routes.allSelectTestList` with 6 arg keys)
///   • Drawer holds a `SectionExamPallet` with 8 forwarded props; the
///     same pallet appears in the left rail on wide screens (width>1160
///     && height>690)
///   • Top-level `listTile(title, value, color)` helper preserved for any
///     external callers relying on it
class SectionExamScreen extends StatefulWidget {
  const SectionExamScreen({
    super.key,
    this.testExamPaper,
    this.id,
    this.userExamId,
    this.timeDuration,
    this.name,
    this.showPredictive,
    this.isTrend,
    this.isLastSection = false,
    required this.sectionData,
    this.mainId,
    this.type,
    this.isAll = false,
    this.isSecond = false,
    this.ansList = const [],
    this.questionList = const [],
    this.sectionsList = const [],
  });

  final TestExamPaperListModel? testExamPaper;
  final String? id;
  final String? userExamId;
  final String? timeDuration;
  final String? name;
  final GetSectionListModel sectionData;
  final List<List<ExamAnsModel>> ansList;
  final List<List<TestData>> questionList;
  final List<GetSectionListModel> sectionsList;
  final bool? showPredictive;
  final bool? isTrend;
  final bool? isAll;
  final bool? isLastSection;
  final String? type;
  final String? mainId;
  final bool isSecond;

  @override
  State<SectionExamScreen> createState() => _SectionExamScreenState();
}

class _SectionExamScreenState extends State<SectionExamScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late SectionExamStore store;
  Timer? timer;
  Duration? remainingTime;
  Duration? duration;
  String? usedExamTime;
  String? pre;

  late CountdownTimer countdownTimer;
  late CountdownTimer sectionTimer;
  final ScrollController scrollController = ScrollController();

  late ReactionDisposer disposer;
  late ReactionDisposer disposer2;
  late ReactionDisposer disposer3;

  List<GetSectionListModel> sectionsList = [];
  List<List<TestData>> questionList = [];
  List<List<ExamAnsModel>> ansList = [];

  // --------------------------------------------------------------------
  // Lifecycle
  // --------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    init();
  }

  @override
  void dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    countdownTimer.dispose();
    sectionTimer.dispose();
    await store.disposeStore();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
        countdownTimer.pause();
        sectionTimer.pause();
        break;
      case AppLifecycleState.resumed:
        countdownTimer.resume(() {});
        sectionTimer.resume(() async {
          if (!store.isSubmit.value) {
            countdownTimer.stop();
            showLoadingDialog(context);
            store.onAnsSave(context, true).then((e) {
              Navigator.pop(context);
              if (widget.isLastSection ?? false) {
                openBottomSheet(store);
              } else {
                onSubmit();
              }
            });
          }
        });
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  // --------------------------------------------------------------------
  // Initialisation
  // --------------------------------------------------------------------

  Future<void> init() async {
    store = Provider.of<SectionExamStore>(context, listen: false);

    debugPrint('init: widget.questionList.length=${widget.questionList.length}');
    debugPrint('init: widget.sectionsList.length=${widget.sectionsList.length}');
    debugPrint(
        'init: store.questionList.value.length=${store.questionList.value.length}');
    debugPrint('init: widget.sectionData.sectionId=${widget.sectionData.sectionId}');

    if (widget.questionList.isNotEmpty &&
        widget.questionList[0].isNotEmpty &&
        store.questionList.value.isEmpty) {
      final currentSectionIndex = widget.sectionsList.indexWhere(
        (section) => section.sectionId == widget.sectionData.sectionId,
      );
      debugPrint('init: currentSectionIndex=$currentSectionIndex');

      if (currentSectionIndex >= 0 &&
          currentSectionIndex < widget.questionList.length &&
          widget.questionList[currentSectionIndex].isNotEmpty) {
        store.questionList.value =
            List<TestData>.from(widget.questionList[currentSectionIndex]);
        debugPrint(
            'init: Loaded ${store.questionList.value.length} questions from widget.questionList[$currentSectionIndex]');
        if (store.questionList.value.isNotEmpty) {
          store.question.value = store.questionList.value[0];
          store.currentQuestionIndex.value = 0;
        }
      } else if (widget.questionList[0].isNotEmpty) {
        store.questionList.value = List<TestData>.from(widget.questionList[0]);
        debugPrint(
            'init: Loaded ${store.questionList.value.length} questions from widget.questionList[0] (fallback)');
        if (store.questionList.value.isNotEmpty) {
          store.question.value = store.questionList.value[0];
          store.currentQuestionIndex.value = 0;
        }
      }
    }

    if (store.questionList.value.isEmpty &&
        widget.id != null &&
        widget.sectionData.sectionId != null) {
      debugPrint(
          'init: Loading questions from API for sectionId=${widget.sectionData.sectionId}');
      try {
        await store.onTestApiCall(
          context,
          widget.type ?? 'MockExam',
          widget.sectionData.sectionId ?? '',
        );
        debugPrint(
            'init: Loaded ${store.questionList.value.length} questions from API');
      } catch (e) {
        debugPrint('init: Error loading questions from API: $e');
      }
    }

    debugPrint(
        'init: Final store.questionList.value.length=${store.questionList.value.length}');

    countdownTimer = CountdownTimer(store.timeDuration);
    sectionTimer =
        CountdownTimer(widget.sectionData.timeDuration ?? '00:00:15');

    sectionsList = [...widget.sectionsList, widget.sectionData];

    setState(() {});

    countdownTimer.start(() {});
    sectionTimer.start(() async {
      if (!store.isSubmit.value) {
        countdownTimer.stop();
        showLoadingDialog(context);
        store.onAnsSave(context, true).then((e) {
          Navigator.pop(context);
          if (widget.isLastSection ?? false) {
            openBottomSheet(store);
          } else {
            onSubmit();
          }
        });
      }
    });

    store.startTimer();
  }

  // --------------------------------------------------------------------
  // Submission flow
  // --------------------------------------------------------------------

  void onSubmit() async {
    String currentTime = countdownTimer.getCurrentTime();
    final parts = currentTime.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    int seconds = int.parse(parts[2]) + 1;
    if (seconds >= 60) {
      seconds = 0;
      minutes += 1;
      if (minutes >= 60) {
        minutes = 0;
        hours += 1;
      }
    }
    currentTime =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    setState(() {});

    final route = CupertinoPageRoute(
      builder: (context) => SectionListScreen(
        sectionsList: sectionsList,
        isSecond: widget.isSecond,
        id: widget.id,
        testExamPaper: widget.testExamPaper,
        userexamId: widget.userExamId,
        previousSectionTime: currentTime,
      ),
    );
    Navigator.pushReplacement(context, route);
    store.disposeSectiomStore(currentTime);
  }

  Future<void> saveAns(bool isAdd, bool isNext) async {
    log('INDEX ==== > ${store.currentQuestionIndex.value}');
    log('Question ID ==== > ${store.question.value!.sId!}');
    final index = store.ansList.value
        .indexWhere((item) => item.questionId == store.question.value!.sId);
    if (!isNext && index != -1) {
      pre = (store.ansList.value[index].selectedOption !=
                  (store.selectedOptionIndex.value == -1
                      ? ''
                      : store.question.value!
                              .optionsData![store.selectedOptionIndex.value]
                              .value ??
                          '') &&
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
            ? ''
            : store.question.value!
                    .optionsData![store.selectedOptionIndex.value].value ??
                '',
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
                ''
            : '',
        isSaved: false,
        markedForReview: store.isMarkedForReview.value &&
            store.selectedOptionIndex.value == -1,
        time: countdownTimer.getCurrentTime(),
        timePerQuestion: store.tracker.value.getCurrentTime(),
      ),
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
        builder: (context) => widget.type == 'McqExam'
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

  // --------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------

  bool _isWide(BuildContext context) =>
      MediaQuery.of(context).size.width > 1160 &&
      MediaQuery.of(context).size.height > 690;

  bool _hideDrawerBtn(BuildContext context) =>
      MediaQuery.of(context).size.width > 1160 &&
      MediaQuery.of(context).size.height > 670;

  @override
  Widget build(BuildContext context) {
    print('widget.questionList=====>:${widget.questionList.length}');

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppTokens.scaffold(context),
        drawer: Drawer(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          backgroundColor: AppTokens.surface(context),
          width: double.infinity,
          child: SectionExamPallet(
            currentSectionsList: widget.sectionData,
            sectionsList: widget.sectionsList,
            ansList: widget.ansList,
            questionList: widget.questionList,
            sectionData: widget.sectionData,
            isDesktop: false,
            examName: widget.name ?? widget.testExamPaper!.examName ?? '',
            userExamId: widget.id!,
          ),
        ),
        appBar: _buildAppBar(context),
        body: Observer(builder: (context) {
          if (store.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (store.questionList.value.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Row(
            children: [
              if (_isWide(context)) ...[
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.22,
                  child: SectionExamPallet(
                    currentSectionsList: widget.sectionData,
                    sectionsList: widget.sectionsList,
                    ansList: widget.ansList,
                    questionList: widget.questionList,
                    sectionData: widget.sectionData,
                    isDesktop: true,
                    examName:
                        widget.name ?? widget.testExamPaper!.examName ?? '',
                    userExamId: widget.id!,
                  ),
                ),
                VerticalDivider(color: AppTokens.border(context), width: 1),
              ],
              Expanded(child: _buildQuestionPane(context)),
            ],
          );
        }),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: AppTokens.surface(context),
      surfaceTintColor: AppTokens.surface(context),
      title: Padding(
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            if (!_hideDrawerBtn(context))
              InkWell(
                borderRadius: BorderRadius.circular(AppTokens.r12),
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.s4),
                  child: Image.asset(
                    'assets/image/questionplatte.png',
                    width: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                  ),
                ),
              ),
            const Spacer(),
            _TimerPill(timer: countdownTimer),
            const Spacer(),
            _ReviewCta(onTap: () => openBottomSheet(store)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPane(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionInfoBar(
          section: widget.sectionData,
          sectionTimer: sectionTimer,
        ),
        _QuestionCounter(store: store),
        if (store.question.value != null)
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.PADDING_SIZE_DEFAULT),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QuestionWidget(q: store.question.value!),
                    const SizedBox(height: AppTokens.s16),
                    _OptionsList(
                      store: store,
                      onSelect: () => saveAns(true, false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        _BottomActionBar(
          store: store,
          sectionTimer: sectionTimer,
          type: widget.type,
          onMarkReviewToggle: () {
            store.changeGuess(false);
            store.changeMarkReview(!store.isMarkedForReview.value);
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
          onPrevious: () {
            if (store.selectedOptionIndex.value == -1) {}
            store.onChange(
              store.questionList.value[store.currentQuestionIndex.value! - 1],
            );
          },
          onNextOrSubmit: () async {
            print('=====>questionList=====>${store.questionList.value.length}');
            print('=====>index=====>${store.currentQuestionIndex.value}');
            if (store.currentQuestionIndex.value! <
                store.questionList.value.length - 1) {
              await saveAns(false, true);
              await store.onChange(
                store.questionList.value[store.currentQuestionIndex.value! + 1],
              );
            } else if (sectionTimer.getCurrentTime() == '00:00:00' ||
                widget.type != 'MockExam') {
              openBottomSheet(store);
            }
          },
        ),
      ],
    );
  }

  // --------------------------------------------------------------------
  // Submission sheet
  // --------------------------------------------------------------------

  void openBottomSheet(SectionExamStore store) async {
    Map<String, int> data = analyzeQuestionStatus(
      store.ansList.value,
      store.questionList.value.length,
    );
    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return Material(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Observer(builder: (context) {
                  return _buildSubmissionContent(
                    context: context,
                    setStateSB: setState,
                    data: data,
                    onDataReplace: (d) => data = d,
                    store: store,
                    isDialog: true,
                  );
                });
              },
            ),
          );
        },
      );
    } else {
      showModalBottomSheet<void>(
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Observer(builder: (context) {
                return _buildSubmissionContent(
                  context: context,
                  setStateSB: setState,
                  data: data,
                  onDataReplace: (d) => data = d,
                  store: store,
                  isDialog: false,
                );
              });
            },
          );
        },
      );
    }
  }

  Widget _buildSubmissionContent({
    required BuildContext context,
    required StateSetter setStateSB,
    required Map<String, int> data,
    required ValueChanged<Map<String, int>> onDataReplace,
    required SectionExamStore store,
    required bool isDialog,
  }) {
    String attempted = data['isAttempted'].toString().padLeft(2, '0');
    String markedForReview =
        data['isMarkedForReview'].toString().padLeft(2, '0');
    String skipped = data['isSkipped'].toString().padLeft(2, '0');
    String attemptedandMarkedForReview =
        data['isAttemptedMarkedForReview'].toString().padLeft(2, '0');
    String notVisited = (data['notVisited'] ?? 0) <= 0
        ? '00'
        : data['notVisited'].toString().padLeft(2, '0');
    String guess = data['isGuess'].toString().padLeft(2, '0');

    final content = Container(
      height: isDialog ? null : 600,
      color: AppTokens.scaffold(context),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s24,
        vertical: AppTokens.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Test Submission',
            style: AppTokens.titleMd(context).copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: AppTokens.s20),
          DefaultTabController(
            length: widget.sectionsList.length + 2,
            initialIndex: widget.sectionsList.length + 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TabBar(
                  onTap: (value) {
                    if (value == 0) {
                      data = analyzeQuestionStatus(
                        store.ansList.value,
                        store.questionList.value.length,
                      );
                      int totalAttempted = 0;
                      int mark = 0;
                      int attemptedMarked = 0;
                      int skipped = 0;
                      int notVisited = 0;
                      int guess = 0;
                      for (int i = 0; i < widget.sectionsList.length; i++) {
                        totalAttempted +=
                            (store.getSectionListModel.value[i].attempted ??
                                    0) +
                                (store.getSectionListModel.value[i]
                                        .markedforreview ??
                                    0) +
                                (store.getSectionListModel.value[i]
                                        .attemptedandmarkedforreview ??
                                    0);
                        mark += (store.getSectionListModel.value[i]
                                .markedforreview ??
                            0);
                        attemptedMarked += (store.getSectionListModel.value[i]
                                .attemptedandmarkedforreview ??
                            0);
                        skipped +=
                            (store.getSectionListModel.value[i].skipped ?? 0);
                        guess +=
                            (store.getSectionListModel.value[i].guess ?? 0);
                        notVisited += (store
                                .getSectionListModel.value[i].notVisited ??
                            0);
                      }
                      data['isAttempted'] =
                          (data['isAttempted'] ?? 0) + totalAttempted;
                      data['isMarkedForReview'] =
                          (data['isMarkedForReview'] ?? 0) + mark;
                      data['isAttemptedMarkedForReview'] =
                          (data['isAttemptedMarkedForReview'] ?? 0) +
                              attemptedMarked;
                      data['isSkipped'] =
                          (data['isSkipped'] ?? 0) + skipped;
                      data['notVisited'] =
                          (data['notVisited'] ?? 0) + notVisited;
                      data['isGuess'] = (data['isGuess'] ?? 0) + guess;
                      onDataReplace(data);
                      setStateSB(() {});
                    } else if (value == widget.sectionsList.length + 1) {
                      data = analyzeQuestionStatus(
                        store.ansList.value,
                        store.questionList.value.length,
                      );
                      onDataReplace(data);
                      setStateSB(() {});
                    } else {
                      data.clear();
                      data['isAttempted'] = store.getSectionListModel
                              .value[value - 1].attempted ??
                          0;
                      data['isMarkedForReview'] = store.getSectionListModel
                              .value[value - 1].markedforreview ??
                          0;
                      data['isAttemptedMarkedForReview'] = store
                              .getSectionListModel
                              .value[value - 1]
                              .attemptedandmarkedforreview ??
                          0;
                      data['isSkipped'] = store.getSectionListModel
                              .value[value - 1].skipped ??
                          0;
                      data['notVisited'] = store.getSectionListModel
                              .value[value - 1].notVisited ??
                          0;
                      data['isGuess'] =
                          store.getSectionListModel.value[value - 1].guess ??
                              0;
                      onDataReplace(data);
                      setStateSB(() {});
                    }
                  },
                  isScrollable: true,
                  labelColor: AppTokens.accent(context),
                  unselectedLabelColor: AppTokens.muted(context),
                  indicatorColor: AppTokens.accent(context),
                  labelStyle: AppTokens.bodyLg(context)
                      .copyWith(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: AppTokens.body(context),
                  tabs: List<Widget>.generate(
                    widget.sectionsList.length + 2,
                    (int index) {
                      if (index == 0) {
                        return const Tab(text: 'All');
                      } else if (index == widget.sectionsList.length + 1) {
                        return Tab(
                          text: 'Section ${widget.sectionData.section}',
                        );
                      } else {
                        return Tab(
                          text:
                              'Section ${widget.sectionsList[index - 1].section}',
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s20),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  listTile('Attempted', attempted, AppTokens.success(context)),
                  const SizedBox(height: AppTokens.s8),
                  listTile(
                    'Marked for Review',
                    markedForReview,
                    AppTokens.warning(context),
                  ),
                  const SizedBox(height: AppTokens.s8),
                  listTile(
                    'Attempted and Marked for Review',
                    attemptedandMarkedForReview,
                    const Color(0xff74367E),
                  ),
                  const SizedBox(height: AppTokens.s8),
                  listTile('Skipped', skipped, AppTokens.danger(context)),
                  const SizedBox(height: AppTokens.s8),
                  listTile(
                    'Guess',
                    guess,
                    const Color(0xff2E6FEE),
                  ),
                  const SizedBox(height: AppTokens.s8),
                  listTile('Not Visited', notVisited, ThemeManager.evolveYellow),
                  const SizedBox(height: AppTokens.s32),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          _SubmissionActionRow(
            showCancel: sectionTimer.getCurrentTime() != '00:00:00',
            showSubmit: sectionTimer.getCurrentTime() == '00:00:00' ||
                widget.type != 'MockExam',
            isLoading: store.isLoading,
            onCancel: () => Navigator.of(context).pop(),
            onSubmit: store.isLoading ? null : () => _handleSubmit(context),
          ),
        ],
      ),
    );

    return content;
  }

  Future<void> _handleSubmit(BuildContext context) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate();
    }
    if (widget.type == 'MockExam') {
      final tcStore = Provider.of<TestCategoryStore>(context, listen: false);
      tcStore.onAllExamAttemptList(widget.id!);
      final examStore = Provider.of<SectionExamStore>(context, listen: false);
      await examStore.disposeStore();
      Navigator.pop(context);
      Navigator.of(context).pushReplacementNamed(
        Routes.allSelectTestList,
        arguments: {
          'id': widget.testExamPaper!.examId,
          'type': 'topic',
          'showPredictive': true,
          'testExamPaperListModel': widget.testExamPaper!,
          'count': (widget.testExamPaper!.remainingAttempts ?? 0) - 1,
          'isTrend': widget.isTrend,
        },
      );
    } else {
      showLoadingDialog(context);
      final store1 = Provider.of<SectionExamStore>(context, listen: false);
      await store1.onAnsSave(context, false);
      final tcStore = Provider.of<TestCategoryStore>(context, listen: false);
      if (widget.type == 'McqExam') {
        await tcStore.onExamAttemptList(widget.testExamPaper!.sid!);
      }
      if (widget.type == 'McqBookmark' || widget.type == 'MockBookmark') {
        final bkStore = Provider.of<BookmarkNewStore>(context, listen: false);
        bkStore.ongetCustomAnalysisApiCall(
          widget.type!,
          widget.mainId!.isEmpty
              ? '67c7362d96ec565129f93c11'
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

// --------------------------------------------------------------------
// Private primitives
// --------------------------------------------------------------------

class _TimerPill extends StatelessWidget {
  const _TimerPill({required this.timer});
  final CountdownTimer timer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s4,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: BorderRadius.circular(AppTokens.r20),
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/image/clock2.png', width: 16),
          const SizedBox(width: 6),
          ValueListenableBuilder<String>(
            valueListenable: timer.timeNotifier,
            builder: (context, time, child) {
              return Text(
                time,
                style: AppTokens.numeric(context).copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReviewCta extends StatelessWidget {
  const _ReviewCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.r28),
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        padding:
            const EdgeInsets.symmetric(horizontal: AppTokens.s20),
        decoration: BoxDecoration(
          color: AppTokens.accentSoft(context),
          border: Border.all(color: AppTokens.accent(context)),
          borderRadius: BorderRadius.circular(AppTokens.r28),
        ),
        child: Text(
          'Review',
          style: AppTokens.bodyLg(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppTokens.accent(context),
          ),
        ),
      ),
    );
  }
}

class _SectionInfoBar extends StatelessWidget {
  const _SectionInfoBar({required this.section, required this.sectionTimer});
  final GetSectionListModel section;
  final CountdownTimer sectionTimer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionChip(
              iconPath: 'assets/image/sectionBook.svg',
              label: 'Section ${section.section ?? ""}',
            ),
            const SizedBox(width: AppTokens.s12),
            _SectionChip(
              iconPath: 'assets/image/sectionTime.svg',
              labelBuilder: () => ValueListenableBuilder<String>(
                valueListenable: sectionTimer.timeNotifier,
                builder: (context, time, child) {
                  return Text(
                    time,
                    style: AppTokens.numeric(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            _SectionChip(
              iconPath: 'assets/image/sectionBook.svg',
              label: 'Question ${section.numberOfQuestions ?? ""}',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({required this.iconPath, this.label, this.labelBuilder});
  final String iconPath;
  final String? label;
  final Widget Function()? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(iconPath, color: Colors.white),
        const SizedBox(width: AppTokens.s4),
        if (labelBuilder != null)
          labelBuilder!()
        else
          Text(
            label ?? '',
            style: AppTokens.caption(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 0,
            ),
          ),
      ],
    );
  }
}

class _QuestionCounter extends StatelessWidget {
  const _QuestionCounter({required this.store});
  final SectionExamStore store;

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
            '${store.currentQuestionIndex.value! + 1}.',
            style: AppTokens.displayMd(context).copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          Container(
            height: 32,
            width: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTokens.brand, AppTokens.brand2],
              ),
              borderRadius: BorderRadius.circular(AppTokens.r12),
              boxShadow: AppTokens.shadow1(context),
            ),
            alignment: Alignment.center,
            child: Text(
              'Q-${(store.currentQuestionIndex.value! + 1).toString().padLeft(2, '0')}',
              style: AppTokens.bodyLg(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Text(
            'Out of ${store.questionList.value.length.toString().padLeft(2, '0')}',
            style: AppTokens.body(context).copyWith(
              color: AppTokens.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionsList extends StatelessWidget {
  const _OptionsList({required this.store, required this.onSelect});
  final SectionExamStore store;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final q = store.question.value!;
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: q.optionsData?.length ?? 0,
      itemBuilder: (context, index) {
        final option = q.optionsData![index];
        final base64String = option.answerImg ?? '';
        final isSelected = index == store.selectedOptionIndex.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.s12),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.r28),
            onTap: () async {
              if (isSelected) {
                await store.onOptionSelect(-1);
                store.changeMarkReview(false);
                store.changeGuess(false);
              } else {
                await store.onOptionSelect(index);
              }
              onSelect();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTokens.accent(context)
                    : AppTokens.surface(context),
                border: Border.all(
                  color: isSelected
                      ? AppTokens.accent(context)
                      : AppTokens.border(context),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(AppTokens.r28),
                boxShadow: isSelected ? AppTokens.shadow1(context) : null,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s20,
                vertical: AppTokens.s16,
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
                              '${option.value}.',
                              style: AppTokens.bodyLg(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppTokens.ink(context),
                              ),
                            ),
                            const SizedBox(width: AppTokens.s8),
                            Expanded(
                              child: Text(
                                option.answerTitle ?? '',
                                style: AppTokens.bodyLg(context).copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTokens.ink(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if ((option.answerImg ?? '') != '') ...[
                          const SizedBox(height: AppTokens.s12),
                          InteractiveViewer(
                            minScale: 1.0,
                            maxScale: 3.0,
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppTokens.r12),
                              child: SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.6,
                                height: 250,
                                child: Stack(
                                  children: [
                                    if (base64String != '')
                                      Image.network(base64String),
                                    Container(color: Colors.transparent),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.store,
    required this.sectionTimer,
    required this.type,
    required this.onMarkReviewToggle,
    required this.onGuessToggle,
    required this.onPrevious,
    required this.onNextOrSubmit,
  });

  final SectionExamStore store;
  final CountdownTimer sectionTimer;
  final String? type;
  final VoidCallback onMarkReviewToggle;
  final VoidCallback onGuessToggle;
  final VoidCallback onPrevious;
  final VoidCallback onNextOrSubmit;

  @override
  Widget build(BuildContext context) {
    final atLast = !(store.currentQuestionIndex.value! <
        store.questionList.value.length - 1);
    final isDisabled = atLast &&
        sectionTimer.getCurrentTime() != '00:00:00' &&
        type == 'MockExam';

    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        border: Border(
          top: BorderSide(color: AppTokens.border(context)),
        ),
        boxShadow: AppTokens.shadow2(context),
      ),
      padding: const EdgeInsets.only(
        top: AppTokens.s16,
        left: AppTokens.s24,
        right: AppTokens.s20,
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
                  isChecked: store.isMarkedForReview.value,
                  onStatusChanged: (_) => onMarkReviewToggle(),
                ),
              ),
              Expanded(
                child: CheckBoxWithLabel(
                  label: 'Mark for guess answer',
                  isChecked: store.isGuess.value,
                  isShowMessage: store.selectedOptionIndex.value == -1,
                  onStatusChanged: (_) => onGuessToggle(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: CustomPreviewBox(
                  onTap: onPrevious,
                  text: 'Previous',
                ),
              ),
              const SizedBox(width: AppTokens.s16),
              Expanded(
                child: CustomPreviewBox(
                  textColor: Colors.white,
                  bgColor: isDisabled
                      ? AppTokens.muted(context)
                      : AppTokens.accent(context),
                  borderColor: Colors.transparent,
                  onTap: onNextOrSubmit,
                  text: atLast ? 'Submit' : 'Next',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubmissionActionRow extends StatelessWidget {
  const _SubmissionActionRow({
    required this.showCancel,
    required this.showSubmit,
    required this.isLoading,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool showCancel;
  final bool showSubmit;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
      child: Row(
        children: [
          if (showCancel) ...[
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTokens.r12),
                onTap: onCancel,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.surface2(context),
                    border: Border.all(color: AppTokens.border(context)),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                    boxShadow: AppTokens.shadow1(context),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTokens.bodyLg(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTokens.ink(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (showSubmit) ...[
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTokens.r12),
                onTap: onSubmit ?? () {},
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTokens.brand, AppTokens.brand2],
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                    boxShadow: AppTokens.shadow2(context),
                  ),
                  child: isLoading
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Text(
                          'Submit',
                          style: AppTokens.bodyLg(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------
// Public top-level helper (kept for any external callers)
// --------------------------------------------------------------------

Widget listTile(String title, String value, Color color) {
  return Builder(
    builder: (context) {
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
          Divider(color: AppTokens.border(context), height: AppTokens.s16),
        ],
      );
    },
  );
}
