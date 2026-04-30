import 'dart:io';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../new_exam_component/exam_screen.dart';
import '../test/store/test_category_store.dart';
import 'bottom_toast.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/styles.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import
import 'package:flutter_svg/flutter_svg.dart';
// ignore: unused_import
import 'package:carousel_slider/carousel_slider.dart';

/// CustomTestBottomSheet — pre-flight sheet launched from the test module
/// right before starting an exam. Public surface preserved exactly:
///   • const constructor `(BuildContext context, this.testExamPaper,
///     this.id, this.type, this.isPractice, {super.key,
///     this.isUseHightWidthWindow = true})`
///   • MobX Observer gated on `TestCategoryStore.isLoading` / store state
///   • `_startExamApiCall(store, testExamPaper, isPractice, type)` retained
///     — disposes store, creates exam history, fetches paper, maps
///     TestData, navigates to ExamScreen (practice false) or
///     Routes.practiceTestExams (practice true)
class CustomTestBottomSheet extends StatefulWidget {
  final TestExamPaperListModel? testExamPaper;
  final String? id;
  final String? type;
  final bool? isPractice;
  final bool isUseHightWidthWindow;
  const CustomTestBottomSheet(
    BuildContext context,
    this.testExamPaper,
    this.id,
    this.type,
    this.isPractice, {
    super.key,
    this.isUseHightWidthWindow = true,
  });

  @override
  State<CustomTestBottomSheet> createState() => _CustomTestBottomSheetState();
}

class _CustomTestBottomSheetState extends State<CustomTestBottomSheet> {
  // ignore: unused_field
  final CarouselSliderControllerImpl _controller =
      CarouselSliderControllerImpl();

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    final bool desktopWindow = _isDesktop && widget.isUseHightWidthWindow;
    final double height = desktopWindow
        ? MediaQuery.of(context).size.height * 0.56
        : widget.isPractice == false
            ? MediaQuery.of(context).size.height * 0.58
            : MediaQuery.of(context).size.height * 0.32;
    final double? width = desktopWindow
        ? MediaQuery.of(context).size.width * 0.34
        : null;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: _isDesktop
            ? BorderRadius.circular(AppTokens.r20)
            : const BorderRadius.vertical(
                top: Radius.circular(AppTokens.r20),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s16,
          AppTokens.s20,
          AppTokens.s20,
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
                      margin: const EdgeInsets.only(bottom: AppTokens.s12),
                      decoration: BoxDecoration(
                        color: AppTokens.border(context),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                Center(
                  child: Text(
                    widget.testExamPaper?.examName ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTokens.titleMd(context)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                if (widget.isPractice == false)
                  Expanded(
                    child: _InstructionsPanel(
                      negativeMarking:
                          widget.testExamPaper?.negativeMarking == true,
                      marksAwarded:
                          widget.testExamPaper?.marksAwarded?.toString() ?? '',
                      marksDeducted:
                          widget.testExamPaper?.marksDeducted?.toString() ?? '',
                      instruction: widget.testExamPaper?.instruction ?? '',
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(height: AppTokens.s12),
                Observer(
                  builder: (BuildContext context) {
                    return _StartCta(
                      label: widget.isPractice == false
                          ? 'Start Test'
                          : 'Start Practice',
                      isLoading: store.isLoading,
                      onTap: () async {
                        await _startExamApiCall(
                          store,
                          widget.testExamPaper,
                          widget.isPractice,
                          widget.type ?? '',
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _startExamApiCall(
    TestCategoryStore store,
    TestExamPaperListModel? testExamPaper,
    bool? isPractice,
    String type,
  ) async {
    await store.disposeStore();
    final String examId = testExamPaper?.examId ?? '';
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
    await store.onCreateTestHistoryCall(testExamPaper?.examId ?? '', 'exam');
    await store
        .onGetExamPaperDataApiCall(widget.testExamPaper?.examId ?? '')
        .then((_) async {
      store.qutestionList.value = store.examPaperData.map((examPaperData) {
        return TestData(
          questionImg: examPaperData?.questionImg,
          explanationImg: examPaperData?.explanationImg,
          sId: examPaperData?.sId,
          examId: examPaperData?.examId,
          questionText: examPaperData?.questionText,
          correctOption: examPaperData?.correctOption,
          selectedOption: examPaperData?.selectedOption,
          explanation: examPaperData?.explanation,
          created_at: examPaperData?.created_at,
          updated_at: examPaperData?.updated_at,
          id: examPaperData?.id,
          optionsData: examPaperData?.optionVal?.map((option) {
            return Options(
              answerImg: option.answerImg,
              answerTitle: option.answerTitle,
              percentage: option.percentage,
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
    widget.testExamPaper?.test = store.qutestionList.value;
    String? userExamId = store.startExam.value?.id;
    await store.startCreateExam(
        examId, startTime, endTime, isPractice, type, userExamId);
    final bool? isPracticeExam = store.startExam.value?.isPractice;
    if (!mounted) return;
    if (widget.testExamPaper?.test?.isNotEmpty ?? false) {
      if (isPractice == false) {
        if (store.startExam.value?.err?.message == null) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => ExamScreen(
                type: 'McqExam',
                testExamPaper: widget.testExamPaper,
                id: examId,
                userExamId: userExamId!,
                showPredictive: false,
                isTrend: false,
              ),
            ),
          );
        } else {
          BottomToast.showBottomToastOverlay(
            context: context,
            errorMessage: store.startExam.value?.err?.message ?? '',
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      } else {
        log(store.startExam.value!.toJson().toString());
        if (store.startExam.value?.err?.message == null &&
            store.startExam.value?.id != null) {
          Navigator.of(context).pushNamed(
            Routes.practiceTestExams,
            arguments: {
              'testData': widget.testExamPaper,
              'userexamId': store.startExam.value?.id!,
              'isPracticeExam': isPracticeExam,
              'id': widget.id,
              'type': widget.type,
            },
          );
        } else {
          BottomToast.showBottomToastOverlay(
            context: context,
            errorMessage: store.startExam.value?.err?.message ?? '',
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
}

// ---------------------------------------------------------------------------
// Internal blocks
// ---------------------------------------------------------------------------

class _InstructionsPanel extends StatelessWidget {
  const _InstructionsPanel({
    required this.negativeMarking,
    required this.marksAwarded,
    required this.marksDeducted,
    required this.instruction,
  });

  final bool negativeMarking;
  final String marksAwarded;
  final String marksDeducted;
  final String instruction;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructions',
            style: AppTokens.titleSm(context)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTokens.s12),
          const _LegendDot(color: Color(0xFF10B981), label: 'Attempted'),
          const SizedBox(height: AppTokens.s8),
          const _LegendDot(color: Color(0xFF3B82F6), label: 'Marked for Review'),
          const SizedBox(height: AppTokens.s8),
          const _LegendDot(
              color: Color(0xFFF59E0B),
              label: 'Attempted and Marked for Review'),
          const SizedBox(height: AppTokens.s8),
          const _LegendDot(color: Color(0xFFEF4444), label: 'Skipped'),
          const SizedBox(height: AppTokens.s8),
          const _LegendDot(color: Color(0xFF8B5E3C), label: 'Guess'),
          const SizedBox(height: AppTokens.s8),
          _LegendDot(color: AppTokens.ink(context), label: 'Not Visited'),
          const SizedBox(height: AppTokens.s12),
          Text(
            'Touch again on attempted answer to clear',
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.ink2(context),
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          if (negativeMarking) ...[
            Container(
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                color: AppTokens.surface2(context),
                borderRadius: BorderRadius.circular(AppTokens.r12),
                border: Border.all(color: AppTokens.border(context)),
              ),
              child: Row(
                children: [
                  Text(
                    'Marking Scheme:',
                    style: AppTokens.caption(context).copyWith(
                      color: AppTokens.ink2(context),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  _MarkPill(
                    text: '+$marksAwarded',
                    color: AppTokens.success(context),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  _MarkPill(
                    text: '-$marksDeducted',
                    color: AppTokens.danger(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s12),
          ],
          ExpandableText(
            instruction,
            style: AppTokens.body(context).copyWith(
              color: AppTokens.ink2(context),
            ),
            expandText: 'see more',
            maxLines: 3,
            collapseText: '......show less',
            linkColor: AppTokens.accent(context),
          ),
          const SizedBox(height: AppTokens.s12),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppTokens.s12),
        Expanded(
          child: Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.ink2(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _MarkPill extends StatelessWidget {
  const _MarkPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTokens.caption(context).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StartCta extends StatelessWidget {
  const _StartCta({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: AppTokens.brand.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: AppTokens.s8),
                    Text(
                      label,
                      style: AppTokens.body(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
