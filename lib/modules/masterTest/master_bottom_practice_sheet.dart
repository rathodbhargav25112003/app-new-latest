// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, unused_local_variable, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../models/test_exampaper_list_model.dart';
import '../test/store/test_category_store.dart';
import '../widgets/bottom_toast.dart';

/// Master-test practice entry bottom sheet — redesigned with AppTokens.
/// Preserves:
///   • Positional constructor
///     `MasterPracticeBottomSheet(BuildContext context, testExamPaper, id,
///      type, isPractice, {super.key})`
///   • State: `queryController`, `questions` list order, `currentIndex`
///   • initState → `getPracticeCount()` → `store.onGetMockPracticeCountApiCall(
///      exitUserExamId)`
///   • 4 counter pills (Answered / Unanswered / Correct / Incorrect) from
///     `store.getMockPracticeCountData.value`
///   • 3 radio options: "All Questions" / "Answered Questions" /
///     "Unanswered Questions"
///   • Cancel → `Navigator.pop(context)`
///   • Next branches on `currentIndex`:
///       0 → `_startMasterExamApiCall(...)`
///       1 → `_startAnsweredMasterExamApiCall(..., 'Answered')` (modal
///            `StartPracticeBottomSheet`)
///       2 → `_startUnAnsweredMasterExamApiCall(..., 'Unanswered')`
///   • All four async helpers verbatim incl. TestData/Options mapping and
///     Routes.testExams / Routes.testMasterExams / Routes.practiceMasterTestExams
class MasterPracticeBottomSheet extends StatefulWidget {
  final TestExamPaperListModel? testExamPaper;
  final String? id;
  final String? type;
  final bool? isPractice;
  const MasterPracticeBottomSheet(BuildContext context, this.testExamPaper,
      this.id, this.type, this.isPractice,
      {super.key});

  @override
  State<MasterPracticeBottomSheet> createState() =>
      _MasterPracticeBottomSheetState();
}

class _MasterPracticeBottomSheetState extends State<MasterPracticeBottomSheet> {
  TextEditingController queryController = TextEditingController();
  List<String> questions = [
    "All Questions",
    "Answered Questions",
    "Unanswered Questions"
  ];
  int? currentIndex;

  @override
  void initState() {
    super.initState();
    getPracticeCount();
  }

  Future<void> getPracticeCount() async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onGetMockPracticeCountApiCall(
        widget.testExamPaper?.exitUserExamId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<TestCategoryStore>(context);
    final bool isDesktop = Platform.isWindows || Platform.isMacOS;
    final bool isMobile = Platform.isAndroid || Platform.isIOS;

    return Container(
      constraints: isDesktop
          ? const BoxConstraints(maxWidth: 520)
          : BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: isDesktop
            ? AppTokens.radius20
            : const BorderRadius.vertical(top: Radius.circular(AppTokens.r20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isMobile)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.s12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTokens.border(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                AppTokens.s20,
                AppTokens.s20,
                AppTokens.s8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Practice Mode',
                    style: AppTokens.titleMd(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTokens.s4),
                  Text(
                    'Select any one of the options',
                    style: AppTokens.body(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
              child: Observer(builder: (_) {
                final data = store.getMockPracticeCountData.value;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _CountPill(
                            label: 'Answered',
                            value: (data?.attempted ?? 0).toString(),
                            tone: _PillTone.accent,
                          ),
                        ),
                        const SizedBox(width: AppTokens.s12),
                        Expanded(
                          child: _CountPill(
                            label: 'Unanswered',
                            value: (data?.notVisited ?? 0).toString(),
                            tone: _PillTone.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.s12),
                    Row(
                      children: [
                        Expanded(
                          child: _CountPill(
                            label: 'Correct',
                            value: (data?.correctAnswers ?? 0).toString(),
                            tone: _PillTone.success,
                          ),
                        ),
                        const SizedBox(width: AppTokens.s12),
                        Expanded(
                          child: _CountPill(
                            label: 'Incorrect',
                            value: (data?.incorrectAnswers ?? 0).toString(),
                            tone: _PillTone.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: AppTokens.s20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
              child: Column(
                children: List.generate(
                  questions.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.s12),
                    child: _OptionCard(
                      label: questions[index],
                      selected: currentIndex == index,
                      onTap: () => setState(() => currentIndex = index),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            Observer(builder: (_) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s20,
                  AppTokens.s12,
                  AppTokens.s20,
                  AppTokens.s20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SheetBtn(
                        label: 'Cancel',
                        primary: false,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: _SheetBtn(
                        label: 'Next',
                        primary: true,
                        loading: store.isLoading,
                        enabled: currentIndex != null,
                        onTap: () async {
                          if (currentIndex == 0) {
                            await _startMasterExamApiCall(store,
                                widget.testExamPaper, widget.isPractice);
                          } else if (currentIndex == 1) {
                            await _startAnsweredMasterExamApiCall(
                                store,
                                widget.testExamPaper,
                                widget.isPractice,
                                'Answered');
                          } else if (currentIndex == 2) {
                            await _startUnAnsweredMasterExamApiCall(
                                store,
                                widget.testExamPaper,
                                widget.isPractice,
                                'Unanswered');
                          } else {
                            BottomToast.showBottomToastOverlay(
                              context: context,
                              errorMessage: "Please selected one option",
                              backgroundColor:
                                  Theme.of(context).primaryColor,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  //  Preserved API helpers
  // --------------------------------------------------------------
  Future<void> _startExamApiCall(TestCategoryStore store,
      TestExamPaperListModel? testExamPaper, bool? isPractice) async {
    String examId = testExamPaper?.examId ?? "";
    DateTime now = DateTime.now();
    String startTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(now);
    String timeDuration = testExamPaper?.timeDuration ?? "";
    List<String> timeParts = timeDuration.split(":");
    Duration duration = Duration(
      hours: int.parse(timeParts[0]),
      minutes: int.parse(timeParts[1]),
      seconds: int.parse(timeParts[2]),
    );
    DateTime startDateTime = DateTime.parse(startTime);
    DateTime endDateTime = startDateTime.add(duration);
    String endTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(endDateTime);
    await store
        .onGetExamPaperDataApiCall(widget.testExamPaper?.examId ?? "")
        .then((_) async {
      widget.testExamPaper?.test = store.examPaperData.map((examPaperData) {
        return TestData(
          questionImg: examPaperData?.questionImg,
          explanationImg: examPaperData?.explanationImg,
          sId: examPaperData?.sId,
          examId: examPaperData?.examId,
          questionText: examPaperData?.questionText,
          correctOption: examPaperData?.correctOption,
          explanation: examPaperData?.explanation,
          selectedOption: examPaperData?.selectedOption,
          created_at: examPaperData?.created_at,
          updated_at: examPaperData?.updated_at,
          id: examPaperData?.id,
          optionsData: examPaperData?.optionVal?.map((option) {
            return Options(
              answerImg: option.answerImg,
              answerTitle: option.answerTitle,
              sId: option.sId,
              value: option.value,
            );
          }).toList(),
          questionNumber: examPaperData?.questionNumber,
          statusColor: examPaperData?.statusColor,
          txtColor: examPaperData?.txtColor,
          bookmarks: examPaperData?.bookmarks,
        );
      }).toList();
    });
    await store.startCreateExam(examId, startTime, endTime, isPractice, "", "");
    String? userExamId = store.startExam.value?.id;
    bool? isPracticeExam = store.startExam.value?.isPractice;
    if (widget.testExamPaper?.test?.isNotEmpty ?? false) {
      if (isPractice == false) {
        if (store.startExam.value?.err?.message == null) {
          Navigator.of(context).pushNamed(Routes.testExams, arguments: {
            'testData': widget.testExamPaper,
            'userexamId': userExamId,
            'isPracticeExam': isPracticeExam,
            'id': widget.id,
            'type': widget.type
          });
        } else {
          BottomToast.showBottomToastOverlay(
            context: context,
            errorMessage: store.startExam.value?.err?.message ?? "",
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      } else {
        if (store.startExam.value?.err?.message == null) {
          Navigator.of(context)
              .pushNamed(Routes.practiceMasterTestExams, arguments: {
            'testData': widget.testExamPaper,
            'userexamId': userExamId,
            'isPracticeExam': isPracticeExam,
            'id': widget.id,
            'type': widget.type
          });
        } else {
          BottomToast.showBottomToastOverlay(
            context: context,
            errorMessage: store.startExam.value?.err?.message ?? "",
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      }
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "Exam Paper Not Found!",
        backgroundColor: ThemeManager.redAlert,
      );
    }
  }

  Future<void> _startMasterExamApiCall(TestCategoryStore store,
      TestExamPaperListModel? testExamPaper, isPractice) async {
    String examId = testExamPaper?.examId ?? "";
    DateTime now = DateTime.now();
    String startTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(now);
    String timeDuration = testExamPaper?.timeDuration ?? "";
    List<String> timeParts = timeDuration.split(":");
    Duration duration = Duration(
      hours: int.parse(timeParts[0]),
      minutes: int.parse(timeParts[1]),
      seconds: int.parse(timeParts[2]),
    );
    DateTime startDateTime = DateTime.parse(startTime);
    DateTime endDateTime = startDateTime.add(duration);
    String endTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(endDateTime);
    await store
        .onGetPracticeMasterExamPaperDataApiCall(
            widget.testExamPaper?.examId ?? "")
        .then((_) async {
      widget.testExamPaper?.test =
          store.materExamPaperData.map((examPaperData) {
        return TestData(
          questionImg: examPaperData?.questionImg,
          explanationImg: examPaperData?.explanationImg,
          sId: examPaperData?.sId,
          examId: examPaperData?.examId,
          questionText: examPaperData?.questionText,
          correctOption: examPaperData?.correctOption,
          correctPercentage: examPaperData?.correctPercentage,
          explanation: examPaperData?.explanation,
          created_at: examPaperData?.created_at,
          updated_at: examPaperData?.updated_at,
          id: examPaperData?.id,
          optionsData: examPaperData?.optionVal?.map((option) {
            return Options(
                answerImg: option.answerImg,
                answerTitle: option.answerTitle,
                sId: option.sId,
                value: option.value,
                percentage: option.percentage);
          }).toList(),
          questionNumber: examPaperData?.questionNumber,
          statusColor: examPaperData?.statusColor,
          txtColor: examPaperData?.txtColor,
          bookmarks: examPaperData?.bookmarks,
        );
      }).toList();
    });
    await store.startCreateMaterExam(examId, startTime, endTime, isPractice);
    String? userExamId = store.startMasterExam.value?.id;
    bool? isPracticeExam = store.startMasterExam.value?.isPractice;
    if (widget.testExamPaper?.test?.isNotEmpty ?? false) {
      if (isPractice == false) {
        if (store.startMasterExam.value?.err?.message == null) {
          Navigator.of(context).pushNamed(Routes.testMasterExams, arguments: {
            'testData': widget.testExamPaper,
            'userexamId': userExamId,
            'isPracticeExam': isPracticeExam,
            'id': widget.id,
            'type': widget.type
          });
        } else {
          BottomToast.showBottomToastOverlay(
            context: context,
            errorMessage: store.startMasterExam.value?.err?.message ?? "",
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      } else {
        if (store.startExam.value?.err?.message == null) {
          Navigator.of(context)
              .pushNamed(Routes.practiceMasterTestExams, arguments: {
            'testData': widget.testExamPaper,
            'userexamId': userExamId,
            'isPracticeExam': isPracticeExam,
            'id': widget.id,
            'type': widget.type
          });
        } else {
          BottomToast.showBottomToastOverlay(
            context: context,
            errorMessage: store.startExam.value?.err?.message ?? "",
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      }
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "Exam Paper Not Found!",
        backgroundColor: ThemeManager.redAlert,
      );
    }
  }

  Future<void> _startUnAnsweredMasterExamApiCall(
      TestCategoryStore store,
      TestExamPaperListModel? testExamPaper,
      bool? isPractice,
      String? type) async {
    String examId = testExamPaper?.examId ?? "";
    DateTime now = DateTime.now();
    String startTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(now);
    String timeDuration = testExamPaper?.timeDuration ?? "";
    List<String> timeParts = timeDuration.split(":");
    Duration duration = Duration(
      hours: int.parse(timeParts[0]),
      minutes: int.parse(timeParts[1]),
      seconds: int.parse(timeParts[2]),
    );
    DateTime startDateTime = DateTime.parse(startTime);
    DateTime endDateTime = startDateTime.add(duration);
    String endTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(endDateTime);
    await store
        .onGetPracticeMockExamPaperDataApiCall(
            widget.testExamPaper?.exitUserExamId ?? "", type!)
        .then((_) async {
      widget.testExamPaper?.test =
          store.mockExamPracticePaperData.map((examPaperData) {
        return TestData(
          questionImg: examPaperData?.questionImg,
          explanationImg: examPaperData?.explanationImg,
          sId: examPaperData?.sId,
          examId: examPaperData?.examId,
          questionText: examPaperData?.questionText,
          correctOption: examPaperData?.correctOption,
          correctPercentage: examPaperData?.correctPercentage,
          explanation: examPaperData?.explanation,
          created_at: examPaperData?.created_at,
          updated_at: examPaperData?.updated_at,
          id: examPaperData?.id,
          optionsData: examPaperData?.optionVal?.map((option) {
            return Options(
                answerImg: option.answerImg,
                answerTitle: option.answerTitle,
                sId: option.sId,
                value: option.value,
                percentage: option.percentage);
          }).toList(),
          questionNumber: examPaperData?.questionNumber,
          statusColor: examPaperData?.statusColor,
          txtColor: examPaperData?.txtColor,
          bookmarks: examPaperData?.bookmarks,
        );
      }).toList();
    });
    // await store.startCreateExam(examId, startTime, endTime, isPractice);
    // String? userExamId = store.startExam.value?.id;
    // bool? isPracticeExam = store.startExam.value?.isPractice;
    if (widget.testExamPaper?.test?.isNotEmpty ?? false) {
      Navigator.of(context)
          .pushNamed(Routes.practiceMasterTestExams, arguments: {
        'testData': widget.testExamPaper,
        'userexamId': widget.testExamPaper?.exitUserExamId,
        'isPracticeExam': true,
        'id': widget.id,
        'type': widget.type
      });
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "Exam Paper Not Found!",
        backgroundColor: ThemeManager.redAlert,
      );
    }
  }

  Future<void> _startAnsweredMasterExamApiCall(
      TestCategoryStore store,
      TestExamPaperListModel? testExamPaper,
      bool? isPractice,
      String? type) async {
    String examId = testExamPaper?.examId ?? "";
    DateTime now = DateTime.now();
    String startTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(now);
    String timeDuration = testExamPaper?.timeDuration ?? "";
    List<String> timeParts = timeDuration.split(":");
    Duration duration = Duration(
      hours: int.parse(timeParts[0]),
      minutes: int.parse(timeParts[1]),
      seconds: int.parse(timeParts[2]),
    );
    DateTime startDateTime = DateTime.parse(startTime);
    DateTime endDateTime = startDateTime.add(duration);
    String endTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(endDateTime);
    await store
        .onGetPracticeMockExamPaperDataApiCall(
            widget.testExamPaper?.exitUserExamId ?? "", type!)
        .then((_) async {
      widget.testExamPaper?.test =
          store.mockExamPracticePaperData.map((examPaperData) {
        debugPrint("examPaperData?.isCorrect,:${examPaperData?.isCorrect}");
        return TestData(
          isCorrect: examPaperData?.isCorrect,
          questionImg: examPaperData?.questionImg,
          selectedOption: examPaperData?.selectedOption,
          explanationImg: examPaperData?.explanationImg,
          sId: examPaperData?.sId,
          examId: examPaperData?.examId,
          questionText: examPaperData?.questionText,
          correctOption: examPaperData?.correctOption,
          correctPercentage: examPaperData?.correctPercentage,
          explanation: examPaperData?.explanation,
          created_at: examPaperData?.created_at,
          updated_at: examPaperData?.updated_at,
          id: examPaperData?.id,
          optionsData: examPaperData?.optionVal?.map((option) {
            return Options(
                answerImg: option.answerImg,
                answerTitle: option.answerTitle,
                sId: option.sId,
                value: option.value,
                percentage: option.percentage);
          }).toList(),
          questionNumber: examPaperData?.questionNumber,
          statusColor: examPaperData?.statusColor,
          txtColor: examPaperData?.txtColor,
          bookmarks: examPaperData?.bookmarks,
        );
      }).toList();
    });
    // await store.startCreateExam(examId, startTime, endTime, isPractice);
    // String? userExamId = store.startExam.value?.id;
    // bool? isPracticeExam = store.startExam.value?.isPractice;
    if (widget.testExamPaper?.test?.isNotEmpty ?? false) {
      showModalBottomSheet<void>(
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return StartPracticeBottomSheet(
            store: store,
            testExamPaper: widget.testExamPaper,
            id: widget.id,
            type: widget.type,
            isPractice: widget.isPractice,
            userExamId: widget.testExamPaper?.exitUserExamId,
            isPracticeExam: true,
          );
        },
      );
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "Exam Paper Not Found!",
        backgroundColor: ThemeManager.redAlert,
      );
    }
  }
}

// ============================================================
//            StartPracticeBottomSheet (Answered branch)
// ============================================================

/// Second-stage practice sheet shown after the "Answered Questions" option is
/// picked. Preserves:
///   • Named constructor `StartPracticeBottomSheet({super.key, required store,
///     testExamPaper, id, type, isPractice, userExamId, isPracticeExam})`
///   • State: `queryController`, `questions = ["All", "Correct", "Incorrect"]`,
///     `currentIndex`
///   • Back → `Navigator.pop(context)`
///   • Start Practice → validates currentIndex==1 ⇒ correctAnswers>0 and
///     currentIndex==2 ⇒ incorrectAnswers>0 else toast; then pushes
///     `Routes.mockPracticeSolutionTestExams` with
///     `{testData, userexamId, isPracticeExam, id, type, isCorrect}`
class StartPracticeBottomSheet extends StatefulWidget {
  final TestCategoryStore store;
  final TestExamPaperListModel? testExamPaper;
  final String? id;
  final String? type;
  final bool? isPractice;
  final String? userExamId;
  final bool? isPracticeExam;
  const StartPracticeBottomSheet({
    super.key,
    required this.store,
    this.testExamPaper,
    this.id,
    this.type,
    this.isPractice,
    this.userExamId,
    this.isPracticeExam,
  });

  @override
  State<StartPracticeBottomSheet> createState() =>
      _StartPracticeBottomSheetState();
}

class _StartPracticeBottomSheetState extends State<StartPracticeBottomSheet> {
  TextEditingController queryController = TextEditingController();
  List<String> questions = ["All", "Correct", "Incorrect"];
  int? currentIndex;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Platform.isWindows || Platform.isMacOS;
    final bool isMobile = Platform.isAndroid || Platform.isIOS;

    return Container(
      constraints: isDesktop
          ? const BoxConstraints(maxWidth: 520)
          : BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: isDesktop
            ? AppTokens.radius20
            : const BorderRadius.vertical(top: Radius.circular(AppTokens.r20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isMobile)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.s12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTokens.border(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                AppTokens.s16,
                AppTokens.s20,
                AppTokens.s8,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      borderRadius: AppTokens.radius8,
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s8,
                          vertical: AppTokens.s4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 14,
                              color: AppTokens.accent(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Back',
                              style: AppTokens.titleSm(context).copyWith(
                                color: AppTokens.accent(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Practice Mode',
                    style: AppTokens.titleMd(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                0,
                AppTokens.s20,
                AppTokens.s12,
              ),
              child: Text(
                'Select any one of the options',
                style: AppTokens.body(context),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
              child: Builder(builder: (_) {
                final data = widget.store.getMockPracticeCountData.value;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _CountPill(
                            label: 'Answered',
                            value: (data?.attempted ?? 0).toString(),
                            tone: _PillTone.accent,
                          ),
                        ),
                        const SizedBox(width: AppTokens.s12),
                        Expanded(
                          child: _CountPill(
                            label: 'Unanswered',
                            value: (data?.notVisited ?? 0).toString(),
                            tone: _PillTone.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.s12),
                    Row(
                      children: [
                        Expanded(
                          child: _CountPill(
                            label: 'Correct',
                            value: (data?.correctAnswers ?? 0).toString(),
                            tone: _PillTone.success,
                          ),
                        ),
                        const SizedBox(width: AppTokens.s12),
                        Expanded(
                          child: _CountPill(
                            label: 'Incorrect',
                            value: (data?.incorrectAnswers ?? 0).toString(),
                            tone: _PillTone.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: AppTokens.s20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
              child: Column(
                children: List.generate(
                  questions.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.s12),
                    child: _OptionCard(
                      label: questions[index],
                      selected: currentIndex == index,
                      onTap: () => setState(() => currentIndex = index),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                AppTokens.s12,
                AppTokens.s20,
                AppTokens.s20,
              ),
              child: _SheetBtn(
                label: 'Start Practice',
                primary: true,
                loading: widget.store.isLoading,
                enabled: currentIndex != null,
                onTap: () async {
                  bool? isSelected;
                  if (currentIndex == 1) {
                    isSelected = true;
                    if (widget.store.getMockPracticeCountData.value
                            ?.correctAnswers ==
                        0) {
                      BottomToast.showBottomToastOverlay(
                        context: context,
                        errorMessage: "Correct answer is empty",
                        backgroundColor: Theme.of(context).primaryColor,
                      );
                      return;
                    }
                  } else if (currentIndex == 2) {
                    isSelected = false;
                    if (widget.store.getMockPracticeCountData.value
                            ?.incorrectAnswers ==
                        0) {
                      BottomToast.showBottomToastOverlay(
                        context: context,
                        errorMessage: "Incorrect answer is empty",
                        backgroundColor: Theme.of(context).primaryColor,
                      );
                      return;
                    }
                  }
                  Navigator.of(context).pushNamed(
                    Routes.mockPracticeSolutionTestExams,
                    arguments: {
                      'testData': widget.testExamPaper,
                      'userexamId': widget.userExamId,
                      'isPracticeExam': widget.isPracticeExam,
                      'id': widget.id,
                      'type': widget.type,
                      'isCorrect': isSelected,
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//                        Primitives
// ============================================================

enum _PillTone { accent, warning, success, danger }

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final _PillTone tone;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (tone) {
      case _PillTone.accent:
        bg = AppTokens.accentSoft(context);
        fg = AppTokens.accent(context);
        break;
      case _PillTone.warning:
        bg = AppTokens.warningSoft(context);
        fg = AppTokens.warning(context);
        break;
      case _PillTone.success:
        bg = AppTokens.successSoft(context);
        fg = AppTokens.success(context);
        break;
      case _PillTone.danger:
        bg = AppTokens.dangerSoft(context);
        fg = AppTokens.danger(context);
        break;
    }
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(64),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.caption(context).copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: fg,
              borderRadius: BorderRadius.circular(64),
            ),
            child: Text(
              value,
              style: AppTokens.caption(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
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
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [AppTokens.brand, AppTokens.brand2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : AppTokens.surface(context),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppTokens.border(context),
              width: 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTokens.brand.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(right: AppTokens.s8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? Colors.white
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? Colors.white
                        : AppTokens.borderStrong(context),
                    width: 1.4,
                  ),
                ),
                alignment: Alignment.center,
                child: selected
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTokens.brand,
                        ),
                      )
                    : null,
              ),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTokens.titleSm(context).copyWith(
                    color:
                        selected ? Colors.white : AppTokens.ink(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetBtn extends StatelessWidget {
  const _SheetBtn({
    required this.label,
    required this.onTap,
    this.primary = true,
    this.loading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!primary) {
      return Material(
        color: Colors.transparent,
        borderRadius: AppTokens.radius12,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.surface2(context),
              borderRadius: AppTokens.radius12,
              border: Border.all(color: AppTokens.border(context)),
            ),
            child: Text(
              label,
              style: AppTokens.titleSm(context)
                  .copyWith(color: AppTokens.ink2(context)),
            ),
          ),
        ),
      );
    }

    final bool active = enabled && !loading;
    return Opacity(
      opacity: active ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTokens.radius12,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: active ? onTap : null,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppTokens.radius12,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppTokens.brand.withOpacity(0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: SizedBox(
              height: 48,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : Text(
                        label,
                        style: AppTokens.titleSm(context)
                            .copyWith(color: Colors.white),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
