import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../models/test_exampaper_list_model.dart';
import '../new-bookmark-flow/store/new_bookmark_store.dart';
import '../new_exam_component/widget/loading_box.dart';
import '../test/store/test_category_store.dart';
import 'bottom_toast.dart';
import 'package:shusruta_lms/models/practice_count_model.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart' as test;

/// PracticeBottomSheet — opens from a test card to let the learner pick
/// which cohort of questions they want to practice (all / answered /
/// unanswered / bookmarked). Public surface preserved exactly:
///   • class [PracticeBottomSheet] + const positional constructor
///     `(BuildContext, TestExamPaperListModel?, String? id, String? type,
///       bool? isPractice, String? time, String? name, bool? isAll,
///       String? mainId, bool? isCustom, {Key? key})`
///   • fields: testExamPaper, id, mainId, type, time, name, isPractice,
///     isAll, isCustom
///   • state lifecycle (initState → getPracticeCount) and state fields
///     currentIndex / selectedIndex / questions / queryController
///   • three private flows `_startExamApiCall`, `_startAnsweredExamApiCall`,
///     `_startUnAnsweredExamApiCall` preserved byte-for-byte
///   • BookmarkNewStore.ongetBookmarkMacqQuestionsListApiCall /
///     ongetReBookmarkMacqQuestionsListApiCall /
///     onCreateCustomeExamApiCall wiring
///   • routes target: Routes.practiceTestExams / Routes.testExams /
///     Routes.practiceSolutionTestExams
class PracticeBottomSheet extends StatefulWidget {
  final TestExamPaperListModel? testExamPaper;
  final String? id;
  final String? mainId;
  final String? type;
  final String? time;
  final String? name;
  final bool? isPractice;
  final bool? isAll;
  final bool? isCustom;
  const PracticeBottomSheet(
    BuildContext context,
    this.testExamPaper,
    this.id,
    this.type,
    this.isPractice,
    this.time,
    this.name,
    this.isAll,
    this.mainId,
    this.isCustom, {
    super.key,
  });

  @override
  State<PracticeBottomSheet> createState() => _PracticeBottomSheetState();
}

class _PracticeBottomSheetState extends State<PracticeBottomSheet> {
  // ignore: unused_field
  final TextEditingController queryController = TextEditingController();
  // ignore: unused_field
  final List<String> questions = [
    "All Questions",
    "Answered Questions",
    "Unanswered Questions",
  ];
  int? currentIndex;
  // ignore: unused_field
  int selectedIndex = -1;

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    getPracticeCount();
  }

  Future<void> getPracticeCount() async {
    debugPrint('${widget.type}');
    debugPrint('${widget.isCustom}');
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onGetPracticeCountApiCall(
      widget.type == "McqBookmark" ||
              widget.type == "MockBookmark" ||
              (widget.isCustom ?? false)
          ? widget.id!
          : widget.testExamPaper?.exitUserExamId ?? '',
      widget.type ?? "",
      widget.isCustom ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<TestCategoryStore>(context);
    return FractionallySizedBox(
      child: FittedBox(
        fit: BoxFit.fitWidth,
        child: Container(
          constraints: _isDesktop
              ? const BoxConstraints(maxWidth: 560)
              : null,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: _isDesktop
                ? BorderRadius.circular(AppTokens.r20)
                : const BorderRadius.vertical(
                    top: Radius.circular(AppTokens.r20),
                  ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppTokens.s20,
              _isDesktop ? AppTokens.s24 : AppTokens.s12,
              AppTokens.s20,
              AppTokens.s20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isDesktop) ...[
                  _SheetGrabber(),
                  const SizedBox(height: AppTokens.s20),
                ],
                Text(
                  'Practice Mode',
                  style: AppTokens.titleLg(context)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  'Select any one of the options',
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.ink2(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                Observer(builder: (_) {
                  if (store.isLoading) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppTokens.s24),
                      child: CupertinoActivityIndicator(
                        color: AppTokens.accent(context),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      _OptionTile(
                        label: 'All Questions',
                        value: ((store.getPracticeCountData.value?.attempted ??
                                    0) +
                                (store.getPracticeCountData.value?.notVisited ??
                                    0))
                            .toString(),
                        valueColor: AppTokens.ink(context),
                        selected: currentIndex == 0,
                        onTap: () => _select(0),
                      ),
                      const SizedBox(height: AppTokens.s8),
                      _OptionTile(
                        label: 'Answered Questions',
                        value:
                            '${store.getPracticeCountData.value?.attempted ?? 0}',
                        valueColor: Colors.blue,
                        selected: currentIndex == 1,
                        onTap: () => _select(1),
                      ),
                      const SizedBox(height: AppTokens.s8),
                      _OptionTile(
                        label: 'Unanswered Questions',
                        value:
                            '${store.getPracticeCountData.value?.notVisited ?? 0}',
                        valueColor: Colors.red,
                        selected: currentIndex == 2,
                        onTap: () => _select(2),
                      ),
                      if (widget.testExamPaper != null) ...[
                        const SizedBox(height: AppTokens.s8),
                        _OptionTile(
                          label: 'Bookmarked Questions',
                          value:
                              '${store.getPracticeCountData.value?.bookmarkCount ?? 0}',
                          valueColor: Colors.orange,
                          selected: currentIndex == 3,
                          onTap: () => _select(3),
                        ),
                      ],
                    ],
                  );
                }),
                const SizedBox(height: AppTokens.s20),
                Observer(builder: (_) {
                  if (_isDesktop) {
                    return Row(
                      children: [
                        Expanded(
                          child: _GhostCta(
                            label: 'Cancel',
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: AppTokens.s12),
                        Expanded(
                          child: _PrimaryCta(
                            label: 'Next',
                            enabled: currentIndex != null,
                            loading: store.isLoading,
                            onTap: _onNextTap,
                          ),
                        ),
                      ],
                    );
                  }
                  return _PrimaryCta(
                    label: 'Next',
                    enabled: currentIndex != null,
                    loading: store.isLoading,
                    onTap: _onNextTap,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _select(int index) {
    setState(() => currentIndex = index);
  }

  Future<void> _onNextTap() async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    if (currentIndex == 0) {
      if (widget.type != "McqBookmark" &&
          widget.type != "MockBookmark" &&
          widget.type != "Custom") {
        await _startExamApiCall(
            store, widget.testExamPaper, widget.isPractice);
      } else {
        await _launchBookmarkedExam(
          cohort: "All Questions",
          useFallbackMain: true,
          popCount: 1,
        );
      }
    } else if (currentIndex == 1) {
      if (widget.type != "McqBookmark" &&
          widget.type != "MockBookmark" &&
          widget.type != "Custom") {
        await _startAnsweredExamApiCall(
            store, widget.testExamPaper, widget.isPractice, 'Answered');
      } else {
        await _launchRebookmarkedExam(
          cohort: 'Answered',
          popCount: 2,
          withCustomFlag: false,
        );
      }
    } else if (currentIndex == 2) {
      if (widget.type != "McqBookmark" &&
          widget.type != "MockBookmark" &&
          widget.type != "Custom") {
        await _startUnAnsweredExamApiCall(
            store, widget.testExamPaper, widget.isPractice, 'Unanswered');
      } else {
        await _launchRebookmarkedExam(
          cohort: 'Unanswered',
          popCount: 2,
          withCustomFlag: false,
        );
      }
    } else if (currentIndex == 3) {
      await _startUnAnsweredExamApiCall(
          store, widget.testExamPaper, widget.isPractice, 'Bookmark');
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "Please selected one option",
        backgroundColor: Theme.of(context).primaryColor,
      );
    }
  }

  Future<void> _launchBookmarkedExam({
    required String cohort,
    required bool useFallbackMain,
    required int popCount,
  }) async {
    final bookmarkStore =
        Provider.of<BookmarkNewStore>(context, listen: false);
    final List<test.TestData> dataList =
        await bookmarkStore.ongetBookmarkMacqQuestionsListApiCall(
      cohort,
      useFallbackMain && widget.mainId!.isEmpty
          ? "67c70853be4a8ac3c2761910"
          : widget.mainId!,
      widget.isAll!,
      widget.type == "MockBookmark",
      widget.isCustom!,
    );
    final now = DateTime.now();
    final List<String> parts = widget.time!.split(":");
    final int hours = int.parse(parts[0]);
    final int minutes = int.parse(parts[1]);
    final int totalMinutes = (hours * 60) + minutes;
    final endTime = now.add(Duration(minutes: totalMinutes));
    // ignore: use_build_context_synchronously
    final Map<String, dynamic>? data =
        await bookmarkStore.onCreateCustomeExamApiCall(widget.type!, {
      "customTest_id": useFallbackMain && widget.mainId!.isEmpty
          ? "67c70853be4a8ac3c2761910"
          : widget.mainId!,
      "start_time": now.toIso8601String(),
      "end_time": endTime.toIso8601String(),
      "isAllQSolve": widget.isAll,
      'isPractice': true,
    });
    if (!mounted) return;
    final store2 = Provider.of<TestCategoryStore>(context, listen: false);
    store2.qutestionList.value = dataList;
    store2.type.value = widget.type!;
    for (int i = 0; i < popCount; i++) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushNamed(Routes.practiceTestExams, arguments: {
      'testData': test.TestExamPaperListModel(
          examName: widget.name, test: dataList),
      'userexamId': data!['_id'],
      'isPracticeExam': true,
      'id': widget.id,
      'isAll': widget.isAll,
      'mainId': widget.mainId,
      'isCustom': widget.isCustom,
      'type': widget.type,
    });
  }

  Future<void> _launchRebookmarkedExam({
    required String cohort,
    required int popCount,
    // ignore: unused_element
    required bool withCustomFlag,
  }) async {
    showLoadingDialog(context);
    final bookmarkStore =
        Provider.of<BookmarkNewStore>(context, listen: false);
    final List<test.TestData> dataList =
        await bookmarkStore.ongetReBookmarkMacqQuestionsListApiCall(
      cohort,
      widget.type ?? "",
      widget.id!,
      widget.isAll ?? false,
      widget.isCustom ?? false,
    );
    final now = DateTime.now();
    final List<String> parts = widget.time!.split(":");
    final int hours = int.parse(parts[0]);
    final int minutes = int.parse(parts[1]);
    final int totalMinutes = (hours * 60) + minutes;
    final endTime = now.add(Duration(minutes: totalMinutes));
    // ignore: use_build_context_synchronously
    final Map<String, dynamic>? data =
        await bookmarkStore.onCreateCustomeExamApiCall(widget.type!, {
      "customTest_id": widget.id,
      "start_time": now.toIso8601String(),
      "end_time": endTime.toIso8601String(),
      "isAllQSolve": widget.isAll,
      'isPractice': true,
    });
    if (!mounted) return;
    final store2 = Provider.of<TestCategoryStore>(context, listen: false);
    store2.qutestionList.value = dataList;
    store2.type.value = widget.type!;
    for (int i = 0; i < popCount; i++) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushNamed(Routes.practiceTestExams, arguments: {
      'testData': test.TestExamPaperListModel(
          examName: widget.name, test: dataList),
      'userexamId': data!['_id'],
      'isPracticeExam': true,
      'id': widget.id,
      'isAll': widget.isAll,
      'mainId': widget.mainId,
      'isCustom': widget.isCustom,
      'type': widget.type,
    });
  }

  // --- Preserved original flows, unchanged semantics -----------------------

  Future<void> _startExamApiCall(TestCategoryStore store,
      TestExamPaperListModel? testExamPaper, bool? isPractice) async {
    // ignore: unused_local_variable
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
    final store2 = Provider.of<TestCategoryStore>(context, listen: false);
    await store
        .onPracticeExamPaperDataApiCall(widget.testExamPaper?.examId ?? "")
        .then((_) async {
      store2.qutestionList.value = store.examPaperData.map((examPaperData) {
        return TestData(
          questionImg: examPaperData?.questionImg,
          explanationImg: examPaperData?.explanationImg,
          sId: examPaperData?.sId,
          examId: examPaperData?.examId,
          questionText: examPaperData?.questionText,
          correctOption: examPaperData?.correctOption,
          correctPercentage: examPaperData?.correctPercentage,
          selectedOption: examPaperData?.selectedOption,
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
    widget.testExamPaper?.test = store2.qutestionList.value;
    String? userExamId = store.startExam.value?.id;
    String id = await store.startCreateExam(
        widget.testExamPaper?.examId ?? "",
        startTime,
        endTime,
        isPractice,
        "",
        userExamId);
    String? userExamId2 = store.startExam.value?.id;
    bool? isPracticeExam = store.startExam.value?.isPractice;
    if (!mounted) return;
    if (widget.testExamPaper?.test?.isNotEmpty ?? false) {
      if (isPractice == false) {
        if (store.startExam.value?.err?.message == null) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pushNamed(Routes.testExams, arguments: {
            'testData': widget.testExamPaper,
            'userexamId': userExamId2,
            'isPracticeExam': isPracticeExam,
            'id': widget.id,
            'type': widget.type,
          });
        } else {
          BottomToast.showBottomToastOverlay(
            // ignore: use_build_context_synchronously
            context: context,
            errorMessage: store.startExam.value?.err?.message ?? "",
            // ignore: use_build_context_synchronously
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      } else {
        if (store.startExam.value?.err?.message == null) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pushNamed(Routes.practiceTestExams, arguments: {
            'testData': widget.testExamPaper,
            'userexamId': id,
            'isPracticeExam': isPracticeExam,
            'id': widget.id,
            'type': widget.type,
          });
        } else {
          BottomToast.showBottomToastOverlay(
            // ignore: use_build_context_synchronously
            context: context,
            errorMessage: store.startExam.value?.err?.message ?? "",
            // ignore: use_build_context_synchronously
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      }
    } else {
      BottomToast.showBottomToastOverlay(
        // ignore: use_build_context_synchronously
        context: context,
        errorMessage: "Exam Paper Not Found!",
        backgroundColor: ThemeManager.redAlert,
      );
    }
  }

  Future<void> _startUnAnsweredExamApiCall(
      TestCategoryStore store,
      TestExamPaperListModel? testExamPaper,
      bool? isPractice,
      String? type) async {
    await store.disposeStore();
    // ignore: unused_local_variable
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
    // ignore: unused_local_variable
    String endTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(endDateTime);
    await store
        .onGetPracticeExamPaperDataApiCall(
            widget.testExamPaper?.exitUserExamId ?? "", type!)
        .then((_) async {
      store.qutestionList.value =
          store.examPracticePaperData.map((examPaperData) {
        return TestData(
          questionImg: examPaperData?.questionImg,
          explanationImg: examPaperData?.explanationImg,
          sId: examPaperData?.sId,
          examId: examPaperData?.examId,
          questionText: examPaperData?.questionText,
          correctOption: examPaperData?.correctOption,
          selectedOption: examPaperData?.selectedOption,
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
    widget.testExamPaper?.test = store.qutestionList.value;
    if (!mounted) return;
    if (store.qutestionList.value.isNotEmpty) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushNamed(Routes.practiceTestExams, arguments: {
        'testData': widget.testExamPaper,
        'userexamId': widget.testExamPaper!.exitUserExamId!,
        'isPracticeExam': true,
        'id': widget.id,
        'type': widget.type,
      });
    } else {
      BottomToast.showBottomToastOverlay(
        // ignore: use_build_context_synchronously
        context: context,
        errorMessage: "Exam Paper Not Found!",
        backgroundColor: ThemeManager.redAlert,
      );
    }
  }

  Future<void> _startAnsweredExamApiCall(
      TestCategoryStore store,
      TestExamPaperListModel? testExamPaper,
      // ignore: unused_element
      bool? isPractice,
      String? type) async {
    // ignore: unused_local_variable
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
    // ignore: unused_local_variable
    String endTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(endDateTime);
    await store
        .onGetPracticeExamPaperDataApiCall(
            widget.testExamPaper?.exitUserExamId ?? "", type!)
        .then((_) async {
      widget.testExamPaper?.test =
          store.examPracticePaperData.map((examPaperData) {
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
    if (!mounted) return;
    if (widget.testExamPaper?.test?.isNotEmpty ?? false) {
      // ignore: use_build_context_synchronously
      showModalBottomSheet<void>(
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return StartPracticeBottomSheet(
            count: store.getPracticeCountData.value!,
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
        // ignore: use_build_context_synchronously
        context: context,
        errorMessage: "Exam Paper Not Found!",
        backgroundColor: ThemeManager.redAlert,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Shared primitives
// ---------------------------------------------------------------------------

class _SheetGrabber extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: AppTokens.border(context),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s16,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppTokens.accentSoft(context)
                : AppTokens.surface2(context),
            border: Border.all(
              color: selected
                  ? AppTokens.accent(context)
                  : AppTokens.border(context),
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTokens.body(context).copyWith(
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Text(
                value,
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool loading;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled && !loading ? () => onTap() : null,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    colors: [AppTokens.brand, AppTokens.brand2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: enabled ? null : AppTokens.surface3(context),
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: AppTokens.body(context).copyWith(
                    color: enabled
                        ? Colors.white
                        : AppTokens.ink2(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class _GhostCta extends StatelessWidget {
  const _GhostCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.surface2(context),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(color: AppTokens.border(context)),
          ),
          child: Text(
            label,
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.ink2(context),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// StartPracticeBottomSheet — opens after "Answered Questions" to pick
// between All / Correct / Incorrect before pushing to the solution viewer.
// ---------------------------------------------------------------------------

class StartPracticeBottomSheet extends StatefulWidget {
  final TestCategoryStore store;
  final TestExamPaperListModel? testExamPaper;
  final String? id;
  final PracticeCountModel count;
  final String? type;
  final bool? isPractice;
  final String? userExamId;
  final bool? isPracticeExam;
  const StartPracticeBottomSheet({
    super.key,
    required this.store,
    this.testExamPaper,
    this.id,
    required this.count,
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
  // ignore: unused_field
  final TextEditingController queryController = TextEditingController();
  final List<String> questions = const ["All", "Correct", "Incorrect"];
  int? currentIndex;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      child: FittedBox(
        fit: BoxFit.fitWidth,
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTokens.r20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s20,
              AppTokens.s12,
              AppTokens.s20,
              AppTokens.s20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetGrabber(),
                const SizedBox(height: AppTokens.s20),
                Text(
                  'Answered Question',
                  style: AppTokens.titleLg(context)
                      .copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  'Select any one of the options',
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.ink2(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                Column(
                  children: List.generate(questions.length, (index) {
                    final label = questions[index];
                    final value = label == "All"
                        ? (widget.count.attempted ?? 0).toString()
                        : label == "Correct"
                            ? (widget.count.correctAnswers ?? 0).toString()
                            : (widget.count.incorrectAnswers ?? 0).toString();
                    final valueColor = label == "All"
                        ? AppTokens.ink(context)
                        : label == "Correct"
                            ? Colors.green
                            : Colors.orange;
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppTokens.s8),
                      child: _OptionTile(
                        label: label,
                        value: value,
                        valueColor: valueColor,
                        selected: currentIndex == index,
                        onTap: () =>
                            setState(() => currentIndex = index),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppTokens.s16),
                Observer(builder: (_) {
                  return _PrimaryCta(
                    label: 'Start Practice',
                    enabled: currentIndex != null,
                    loading: widget.store.isLoading,
                    onTap: () async {
                      bool? isSelected;
                      if (currentIndex == 1) {
                        isSelected = true;
                        if (widget.store.getPracticeCountData.value
                                ?.correctAnswers ==
                            0) {
                          BottomToast.showBottomToastOverlay(
                            context: context,
                            errorMessage: "Correct answer is empty",
                            backgroundColor:
                                Theme.of(context).primaryColor,
                          );
                          return;
                        }
                      } else if (currentIndex == 2) {
                        isSelected = false;
                        if (widget.store.getPracticeCountData.value
                                ?.incorrectAnswers ==
                            0) {
                          BottomToast.showBottomToastOverlay(
                            context: context,
                            errorMessage: "Incorrect answer is empty",
                            backgroundColor:
                                Theme.of(context).primaryColor,
                          );
                          return;
                        }
                      }
                      Navigator.of(context).pushNamed(
                        Routes.practiceSolutionTestExams,
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
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
