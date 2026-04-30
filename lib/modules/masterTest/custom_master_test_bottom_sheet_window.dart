// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/new_exam_component/exam_screen.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../test/store/test_category_store.dart';
import '../widgets/bottom_toast.dart';

/// Window-variant of the master-test instructions sheet — redesigned
/// with AppTokens. Preserves the 7-positional constructor with the
/// named `isWindow` flag (defaults false) + non-nullable
/// `showPredictive`, the isWindow-gated rounded border, the Column
/// with no fixed height, the 7-dot instruction legend, the
/// `negativeMarking` marking-scheme row (svg assets unchanged), plain
/// Text for the raw instruction (this variant deliberately skips
/// ExpandableText), the Start Test/Practice CTA, and the full
/// `_startMasterExamApiCall` chain including the source's
/// `'showPredictive': widget.type` arg on the practice route
/// (preserved verbatim to avoid changing behavior).
class CustomMasterTestBottomSheetWindow extends StatefulWidget {
  final TestExamPaperListModel? testExamPaper;
  final String? id;
  final String? type;
  final bool? isPractice;
  final bool isWindow;
  final bool showPredictive;
  const CustomMasterTestBottomSheetWindow(
    BuildContext context,
    this.testExamPaper,
    this.id,
    this.type,
    this.isPractice,
    this.showPredictive, {
    super.key,
    this.isWindow = false,
  });

  @override
  State<CustomMasterTestBottomSheetWindow> createState() =>
      _CustomMasterTestBottomSheetWindowState();
}

class _CustomMasterTestBottomSheetWindowState
    extends State<CustomMasterTestBottomSheetWindow> {
  final CarouselSliderControllerImpl _controller =
      CarouselSliderControllerImpl();

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    final bool isPractice = widget.isPractice == true;

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          borderRadius:
              widget.isWindow ? BorderRadius.circular(AppTokens.r20) : null,
          color: AppTokens.scaffold(context),
          border: widget.isWindow
              ? Border.all(color: AppTokens.border(context))
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s20,
            AppTokens.s20,
            AppTokens.s20,
            AppTokens.s20,
          ),
          child: Observer(
            builder: (_) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SheetHeader(
                    examName: widget.testExamPaper?.examName ?? "",
                  ),
                  if (!isPractice) ...[
                    const SizedBox(height: AppTokens.s16),
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Instructions",
                            style: AppTokens.titleSm(context),
                          ),
                          const SizedBox(height: AppTokens.s12),
                          _InstructionLegend(),
                          const SizedBox(height: AppTokens.s12),
                          _HintLine(
                            text:
                                "Touch again on attempted answer to clear",
                          ),
                          if (widget.testExamPaper?.negativeMarking ==
                              true) ...[
                            const SizedBox(height: AppTokens.s16),
                            _MarkingSchemeRow(
                              marksAwarded:
                                  widget.testExamPaper?.marksAwarded,
                              marksDeducted:
                                  widget.testExamPaper?.marksDeducted,
                            ),
                            const SizedBox(height: AppTokens.s8),
                          ],
                          if ((widget.testExamPaper?.instruction ?? "")
                              .trim()
                              .isNotEmpty) ...[
                            const SizedBox(height: AppTokens.s16),
                            Text(
                              "Additional Notes",
                              style: AppTokens.titleSm(context),
                            ),
                            const SizedBox(height: AppTokens.s8),
                            Text(
                              widget.testExamPaper?.instruction ?? "",
                              style: AppTokens.body(context),
                            ),
                          ],
                          const SizedBox(height: AppTokens.s12),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: AppTokens.s24),
                    _PracticeBlurb(),
                    const SizedBox(height: AppTokens.s24),
                  ],
                  const SizedBox(height: AppTokens.s12),
                  Observer(
                    builder: (_) {
                      return _StartCta(
                        label: isPractice ? "Start Practice" : "Start Test",
                        loading: store.isLoading,
                        onTap: () async {
                          await _startMasterExamApiCall(
                            store,
                            widget.testExamPaper,
                            widget.isPractice,
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
      ),
    );
  }

  // --------------------------------------------------------------
  //  Original API call chain — preserved verbatim
  //  (including the `'showPredictive': widget.type` quirk)
  // --------------------------------------------------------------
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
    await store.onCreateTestHistoryCall(
        widget.testExamPaper?.examId ?? '', 'mockExam');
    await store
        .onGetMaterExamPaperDataApiCall(widget.testExamPaper?.examId ?? "")
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
    await store.startCreateMaterExam(examId, startTime, endTime, isPractice);
    String? userExamId = store.startMasterExam.value?.id;
    bool? isPracticeExam = store.startMasterExam.value?.isPractice;
    if (widget.testExamPaper?.test?.isNotEmpty ?? false) {
      if (isPractice == false) {
        if (store.startMasterExam.value?.err?.message == null) {
          Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => ExamScreen(
                  type: "MockExam",
                  testExamPaper: widget.testExamPaper,
                  id: examId,
                  userExamId: userExamId!,
                  showPredictive: widget.showPredictive,
                  isTrend: false,
                ),
              ));
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
            'type': widget.type,
            'showPredictive': widget.type
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
}

// ============================================================
//                        Primitives
// ============================================================

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.examName});
  final String examName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.accentSoft(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(
          color: AppTokens.accent(context).withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppTokens.radius8,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.quiz_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Exam",
                  style: AppTokens.overline(context),
                ),
                const SizedBox(height: 2),
                Text(
                  examName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTokens.titleSm(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HintLine extends StatelessWidget {
  const _HintLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: AppTokens.muted(context),
        ),
        const SizedBox(width: AppTokens.s8),
        Expanded(
          child: Text(
            text,
            style: AppTokens.caption(context),
          ),
        ),
      ],
    );
  }
}

class _InstructionLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entries = <_LegendEntry>[
      const _LegendEntry(color: Colors.green, label: "Attempted"),
      const _LegendEntry(color: Colors.blue, label: "Marked for Review"),
      const _LegendEntry(
          color: Colors.orange, label: "Attempted and Marked for Review"),
      const _LegendEntry(color: Colors.red, label: "Skipped"),
      const _LegendEntry(color: Colors.brown, label: "Guess"),
      _LegendEntry(color: AppTokens.ink(context), label: "Not Visited"),
    ];
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: entries[i].color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Text(
                    entries[i].label,
                    style: AppTokens.caption(context).copyWith(
                      color: AppTokens.ink2(context),
                    ),
                  ),
                ),
              ],
            ),
            if (i != entries.length - 1) const SizedBox(height: AppTokens.s8),
          ],
        ],
      ),
    );
  }
}

class _LegendEntry {
  const _LegendEntry({required this.color, required this.label});
  final Color color;
  final String label;
}

class _MarkingSchemeRow extends StatelessWidget {
  const _MarkingSchemeRow({
    required this.marksAwarded,
    required this.marksDeducted,
  });
  final dynamic marksAwarded;
  final dynamic marksDeducted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        children: [
          Text(
            "Marking Scheme",
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.ink(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _ScorePill(
            color: AppTokens.success(context),
            bg: AppTokens.successSoft(context),
            text: "+${marksAwarded?.toString() ?? "0"}",
            svgAsset: "assets/image/markaward.svg",
          ),
          const SizedBox(width: AppTokens.s8),
          _ScorePill(
            color: AppTokens.danger(context),
            bg: AppTokens.dangerSoft(context),
            text: "-${marksDeducted?.toString() ?? "0"}",
            svgAsset: "assets/image/markdeducation.svg",
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({
    required this.color,
    required this.bg,
    required this.text,
    required this.svgAsset,
  });
  final Color color;
  final Color bg;
  final String text;
  final String svgAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: AppTokens.s4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(64),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: AppTokens.caption(context).copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppTokens.s4),
          Container(
            height: 16,
            width: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              svgAsset,
              width: 10,
              height: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeBlurb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTokens.accentSoft(context),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.auto_stories_rounded,
              color: AppTokens.accent(context),
              size: 20,
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Practice Mode",
                  style: AppTokens.titleSm(context),
                ),
                const SizedBox(height: 2),
                Text(
                  "Review each answer instantly. No time pressure.",
                  style: AppTokens.caption(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartCta extends StatelessWidget {
  const _StartCta({
    required this.label,
    required this.loading,
    required this.onTap,
  });
  final String label;
  final bool loading;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: AppTokens.radius12,
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : () => onTap(),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppTokens.radius12,
            boxShadow: [
              BoxShadow(
                color: AppTokens.brand.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: 52,
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
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: AppTokens.s8),
                        Text(
                          label,
                          style: AppTokens.titleSm(context).copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
