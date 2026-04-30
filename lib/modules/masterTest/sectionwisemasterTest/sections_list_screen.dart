// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names, dead_null_aware_expression, prefer_final_fields, unused_local_variable

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/masterTest/sectionwisemasterTest/section_exam_screen.dart';
import 'package:shusruta_lms/modules/masterTest/sectionwisemasterTest/store/section_exam_store.dart';
import 'package:shusruta_lms/modules/new_exam_component/model/exam_ans_model.dart';

import '../../../app/routes.dart';
import '../../../helpers/app_tokens.dart';
import '../../../helpers/colors.dart';
import '../../test/store/test_category_store.dart';
import '../../widgets/bottom_toast.dart';
import '../custom_master_test_dialogbox.dart';
import 'package:shusruta_lms/modules/masterTest/sectionwisemasterTest/model/get_section_list_model.dart';

/// Section-wise master-exam landing page. Redesigned with AppTokens while
/// preserving every API contract:
///   • Constructor `SectionListScreen({super.key, required id, testExamPaper,
///     previousSectionTime, userexamId, isSecond, required sectionsList})`
///   • State fields: `sectionPaper`, `timer`, `_timer`, `_remainingTime=1`,
///     `remainingTime`, `remainingTimeNotifier`, `duration`, `mainExamTime`,
///     `sectionsList`, `ansList`, `questionList`, `isLastSection=false`
///   • `initState` -> `initializeData()`
///   • `initializeData()` copies widget.sectionsList + calls getSectionList
///   • `startSectionTimer()` wrapper preserved (calls
///     `_startSectionExamApiCall` every second — legacy; kept as-is)
///   • `getSectionList(context)` — `store.onGetSectionListApiCall`, mirrors
///     the list into `SectionExamStore.getSectionListModel.value`, picks the
///     first unlocked+incomplete section as `sectionPaper`, flags
///     `isLastSection` when the penultimate section is complete
///   • `_startSectionExamApiCall(store, sectionPaper)` — builds
///     startTime/endTime, calls
///     `store.onGetSectionExamPaperDataApiCall(examId, sectionId)` and maps
///     the response back into `widget.testExamPaper.test`, then
///     `sectionExamStore.setSectionData(...)`,
///     `store.startCreateSectionMaterExam(userExamId, sectionId, 'On Going')`,
///     and on success `pushReplacement(CupertinoPageRoute ->
///     SectionExamScreen(sectionData / type:'MockExam' / sectionsList /
///     testExamPaper / timeDuration:previousSectionTime / isLastSection / id /
///     ansList / questionList / isSecond / userExamId / showPredictive:true /
///     isTrend:false))` — all 12 fields preserved
///   • BottomToast error surfaces for both "startSectionMasterExam error"
///     and empty-test-paper cases
///   • Back button -> exit confirmation dialog; "Yes" ->
///     `pushNamed(Routes.allTestCategory)`
///   • Top stats: section count / total time / total questions
///   • List tiles: section name + duration + question count, Submitted
///     badge + lock corner ribbon
///   • Bottom action button — "Start Section {n}" — only rendered when
///     `sectionPaper?.isCompleteSection != true`
class SectionListScreen extends StatefulWidget {
  final TestExamPaperListModel? testExamPaper;
  final String? userexamId;
  final String? id;
  final bool? isSecond;
  final String? previousSectionTime;
  final List<GetSectionListModel> sectionsList;

  const SectionListScreen({
    super.key,
    required this.id,
    this.testExamPaper,
    this.previousSectionTime,
    this.userexamId,
    this.isSecond,
    required this.sectionsList,
  });

  @override
  State<SectionListScreen> createState() => _SectionListScreenState();
}

class _SectionListScreenState extends State<SectionListScreen> {
  GetSectionListModel? sectionPaper;
  Timer? timer;
  Timer? _timer;
  int _remainingTime = 1;
  Duration? remainingTime;
  late ValueNotifier<Duration> remainingTimeNotifier;
  Duration? duration;
  String? mainExamTime;
  List<GetSectionListModel> sectionsList = [];
  List<List<ExamAnsModel>> ansList = [];
  List<List<TestData>> questionList = [];

  bool isLastSection = false;

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    sectionsList = widget.sectionsList.isNotEmpty
        ? List<GetSectionListModel>.from(widget.sectionsList)
        : [];
    setState(() {});
    await getSectionList(context);
  }

  void startSectionTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        final store = Provider.of<TestCategoryStore>(context, listen: false);
        _startSectionExamApiCall(store, sectionPaper);
      });
    });
  }

  Future<void> getSectionList(context) async {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    await store.onGetSectionListApiCall(
        widget.testExamPaper?.examId ?? "", widget.userexamId ?? '');
    final sectionExamStore =
        Provider.of<SectionExamStore>(context, listen: false);
    sectionExamStore.getSectionListModel.value = List<GetSectionListModel>.from(
        store.getSectionList
            .where((section) => section != null)
            .cast<GetSectionListModel>());
    for (var section in store.getSectionList) {
      if (section?.isLocked == false && section?.isCompleteSection == false) {
        sectionPaper = section;
      }
    }
    if (store.getSectionList.length > 1 &&
        store.getSectionList[store.getSectionList.length - 2]
                ?.isCompleteSection ==
            true) {
      isLastSection = true;
    }
  }

  Future<void> _confirmExit() async {
    await showDialog(
      context: context,
      builder: (context) => _ExitDialog(
        onNo: () => Navigator.pop(context, false),
        onYes: () => Navigator.of(context).pushNamed(Routes.allTestCategory),
      ),
    );
  }

  Future<void> _startSectionExamApiCall(
      TestCategoryStore store, GetSectionListModel? sectionPaper) async {
    String examId = widget.testExamPaper?.examId ?? "";
    DateTime now = DateTime.now();
    String startTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(now);
    String timeDuration = sectionPaper?.timeDuration ?? "";
    List<String> timeParts = timeDuration.split(":");
    Duration duration = Duration(
      hours: int.parse(timeParts[0]),
      minutes: int.parse(timeParts[1]),
      seconds: int.parse(timeParts[2]),
    );
    DateTime startDateTime = DateTime.parse(startTime);
    DateTime endDateTime = startDateTime.add(duration);
    String endTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(endDateTime);
    final sectionExamStore =
        Provider.of<SectionExamStore>(context, listen: false);
    await store
        .onGetSectionExamPaperDataApiCall(
            examId ?? "", sectionPaper?.sectionId ?? '')
        .then((_) async {
      widget.testExamPaper?.test =
          store.sectionExamPaperData.map((examPaperData) {
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
    if (widget.testExamPaper!.test!.isNotEmpty) {
      await sectionExamStore.setSectionData(
          widget.testExamPaper!.test ?? [],
          widget.testExamPaper!,
          widget.isSecond == null ? widget.testExamPaper?.timeDuration : null);
    }

    await store.startCreateSectionMaterExam(
        widget.userexamId ?? '', sectionPaper?.sectionId ?? '', "On Going");

    if (widget.testExamPaper?.test?.isNotEmpty ?? false) {
      if (store.startSectionMasterExam.value?.err?.message == null) {
        Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
              builder: (context) => SectionExamScreen(
                sectionData: sectionPaper!,
                type: "MockExam",
                sectionsList: widget.sectionsList,
                testExamPaper: widget.testExamPaper,
                timeDuration: widget.previousSectionTime,
                isLastSection: isLastSection,
                id: examId,
                ansList: ansList,
                questionList: questionList,
                isSecond: widget.isSecond == null ? true : false,
                userExamId: widget.userexamId!,
                showPredictive: true,
                isTrend: false,
              ),
            ));
      } else {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: store.startSectionMasterExam.value?.err?.message ?? "",
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "Exam Paper Not Found!",
        backgroundColor: ThemeManager.redAlert,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      bottomNavigationBar: Observer(
        builder: (BuildContext context) {
          if (sectionPaper?.isCompleteSection == true) {
            return const SizedBox.shrink();
          }
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s16,
                AppTokens.s12,
                AppTokens.s16,
                AppTokens.s16,
              ),
              child: _StartSectionBtn(
                label: "Start Section ${sectionPaper?.section ?? ''}",
                loading: store.isLoading,
                onTap: () async {
                  await _startSectionExamApiCall(store, sectionPaper);
                },
              ),
            ),
          );
        },
      ),
      body: Observer(
        builder: (BuildContext context) {
          return Column(
            children: [
              // ---------- header gradient block ----------
              _HeaderBlock(
                onBack: _confirmExit,
                title: "Choose Test",
                sectionCount: widget.testExamPaper?.sectionWiseCount
                        ?.toString()
                        .padLeft(2, '0') ??
                    '',
                totalTime: widget.testExamPaper?.timeDuration ?? '',
                totalQuestions:
                    widget.testExamPaper?.totalQuestions?.toString() ?? '',
              ),
              // ---------- rounded content ----------
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTokens.scaffold(context),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTokens.r28),
                      topRight: Radius.circular(AppTokens.r28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.s16,
                    AppTokens.s20,
                    AppTokens.s16,
                    AppTokens.s12,
                  ),
                  child: store.getSectionList.isEmpty
                      ? Center(
                          child: Text(
                            "No sections available",
                            style: AppTokens.body(context),
                          ),
                        )
                      : ListView.builder(
                          itemCount: store.getSectionList.length,
                          padding: EdgeInsets.zero,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (BuildContext context, int index) {
                            final GetSectionListModel? sectionList =
                                store.getSectionList[index];
                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppTokens.s12),
                              child: _SectionTile(
                                index: index,
                                title: "Section ${sectionList?.section}",
                                duration: sectionList?.timeDuration ?? '',
                                questions:
                                    "${sectionList?.numberOfQuestions ?? 0} Questions",
                                isComplete:
                                    sectionList?.isCompleteSection == true,
                                isLocked: sectionList?.isLocked == true,
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
//                                 PRIMITIVES
// ============================================================================

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({
    required this.onBack,
    required this.title,
    required this.sectionCount,
    required this.totalTime,
    required this.totalQuestions,
  });
  final VoidCallback onBack;
  final String title;
  final String sectionCount;
  final String totalTime;
  final String totalQuestions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppTokens.s12,
        MediaQuery.of(context).padding.top + AppTokens.s8,
        AppTokens.s16,
        AppTokens.s20,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppTokens.s4),
              Expanded(
                child: Text(
                  title,
                  style: AppTokens.titleMd(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HeaderStat(
                svgAsset: "assets/image/sectionBook.svg",
                label: "Sections",
                value: sectionCount,
              ),
              _HeaderStat(
                svgAsset: "assets/image/sectionTime.svg",
                label: "Total Time",
                value: totalTime,
              ),
              _HeaderStat(
                svgAsset: "assets/image/sectionBook.svg",
                label: "Total Que.",
                value: totalQuestions,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.svgAsset,
    required this.label,
    required this.value,
  });
  final String svgAsset;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(svgAsset,
            width: 22, height: 22, color: Colors.white.withOpacity(0.95)),
        const SizedBox(width: AppTokens.s8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTokens.caption(context).copyWith(
                color: Colors.white.withOpacity(0.85),
                height: 1.15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTokens.titleSm(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.index,
    required this.title,
    required this.duration,
    required this.questions,
    required this.isComplete,
    required this.isLocked,
  });
  final int index;
  final String title;
  final String duration;
  final String questions;
  final bool isComplete;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTokens.s12),
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(color: AppTokens.border(context)),
            boxShadow: AppTokens.shadow1(context),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                ),
                child: SvgPicture.asset(
                  "assets/image/note2.svg",
                  width: 28,
                  height: 28,
                  color: AppTokens.accent(context),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTokens.titleSm(context),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SvgPicture.asset(
                          "assets/image/clock2.svg",
                          width: 12,
                          height: 12,
                          color: AppTokens.ink2(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: AppTokens.caption(context)
                              .copyWith(color: AppTokens.ink2(context)),
                        ),
                        const SizedBox(width: AppTokens.s12),
                        SvgPicture.asset(
                          "assets/image/question2.svg",
                          width: 12,
                          height: 12,
                          color: AppTokens.ink2(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          questions,
                          style: AppTokens.caption(context)
                              .copyWith(color: AppTokens.ink2(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isComplete)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ThemeManager.greenSuccess,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "Submitted",
                    style: AppTokens.caption(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (isLocked)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              height: 22,
              width: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTokens.accent(context),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppTokens.r12),
                  bottomLeft: Radius.circular(AppTokens.r12),
                ),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _StartSectionBtn extends StatelessWidget {
  const _StartSectionBtn({
    required this.label,
    required this.loading,
    required this.onTap,
  });
  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: loading ? null : onTap,
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            boxShadow: AppTokens.shadow2(context),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
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
    );
  }
}

class _ExitDialog extends StatelessWidget {
  const _ExitDialog({required this.onNo, required this.onYes});
  final VoidCallback onNo;
  final VoidCallback onYes;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTokens.surface(context),
      surfaceTintColor: AppTokens.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.r16),
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        AppTokens.s20,
        AppTokens.s20,
        AppTokens.s12,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppTokens.s16,
        0,
        AppTokens.s16,
        AppTokens.s16,
      ),
      content: Text(
        'Do you want to exit the exam?',
        style: AppTokens.body(context).copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: _DialogBtn(
                label: 'No',
                filled: true,
                onTap: onNo,
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: _DialogBtn(
                label: 'Yes',
                filled: false,
                onTap: onYes,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DialogBtn extends StatelessWidget {
  const _DialogBtn({
    required this.label,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppTokens.accent(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTokens.r8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTokens.r8),
            border: filled ? null : Border.all(color: accent),
          ),
          child: Text(
            label,
            style: AppTokens.titleSm(context).copyWith(
              color: filled ? Colors.white : accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
