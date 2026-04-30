// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names, dead_null_aware_expression, prefer_final_fields, unused_local_variable

import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:nuts_activity_indicator/nuts_activity_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/masterTest/sectionwisemasterTest/sections_list_screen.dart';
import 'package:shusruta_lms/modules/new_exam_component/widget/checkbox_widget.dart';
import 'package:shusruta_lms/modules/test/test_instruction_screen.dart';
import 'package:shusruta_lms/modules/widgets/custom_button.dart';

import '../../../app/routes.dart';
import '../../../helpers/app_tokens.dart';
import '../../../helpers/colors.dart';
import '../../dashboard/store/home_store.dart';
import '../../test/store/test_category_store.dart';
import '../../widgets/bottom_toast.dart';

/// Instruction screen for the section-wise master exam. Redesigned with
/// AppTokens while preserving every API contract:
///   • Constructor `StartSectionInstructionScreen({super.key, required id,
///     required type, testExamPaper, isPractice})`
///   • Static `route(RouteSettings)` factory with 4 keys: testExamPaper /
///     id / type / isPractice
///   • State field `isAgree=false` + 5-item `items` list (status legend)
///   • `buildColumnLayout(ctx, isAgree, onStatusChanged)` + `buildRowLayout`
///     helpers — mobile stacks the checkbox above the button, desktop
///     (Windows/MacOS) puts them side-by-side
///   • `_startMasterExamApiCall(store, testExamPaper, isPractice)` —
///     `store.onCreateTestHistoryCall(examId, 'mockExam')`, then
///     `store.startCreateMaterExam(examId, startTime, endTime, isPractice)`,
///     then on success -> `pushReplacement(CupertinoPageRoute ->
///     SectionListScreen(testExamPaper, userexamId, id, sectionsList: const
///     []))`; on error -> `BottomToast.showBottomToastOverlay`
///   • "Please agree to instructions" toast when user taps Start without
///     checking the box
///   • Uses top-level `statusPoints(text, subtext, path)` from
///     `test_instruction_screen.dart` so the legend rows stay identical to
///     the classic exam flow
///   • Section list pulled from `widget.testExamPaper?.sectionData` (per-
///     section Q count + duration)
///   • Sections preserved verbatim: Status Key / Exam Instructions /
///     Section Rules / Answer Submission / Evaluation / Important Reminders
///     / Conclusion
class StartSectionInstructionScreen extends StatefulWidget {
  final TestExamPaperListModel? testExamPaper;
  final String? id;
  final String? type;
  final bool? isPractice;
  const StartSectionInstructionScreen(
      {super.key,
      required this.id,
      required this.type,
      this.testExamPaper,
      this.isPractice});

  @override
  State<StartSectionInstructionScreen> createState() =>
      _StartSectionInstructionScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => StartSectionInstructionScreen(
        testExamPaper: arguments['testExamPaper'],
        id: arguments['id'],
        type: arguments['type'],
        isPractice: arguments['isPractice'],
      ),
    );
  }
}

class _StartSectionInstructionScreenState
    extends State<StartSectionInstructionScreen> {
  bool isAgree = false;
  final List<Map<String, dynamic>> items = [
    {
      'title': 'Attempted',
      'subtitle': 'Answered and submitted for evaluation.',
      'imagePath': 'assets/image/21.svg',
    },
    {
      'title': 'Marked for Review',
      'subtitle': 'Marked for review but unanswered.',
      'imagePath': 'assets/image/23.svg',
    },
    {
      'title': 'Attempted & Marked for Review',
      'subtitle': 'Answered but marked for review.',
      'imagePath': 'assets/image/32.svg',
    },
    {
      'title': 'Not Visited',
      'subtitle': 'Not opened yet.',
      'imagePath': 'assets/image/5.svg',
    },
    {
      'title': 'Skipped',
      'subtitle': 'Opened but not answered.',
      'imagePath': 'assets/image/0.svg',
    },
  ];

  // ---------------------------------------------------
  // Mobile: stacked (checkbox on top, button below)
  // ---------------------------------------------------
  Column buildColumnLayout(
      BuildContext context, bool isAgree, ValueChanged<bool?> onStatusChanged) {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckBoxWithLabel(
          isShowMessage: false,
          label: 'I have read the instructions.',
          isChecked: isAgree,
          style: AppTokens.body(context).copyWith(fontWeight: FontWeight.w500),
          onStatusChanged: onStatusChanged,
        ),
        const SizedBox(height: AppTokens.s8),
        _PrimaryCta(
          loading: store.isLoading,
          onPressed: () async {
            if (isAgree) {
              await _startMasterExamApiCall(
                  store, widget.testExamPaper, widget.isPractice);
            } else {
              BottomToast.showBottomToastOverlay(
                context: context,
                errorMessage: "Please agree to instructions",
                backgroundColor: ThemeManager.redAlert,
              );
            }
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------
  // Desktop: side-by-side (checkbox left, button right)
  // ---------------------------------------------------
  SizedBox buildRowLayout(
      BuildContext context, bool isAgree, ValueChanged<bool?> onStatusChanged) {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: CheckBoxWithLabel(
              isShowMessage: false,
              label: 'I have read the instructions.',
              isChecked: isAgree,
              style:
                  AppTokens.body(context).copyWith(fontWeight: FontWeight.w500),
              onStatusChanged: onStatusChanged,
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          SizedBox(
            width: 360,
            child: _PrimaryCta(
              loading: store.isLoading,
              onPressed: () async {
                if (isAgree) {
                  await _startMasterExamApiCall(
                      store, widget.testExamPaper, widget.isPractice);
                } else {
                  BottomToast.showBottomToastOverlay(
                    context: context,
                    errorMessage: "Please agree to instructions",
                    backgroundColor: ThemeManager.redAlert,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Platform.isWindows || Platform.isMacOS;
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      bottomNavigationBar: Observer(builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            boxShadow: AppTokens.shadow2(context),
            border: Border(
              top: BorderSide(color: AppTokens.border(context), width: 1),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            AppTokens.s16,
            AppTokens.s12,
            AppTokens.s16,
            AppTokens.s12 + MediaQuery.of(context).padding.bottom,
          ),
          child: isDesktop
              ? buildRowLayout(context, isAgree, (status) {
                  setState(() {
                    isAgree = status!;
                  });
                })
              : buildColumnLayout(context, isAgree, (status) {
                  setState(() {
                    isAgree = status!;
                  });
                }),
        );
      }),
      body: Column(
        children: [
          // ---------- gradient header ----------
          _HeaderBar(
            title: widget.testExamPaper?.examName ?? "",
            isDesktop: isDesktop,
            onBack: () => Navigator.pop(context),
          ),
          // ---------- rounded content ----------
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                AppTokens.s24,
                AppTokens.s20,
                AppTokens.s16,
              ),
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: isDesktop
                    ? null
                    : const BorderRadius.only(
                        topLeft: Radius.circular(AppTokens.r28),
                        topRight: Radius.circular(AppTokens.r28),
                      ),
              ),
              child: Observer(
                builder: (BuildContext context) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SectionHeader(label: "Status Key"),
                        const SizedBox(height: AppTokens.s8),
                        ListView.builder(
                          itemCount: items.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemBuilder: (BuildContext context, int index) {
                            return statusPoints(
                              items[index]['title'],
                              items[index]['subtitle'],
                              items[index]['imagePath'],
                            );
                          },
                        ),
                        const SizedBox(height: AppTokens.s8),
                        _SectionHeader(label: "Exam Instructions"),
                        const SizedBox(height: AppTokens.s12),
                        Text(
                          "Please read the instructions below carefully before starting the exam.",
                          style:
                              AppTokens.body(context).copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppTokens.s8),
                        _Bullet(
                          text:
                              "The exam consists of Total Q${widget.testExamPaper?.totalQuestions ?? ''} – Time(${widget.testExamPaper?.timeDuration ?? ''})",
                        ),
                        _Bullet(
                          text:
                              "Exam is divide into multiple time-bound sections.",
                        ),
                        _Bullet(text: "Section Details"),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppTokens.s20,
                            top: AppTokens.s4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(
                              widget.testExamPaper?.sectionData?.length ?? 0,
                              (index) {
                                final sec =
                                    widget.testExamPaper?.sectionData?[index];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppTokens.s8,
                                  ),
                                  child: Text(
                                    "${index + 1}. Section ${sec?.section ?? ''} – Q(${sec?.questionCount ?? 0}) – Time(${sec?.timeDuration ?? ''})",
                                    style: AppTokens.body(context).copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTokens.s16),
                        _SubSectionHeader(label: "Section Rules"),
                        const SizedBox(height: AppTokens.s8),
                        _RuleBlock(
                          number: "1.",
                          title: "Time-Bound Sections :",
                          bullets: const [
                            "Exam is divide into multiple time-bound sections.",
                            "You cannot move to the next section until the current section’s time is up.",
                          ],
                        ),
                        _RuleBlock(
                          number: "2.",
                          title: "Automatic Progression :",
                          bullets: const [
                            "The next section will start automatically once the current section’s time ends.",
                          ],
                        ),
                        const SizedBox(height: AppTokens.s12),
                        _SubSectionHeader(label: "Answer Submission"),
                        const SizedBox(height: AppTokens.s8),
                        _RuleBlock(
                          number: "1.",
                          title: "Automatic Submission:",
                          bullets: const [
                            "All answers in a section will be automatically submitted when the time for that section ends.",
                            "Ensure all your answers are finalized before the time runs out.",
                          ],
                        ),
                        const SizedBox(height: AppTokens.s12),
                        _SubSectionHeader(label: "Evaluation"),
                        const SizedBox(height: AppTokens.s8),
                        _RuleBlock(
                          number: "1.",
                          title: "Marking Scheme :",
                          bullets: [
                            "(+${widget.testExamPaper?.marksAwarded ?? 0} Correct) | (-${widget.testExamPaper?.marksDeducted ?? 0} Incorrect)",
                            "Questions marked for review will be evaluated as per the marking scheme.",
                          ],
                        ),
                        const SizedBox(height: AppTokens.s12),
                        _SubSectionHeader(label: "Important Reminders"),
                        const SizedBox(height: AppTokens.s8),
                        _RuleBlock(
                          number: "1.",
                          title: "No Backtracking:",
                          bullets: const [
                            "After the time for a section ends, you will not be able to revisit or change your answers in that section.",
                          ],
                        ),
                        _RuleBlock(
                          number: "2.",
                          title: "Focus :",
                          bullets: const [
                            "Focus on completing each section within the given time to maximize your score.",
                            "Manage your time effectively to ensure all questions are attempted.",
                          ],
                        ),
                        const SizedBox(height: AppTokens.s12),
                        _SubSectionHeader(label: "Conclusion"),
                        const SizedBox(height: AppTokens.s8),
                        _Bullet(
                          text:
                              "Please ensure you understand these instructions thoroughly.",
                        ),
                        _Bullet(text: "Good luck with your exam!"),
                        const SizedBox(height: AppTokens.s24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startMasterExamApiCall(TestCategoryStore store,
      TestExamPaperListModel? testExamPaper, isPractice) async {
    await store.onCreateTestHistoryCall(
        widget.testExamPaper?.examId ?? '', 'mockExam');
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
    await store.startCreateMaterExam(examId, startTime, endTime, isPractice);
    String? userExamId = store.startMasterExam.value?.id;
    bool? isPracticeExam = store.startMasterExam.value?.isPractice;
    if (store.startMasterExam.value?.err?.message == null) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
          builder: (context) => SectionListScreen(
            testExamPaper: widget.testExamPaper,
            userexamId: userExamId,
            id: widget.id,
            sectionsList: const [],
          ),
        ),
      );
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: store.startMasterExam.value?.err?.message ?? "",
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }
}

// ============================================================================
//                                 PRIMITIVES
// ============================================================================

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.title,
    required this.isDesktop,
    required this.onBack,
  });
  final String title;
  final bool isDesktop;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppTokens.s12,
        (isDesktop ? AppTokens.s16 : MediaQuery.of(context).padding.top) +
            AppTokens.s8,
        AppTokens.s16,
        AppTokens.s16,
      ),
      child: Row(
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.titleMd(context).copyWith(
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppTokens.accent(context),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        Text(
          label,
          style: AppTokens.titleMd(context).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SubSectionHeader extends StatelessWidget {
  const _SubSectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTokens.titleSm(context).copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppTokens.ink2(context),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              text,
              style: AppTokens.body(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleBlock extends StatelessWidget {
  const _RuleBlock({
    required this.number,
    required this.title,
    required this.bullets,
  });
  final String number;
  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$number ",
                style: AppTokens.body(context)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: Text(
                  title,
                  style: AppTokens.body(context)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppTokens.s16, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bullets.map((b) => _Bullet(text: b)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTokens.r8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: loading ? null : onPressed,
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTokens.brand, AppTokens.brand2],
            ),
            borderRadius: BorderRadius.circular(AppTokens.r8),
            boxShadow: AppTokens.shadow1(context),
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
                    "Start Exam",
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
