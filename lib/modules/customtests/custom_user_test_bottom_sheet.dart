import 'dart:io' show Platform;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
// ignore: unused_import
import '../../models/exam_paper_data_model.dart';
import '../../models/get_all_my_custom_test_model.dart';
import '../test/store/test_category_store.dart';
import '../widgets/bottom_toast.dart';

// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import, unnecessary_import
import 'package:flutter/cupertino.dart';
// ignore: unused_import
import 'package:mobx/mobx.dart';
// ignore: unused_import
import 'package:nuts_activity_indicator/nuts_activity_indicator.dart';
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import
import '../../helpers/styles.dart';

/// CustomUserTestBottomSheet — pre-flight sheet shown when the learner
/// taps "Start" on a custom module. Public surface preserved exactly:
///   • const positional constructor
///     `(BuildContext context, Data? testExamPaper, String? id,
///       String? type, bool? isPractice, {Key? key})`
///   • `_startExamApiCall(store, testExamPaper, isPractice)` dispatch
///     including `TestCategoryStore.onGetCustomExamPaperDataApiCall(id)` +
///     `TestCategoryStore.startCreateCustomExam(examId, startTime, endTime,
///     isPractice)`
///   • Navigation to [Routes.customTestExams] or
///     [Routes.practiceCustomTestExamScreen] with full argument map
///     (`testData`, `userexamId`, `isPracticeExam`, `id`, `type`)
///   • Error toasts via [BottomToast.showBottomToastOverlay]
class CustomUserTestBottomSheet extends StatefulWidget {
  final Data? testExamPaper;
  final String? id;
  final String? type;
  final bool? isPractice;
  // ignore: use_super_parameters
  const CustomUserTestBottomSheet(BuildContext context, this.testExamPaper,
      this.id, this.type, this.isPractice,
      {Key? key})
      : super(key: key);

  @override
  State<CustomUserTestBottomSheet> createState() =>
      _CustomUserTestBottomSheetState();
}

class _CustomUserTestBottomSheetState
    extends State<CustomUserTestBottomSheet> {
  // ignore: unused_field
  final CarouselSliderControllerImpl _controller =
      CarouselSliderControllerImpl();

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    final store =
        Provider.of<TestCategoryStore>(context, listen: false);
    final isPractice = widget.isPractice ?? false;
    final media = MediaQuery.of(context);
    final double maxHeight = isPractice
        ? media.size.height * 0.35
        : media.size.height * 0.75;

    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: maxHeight,
          ),
          child: Container(
            margin: _isDesktop
                ? const EdgeInsets.all(AppTokens.s20)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              borderRadius: _isDesktop
                  ? BorderRadius.circular(AppTokens.r28)
                  : const BorderRadius.only(
                      topLeft: Radius.circular(AppTokens.r28),
                      topRight: Radius.circular(AppTokens.r28),
                    ),
              boxShadow: _isDesktop
                  ? [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                AppTokens.s12,
                AppTokens.s20,
                AppTokens.s16,
              ),
              child: Observer(
                builder: (BuildContext context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_isDesktop)
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTokens.surface3(context),
                              borderRadius:
                                  BorderRadius.circular(AppTokens.r8),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppTokens.s16),
                      Text(
                        widget.testExamPaper?.testName ?? '',
                        textAlign: TextAlign.center,
                        style: AppTokens.titleMd(context)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppTokens.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s12,
                          vertical: AppTokens.s8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTokens.accentSoft(context),
                          borderRadius:
                              BorderRadius.circular(AppTokens.r12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isPractice
                                  ? Icons.bolt_rounded
                                  : Icons.timer_outlined,
                              size: 16,
                              color: AppTokens.accent(context),
                            ),
                            const SizedBox(width: AppTokens.s4),
                            Text(
                              isPractice ? 'Practice Mode' : 'Timed Test',
                              style: AppTokens.caption(context).copyWith(
                                color: AppTokens.accent(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTokens.s16),
                      if (!isPractice)
                        Expanded(
                          child: SingleChildScrollView(
                            child: _InstructionsBody(
                                testExamPaper: widget.testExamPaper),
                          ),
                        )
                      else
                        const SizedBox(height: AppTokens.s12),
                      const SizedBox(height: AppTokens.s12),
                      Observer(
                        builder: (BuildContext context) {
                          return SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: store.isLoading
                                  ? null
                                  : () async {
                                      await _startExamApiCall(
                                          store,
                                          widget.testExamPaper,
                                          widget.isPractice);
                                    },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: AppTokens.brand,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.r12),
                                ),
                              ),
                              child: store.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white),
                                        const SizedBox(
                                            width: AppTokens.s8),
                                        Text(
                                          isPractice
                                              ? 'Start Practice'
                                              : 'Start Test',
                                          style: AppTokens.body(context)
                                              .copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startExamApiCall(TestCategoryStore store, Data? testExamPaper,
      bool? isPractice) async {
    String examId = testExamPaper?.sId ?? "";
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
    String endTime =
        DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(endDateTime);
    await store
        .onGetCustomExamPaperDataApiCall(widget.testExamPaper?.sId ?? "")
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
    String? userExamId = store.startCustomExam.value?.id;
    bool? isPracticeExam = store.startCustomExam.value?.isPractice;
    if (!mounted) return;
    if (widget.testExamPaper?.test?.isNotEmpty ?? false) {
      if (isPractice == false) {
        if (store.startCustomExam.value?.err?.message == null) {
          // ignore: use_build_context_synchronously
          Navigator.of(context)
              .pushNamed(Routes.customTestExams, arguments: {
            'testData': widget.testExamPaper,
            'userexamId': userExamId,
            'isPracticeExam': isPracticeExam,
            'id': widget.id,
            'type': widget.type
          });
        } else {
          BottomToast.showBottomToastOverlay(
            // ignore: use_build_context_synchronously
            context: context,
            errorMessage: store.startCustomExam.value?.err?.message ?? "",
            // ignore: use_build_context_synchronously
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      } else {
        if (store.startCustomExam.value?.err?.message == null) {
          // ignore: use_build_context_synchronously
          Navigator.of(context)
              .pushNamed(Routes.practiceCustomTestExamScreen, arguments: {
            'testData': widget.testExamPaper,
            'userexamId': userExamId,
            'isPracticeExam': isPracticeExam,
            'id': widget.id,
            'type': widget.type
          });
        } else {
          BottomToast.showBottomToastOverlay(
            // ignore: use_build_context_synchronously
            context: context,
            errorMessage: store.startCustomExam.value?.err?.message ?? "",
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
}

class _InstructionsBody extends StatelessWidget {
  const _InstructionsBody({required this.testExamPaper});

  final Data? testExamPaper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions',
          style: AppTokens.titleSm(context)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppTokens.s12),
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: const [
            _StatusChip(color: Colors.green, label: 'Attempted'),
            _StatusChip(color: Colors.blue, label: 'Marked'),
            _StatusChip(
                color: Colors.orange, label: 'Attempted + Marked'),
            _StatusChip(color: Colors.red, label: 'Skipped'),
            _StatusChip(color: Colors.brown, label: 'Guess'),
            _StatusChip(color: Colors.black54, label: 'Not Visited'),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        Text(
          'Touch again on an attempted answer to clear it.',
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.ink2(context),
          ),
        ),
        const SizedBox(height: AppTokens.s16),
        Text(
          'Marking Scheme',
          style: AppTokens.titleSm(context)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppTokens.s8),
        Row(
          children: [
            _MarkBadge(
              bg: AppTokens.successSoft(context),
              fg: AppTokens.success(context),
              value: '+${testExamPaper?.marksAwarded ?? 0}',
              icon: 'assets/image/markaward.svg',
            ),
            const SizedBox(width: AppTokens.s12),
            _MarkBadge(
              bg: AppTokens.dangerSoft(context),
              fg: AppTokens.danger(context),
              value: '-${testExamPaper?.marksDeducted ?? 0}',
              icon: 'assets/image/markdeducation.svg',
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        if ((testExamPaper?.description ?? '').isNotEmpty) ...[
          Text(
            'Description',
            style: AppTokens.titleSm(context)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTokens.s8),
          ExpandableText(
            testExamPaper?.description ?? '',
            style: AppTokens.body(context).copyWith(
              color: AppTokens.ink2(context),
            ),
            expandText: 'see more',
            maxLines: 3,
            collapseText: '......show less',
            linkColor: AppTokens.accent(context),
          ),
        ],
        const SizedBox(height: AppTokens.s12),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: AppTokens.s4,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.ink(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkBadge extends StatelessWidget {
  const _MarkBadge({
    required this.bg,
    required this.fg,
    required this.value,
    required this.icon,
  });

  final Color bg;
  final Color fg;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            icon,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
          ),
          const SizedBox(width: AppTokens.s8),
          Text(
            value,
            style: AppTokens.caption(context).copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
