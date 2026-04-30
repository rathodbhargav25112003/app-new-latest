// ignore: unused_import, unnecessary_import
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// ignore: unused_import, unnecessary_import
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import 'package:shusruta_lms/modules/videolectures/store/video_category_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import
import '../../helpers/styles.dart';
import '../../models/get_all_my_custom_test_model.dart';
// ignore: unused_import
import '../reports/store/report_by_category_store.dart';
import '../test/store/test_category_store.dart';
import '../widgets/bottom_toast.dart';

/// CustomTestPracticeBottomSheet — modal shown after the learner taps a
/// saved custom test whose `isExit == true`, letting them pick one of
/// three practice modes (All / Answered / Unanswered). Surface contract
/// preserved:
///   • const constructor positional `(BuildContext, Data?, bool?,
///     {Key? key})` — the first arg is accepted for legacy parity, not
///     consumed (original code did the same)
///   • initState fires TestCategoryStore.onGetCustomPracticeCountApiCall
///     with `exitUserExamId`
///   • selecting an option triggers one of the three dispatch helpers:
///     _startExamApiCall / _startAnsweredExamApiCall /
///     _startUnAnsweredExamApiCall — each preserved byte-for-byte in
///     how they call the store, build `TestData` from option payloads
///     and route to testExams / practiceCustomTestExamScreen /
///     practiceSolutionCustomTestExams
class CustomTestPracticeBottomSheet extends StatefulWidget {
  final Data? testExamPaper;
  final bool? isPractice;
  // ignore: use_super_parameters, avoid_unused_constructor_parameters
  const CustomTestPracticeBottomSheet(
      BuildContext context, this.testExamPaper, this.isPractice,
      {Key? key})
      : super(key: key);

  @override
  State<CustomTestPracticeBottomSheet> createState() =>
      _CustomTestPracticeBottomSheetState();
}

class _CustomTestPracticeBottomSheetState
    extends State<CustomTestPracticeBottomSheet> {
  // ignore: unused_field
  TextEditingController queryController = TextEditingController();
  List<String> questions = [
    'All Questions',
    'Answered Questions',
    'Unanswered Questions',
  ];
  int? currentIndex;

  @override
  void initState() {
    super.initState();
    getPracticeCount();
  }

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  Future<void> getPracticeCount() async {
    if (!mounted) return;
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onGetCustomPracticeCountApiCall(
        widget.testExamPaper?.exitUserExamId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<TestCategoryStore>(context);
    return _SheetShell(
      title: 'Practice Mode',
      subtitle: 'Select any one of the options',
      child: Column(
        children: [
          Observer(
            builder: (_) => _StatsGrid(
              answered:
                  store.getCustomPracticeCountData.value?.attempted ?? 0,
              unanswered: store.getCustomPracticeCountData.value
                      ?.notVisited ??
                  0,
              correct: store
                      .getCustomPracticeCountData.value?.correctAnswers ??
                  0,
              incorrect: store.getCustomPracticeCountData.value
                      ?.incorrectAnswers ??
                  0,
            ),
          ),
          const SizedBox(height: AppTokens.s20),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTokens.s20),
            child: Column(
              children: List.generate(
                questions.length,
                (index) => _ChoiceRow(
                  icon: _iconFor(index),
                  label: questions[index],
                  selected: currentIndex == index,
                  onTap: () => setState(() => currentIndex = index),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Observer(
            builder: (_) => _CtaButton(
              label: 'Next',
              enabled: currentIndex != null,
              loading: store.isLoading,
              onTap: () async {
                if (currentIndex == 0) {
                  await _startExamApiCall(
                      store, widget.testExamPaper, widget.isPractice);
                } else if (currentIndex == 1) {
                  await _startAnsweredExamApiCall(store,
                      widget.testExamPaper, widget.isPractice, 'Answered');
                } else if (currentIndex == 2) {
                  await _startUnAnsweredExamApiCall(
                      store,
                      widget.testExamPaper,
                      widget.isPractice,
                      'Unanswered');
                } else {
                  BottomToast.showBottomToastOverlay(
                    context: context,
                    errorMessage: 'Please selected one option',
                    backgroundColor: Theme.of(context).primaryColor,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(int index) {
    switch (index) {
      case 0:
        return Icons.all_inclusive_rounded;
      case 1:
        return Icons.check_circle_outline_rounded;
      case 2:
        return Icons.radio_button_unchecked_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  Future<void> _startExamApiCall(TestCategoryStore store,
      Data? testExamPaper, bool? isPractice) async {
    final String examId = testExamPaper?.sId ?? '';
    final DateTime now = DateTime.now();
    final String startTime =
        DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(now);
    final String timeDuration = testExamPaper?.timeDuration ?? '';
    final List<String> timeParts = timeDuration.split(':');
    final Duration duration = Duration(
      hours: int.parse(timeParts[0]),
      minutes: int.parse(timeParts[1]),
      seconds: int.parse(timeParts[2]),
    );
    final DateTime startDateTime = DateTime.parse(startTime);
    final DateTime endDateTime = startDateTime.add(duration);
    final String endTime =
        DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(endDateTime);

    await store
        .onGetCustomExamPaperDataApiCall(widget.testExamPaper?.sId ?? '')
        .then((_) async {
      widget.testExamPaper?.test =
          store.customExamPaperData.map((examPaperData) {
        return TestData(
          questionImg: examPaperData?.questionImg,
          explanationImg: examPaperData?.explanationImg,
          sId: examPaperData?.sId,
          examId: examPaperData?.examId,
          questionText: examPaperData?.questionText,
          correctOption: examPaperData?.correctOption,
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
            );
          }).toList(),
          questionNumber: examPaperData?.questionNumber,
          statusColor: examPaperData?.statusColor,
          txtColor: examPaperData?.txtColor,
          bookmarks: examPaperData?.bookmarks,
        );
      }).toList();
    });
    await store.startCreateCustomExam(
        examId, startTime, endTime, isPractice);
    final String? userExamId = store.startCustomExam.value?.id;
    final bool? isPracticeExam = store.startCustomExam.value?.isPractice;
    if (!mounted) return;
    if (widget.testExamPaper?.test?.isNotEmpty ?? false) {
      if (isPractice == false) {
        if (store.startCustomExam.value?.err?.message == null) {
          Navigator.of(context).pushNamed(
            Routes.testExams,
            arguments: {
              'testData': widget.testExamPaper,
              'userexamId': userExamId,
              'isPracticeExam': isPracticeExam,
            },
          );
        } else {
          BottomToast.showBottomToastOverlay(
            context: context,
            errorMessage:
                store.startCustomExam.value?.err?.message ?? '',
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      } else {
        if (store.startCustomExam.value?.err?.message == null) {
          Navigator.of(context).pushNamed(
            Routes.practiceCustomTestExamScreen,
            arguments: {
              'testData': widget.testExamPaper,
              'userexamId': userExamId,
              'isPracticeExam': isPracticeExam,
            },
          );
        } else {
          BottomToast.showBottomToastOverlay(
            context: context,
            errorMessage:
                store.startCustomExam.value?.err?.message ?? '',
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      }
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: 'Exam Paper Not Found!',
        backgroundColor: AppTokens.danger(context),
      );
    }
  }

  Future<void> _startUnAnsweredExamApiCall(
    TestCategoryStore store,
    Data? testExamPaper,
    bool? isPractice,
    String? type,
  ) async {
    // ignore: unused_local_variable
    final String examId = testExamPaper?.sId ?? '';
    final DateTime now = DateTime.now();
    // ignore: unused_local_variable
    final String startTime =
        DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(now);
    final String timeDuration = testExamPaper?.timeDuration ?? '';
    final List<String> timeParts = timeDuration.split(':');
    final Duration duration = Duration(
      hours: int.parse(timeParts[0]),
      minutes: int.parse(timeParts[1]),
      seconds: int.parse(timeParts[2]),
    );
    // ignore: unused_local_variable
    final DateTime startDateTime = DateTime.parse(
        DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(now));
    // ignore: unused_local_variable
    final DateTime endDateTime = startDateTime.add(duration);
    // ignore: unused_local_variable
    final String endTime =
        DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(endDateTime);
    await store
        .onGetPracticeCustomExamPaperDataApiCall(
            widget.testExamPaper?.exitUserExamId ?? '', type!)
        .then((_) async {
      widget.testExamPaper?.test =
          store.customExamPracticePaperData.map((examPaperData) {
        return TestData(
          questionImg: examPaperData?.questionImg,
          explanationImg: examPaperData?.explanationImg,
          sId: examPaperData?.sId,
          examId: examPaperData?.examId,
          questionText: examPaperData?.questionText,
          correctOption: examPaperData?.correctOption,
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
            );
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
      Navigator.of(context).pushNamed(
        Routes.practiceCustomTestExamScreen,
        arguments: {
          'testData': widget.testExamPaper,
          'userexamId': widget.testExamPaper?.exitUserExamId,
          'isPracticeExam': true,
        },
      );
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: 'Exam Paper Not Found!',
        backgroundColor: AppTokens.danger(context),
      );
    }
  }

  Future<void> _startAnsweredExamApiCall(
    TestCategoryStore store,
    Data? testExamPaper,
    bool? isPractice,
    String? type,
  ) async {
    // ignore: unused_local_variable
    final String examId = testExamPaper?.sId ?? '';
    final DateTime now = DateTime.now();
    // ignore: unused_local_variable
    final String startTime =
        DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(now);
    final String timeDuration = testExamPaper?.timeDuration ?? '';
    final List<String> timeParts = timeDuration.split(':');
    final Duration duration = Duration(
      hours: int.parse(timeParts[0]),
      minutes: int.parse(timeParts[1]),
      seconds: int.parse(timeParts[2]),
    );
    // ignore: unused_local_variable
    final DateTime startDateTime = DateTime.parse(
        DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(now));
    // ignore: unused_local_variable
    final DateTime endDateTime = startDateTime.add(duration);
    // ignore: unused_local_variable
    final String endTime =
        DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(endDateTime);
    await store
        .onGetPracticeCustomExamPaperDataApiCall(
            widget.testExamPaper?.exitUserExamId ?? '', type!)
        .then((_) async {
      widget.testExamPaper?.test =
          store.customExamPracticePaperData.map((examPaperData) {
        debugPrint(
            'examPaperData?.isCorrect,:${examPaperData?.isCorrect}');
        return TestData(
          isCorrect: examPaperData?.isCorrect,
          questionImg: examPaperData?.questionImg,
          selectedOption: examPaperData?.selectedOption,
          explanationImg: examPaperData?.explanationImg,
          sId: examPaperData?.sId,
          examId: examPaperData?.examId,
          questionText: examPaperData?.questionText,
          correctOption: examPaperData?.correctOption,
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
            );
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
      showModalBottomSheet<void>(
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.r28),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return StartPracticeBottomSheet(
            store: store,
            testExamPaper: widget.testExamPaper,
            isPractice: widget.isPractice,
            userExamId: widget.testExamPaper?.exitUserExamId,
            isPracticeExam: true,
          );
        },
      );
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: 'Exam Paper Not Found!',
        backgroundColor: AppTokens.danger(context),
      );
    }
  }
}

/// StartPracticeBottomSheet — secondary modal launched when the learner
/// chose "Answered Questions". Filters further by All / Correct /
/// Incorrect before routing to `practiceSolutionCustomTestExams`. Public
/// surface preserved:
///   • const constructor `({required TestCategoryStore store,
///     Data? testExamPaper, bool? isPractice, String? userExamId,
///     bool? isPracticeExam})`
class StartPracticeBottomSheet extends StatefulWidget {
  final TestCategoryStore store;
  final Data? testExamPaper;
  final bool? isPractice;
  final String? userExamId;
  final bool? isPracticeExam;
  const StartPracticeBottomSheet({
    super.key,
    required this.store,
    this.testExamPaper,
    this.isPractice,
    this.userExamId,
    this.isPracticeExam,
  });

  @override
  State<StartPracticeBottomSheet> createState() =>
      _StartPracticeBottomSheetState();
}

class _StartPracticeBottomSheetState
    extends State<StartPracticeBottomSheet> {
  // ignore: unused_field
  TextEditingController queryController = TextEditingController();
  List<String> questions = ['All', 'Correct', 'Incorrect'];
  int? currentIndex;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Practice Mode',
      subtitle: 'Select any one of the options',
      showBack: true,
      onBack: () => Navigator.pop(context),
      child: Column(
        children: [
          _StatsGrid(
            answered: widget
                    .store.getCustomPracticeCountData.value?.attempted ??
                0,
            unanswered: widget.store.getCustomPracticeCountData.value
                    ?.notVisited ??
                0,
            correct: widget.store.getCustomPracticeCountData.value
                    ?.correctAnswers ??
                0,
            incorrect: widget.store.getCustomPracticeCountData.value
                    ?.incorrectAnswers ??
                0,
          ),
          const SizedBox(height: AppTokens.s20),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTokens.s20),
            child: Column(
              children: List.generate(
                questions.length,
                (index) => _ChoiceRow(
                  icon: _iconFor(index),
                  label: questions[index],
                  selected: currentIndex == index,
                  onTap: () => setState(() => currentIndex = index),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          _CtaButton(
            label: 'Start Practice',
            enabled: currentIndex != null,
            loading: widget.store.isLoading,
            onTap: () async {
              bool? isSelected;
              if (currentIndex == 1) {
                isSelected = true;
                if (widget.store.getCustomPracticeCountData.value
                        ?.correctAnswers ==
                    0) {
                  BottomToast.showBottomToastOverlay(
                    context: context,
                    errorMessage: 'Correct answer is empty',
                    backgroundColor: Theme.of(context).primaryColor,
                  );
                  return;
                }
              } else if (currentIndex == 2) {
                isSelected = false;
                if (widget.store.getCustomPracticeCountData.value
                        ?.incorrectAnswers ==
                    0) {
                  BottomToast.showBottomToastOverlay(
                    context: context,
                    errorMessage: 'Incorrect answer is empty',
                    backgroundColor: Theme.of(context).primaryColor,
                  );
                  return;
                }
              }
              Navigator.of(context).pushNamed(
                Routes.practiceSolutionCustomTestExams,
                arguments: {
                  'testData': widget.testExamPaper,
                  'userexamId': widget.userExamId,
                  'isPracticeExam': widget.isPracticeExam,
                  'id': '',
                  'type': '',
                  'isCorrect': isSelected,
                },
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _iconFor(int index) {
    switch (index) {
      case 0:
        return Icons.all_inclusive_rounded;
      case 1:
        return Icons.check_circle_outline_rounded;
      case 2:
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}

// ─── Shared bottom-sheet primitives ──────────────────────────────────────

/// Shell chrome for both practice sheets: r28 top-rounded surface, grabber,
/// optional back-chip + title row, helper subtitle, and space for the body.
class _SheetShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget child;
  const _SheetShell({
    required this.title,
    required this.subtitle,
    this.showBack = false,
    this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.r28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppTokens.s12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppTokens.border(context),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTokens.s20),
              child: Row(
                children: [
                  if (showBack) ...[
                    Material(
                      color: AppTokens.surface2(context),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onBack,
                        child: Padding(
                          padding: const EdgeInsets.all(AppTokens.s8),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: AppTokens.ink(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: showBack
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: AppTokens.titleMd(context)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.ink2(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showBack) const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTokens.s20),
              child: child,
            ),
            const SizedBox(height: AppTokens.s16),
          ],
        ),
      ),
    );
  }
}

/// Four-up pill grid showing Answered / Unanswered / Correct / Incorrect
/// counts with semantic colouring from the AppTokens palette.
class _StatsGrid extends StatelessWidget {
  final int answered;
  final int unanswered;
  final int correct;
  final int incorrect;
  const _StatsGrid({
    required this.answered,
    required this.unanswered,
    required this.correct,
    required this.incorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatPill(
                label: 'Answered',
                count: answered,
                color: AppTokens.accent(context),
                bg: AppTokens.accentSoft(context),
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            Expanded(
              child: _StatPill(
                label: 'Unanswered',
                count: unanswered,
                color: AppTokens.warning(context),
                bg: AppTokens.warningSoft(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s8),
        Row(
          children: [
            Expanded(
              child: _StatPill(
                label: 'Correct',
                count: correct,
                color: AppTokens.success(context),
                bg: AppTokens.successSoft(context),
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            Expanded(
              child: _StatPill(
                label: 'Incorrect',
                count: incorrect,
                color: AppTokens.danger(context),
                bg: AppTokens.dangerSoft(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bg;
  const _StatPill({
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
      child: Text(
        '$label ($count)',
        style: AppTokens.caption(context).copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s16,
              vertical: AppTokens.s12,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppTokens.accentSoft(context)
                  : AppTokens.surface2(context),
              borderRadius: BorderRadius.circular(AppTokens.r12),
              border: Border.all(
                color: selected
                    ? AppTokens.accent(context)
                    : AppTokens.border(context),
                width: selected ? 1.6 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? AppTokens.accent(context)
                      : AppTokens.ink2(context),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppTokens.accent(context)
                          : AppTokens.ink(context),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppTokens.accent(context)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? AppTokens.accent(context)
                          : AppTokens.border(context),
                      width: 1.4,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;
  const _CtaButton({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1.0 : 0.55,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.r16),
            onTap: enabled && !loading ? onTap : null,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTokens.brand, AppTokens.brand2],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(AppTokens.r16),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: AppTokens.brand.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    )
                  : Text(
                      label,
                      style: AppTokens.titleSm(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
