// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, use_build_context_synchronously, unused_local_variable

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/login/store/verify_otp_phone.dart';
import 'package:shusruta_lms/modules/new_exam_component/exam_screen.dart';
import 'package:shusruta_lms/modules/new_exam_component/store/exam_store.dart';
import 'package:shusruta_lms/modules/new_exam_component/widget/checkbox_widget.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/widgets/bottom_toast.dart';

/// Instructions & terms-agreement wall shown before starting a regular
/// MCQ exam.
///
/// Preserved public contract:
///   • `TestInstructionScreen({super.key, required type, required
///     testExamPaperListModel, required id, required examType,
///     required userExamId})`
///   • `startExamApiCall(store, testExamPaper, isPractice, type,
///     userExamIds)` unchanged — same MobX calls and post-success
///     navigation to `ExamScreen(type: "McqExam", ...)` via
///     `Navigator.pushReplacement`.
///   • Gate: student must tick "I have read the instructions." to
///     enable Start Exam; otherwise `BottomToast` with "Please agree to
///     instructions".
///   • examType-to-API mapping identical: "All Questions"/"Bookmarked
///     Questions" → testExamPaperListModel.examId, others → userExamId;
///     "Incorrect Questions" → "InCorrect Questions" on the wire.
///   • Labels verbatim: "Instructions", "Marking Scheme :",
///     "Correct Marks (+X)", "Incorrect Marks (-X)", "The Question
///     Palette shows the status of each question.", "Status Key",
///     "Navigation", "Click a question number in the Question Palette
///     to jump directly to it. Progress will be saved automatically.",
///     "I have read the instructions.", "Start Exam",
///     "Please agree to instructions".
///   • Status key items identical: Attempted / Marked for Review /
///     Attempted & Marked for Review / Not Visited / Skipped (same SVGs).
class TestInstructionScreen extends StatefulWidget {
  const TestInstructionScreen({
    super.key,
    required this.type,
    required this.testExamPaperListModel,
    required this.id,
    required this.examType,
    required this.userExamId,
  });
  final String type;
  final String examType;
  final TestExamPaperListModel testExamPaperListModel;
  final String id;
  final String userExamId;

  @override
  State<TestInstructionScreen> createState() => _TestInstructionScreenState();
}

class _TestInstructionScreenState extends State<TestInstructionScreen> {
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

  Future<void> _handleStart() async {
    if (!isAgree) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "Please agree to instructions",
        backgroundColor: ThemeManager.redAlert,
      );
      return;
    }
    showLoadingDialog(context);
    final examStore = Provider.of<ExamStore>(context, listen: false);
    final testCategoryStore =
        Provider.of<TestCategoryStore>(context, listen: false);
    final examIdForApi = (widget.examType == "All Questions" ||
            widget.examType == "Bookmarked Questions")
        ? widget.testExamPaperListModel.examId!
        : widget.userExamId;
    final typeForApi = widget.examType == "Incorrect Questions"
        ? "InCorrect Questions"
        : widget.examType;
    await examStore.onMcqQuestionListCall(examIdForApi, typeForApi).then((_) {
      Navigator.pop(context);
      startExamApiCall(
        testCategoryStore,
        widget.testExamPaperListModel,
        false,
        typeForApi,
        examIdForApi,
      );
    });
  }

  Column buildColumnLayout(
    BuildContext context,
    bool isAgree,
    ValueChanged<bool?> onStatusChanged,
  ) {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckBoxWithLabel(
          isShowMessage: false,
          label: 'I have read the instructions.',
          isChecked: isAgree,
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w500,
            color: AppTokens.ink(context),
          ),
          onStatusChanged: onStatusChanged,
        ),
        const SizedBox(height: AppTokens.s8),
        _PrimaryButton(
          isLoading: store.isLoading,
          label: "Start Exam",
          onTap: _handleStart,
        ),
      ],
    );
  }

  SizedBox buildRowLayout(
    BuildContext context,
    bool isAgree,
    ValueChanged<bool?> onStatusChanged,
  ) {
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
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w500,
                color: AppTokens.ink(context),
              ),
              onStatusChanged: onStatusChanged,
            ),
          ),
          SizedBox(
            width: 240,
            child: _PrimaryButton(
              isLoading: store.isLoading,
              label: "Start Exam",
              onTap: _handleStart,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      bottomNavigationBar: Observer(
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(0, -4),
                  blurRadius: 9,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s20,
              AppTokens.s12,
              AppTokens.s20,
              AppTokens.s20,
            ),
            child: (Platform.isWindows || Platform.isMacOS)
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
        },
      ),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                AppTokens.s16,
                AppTokens.s20,
                AppTokens.s16,
              ),
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: (Platform.isWindows || Platform.isMacOS)
                    ? null
                    : const BorderRadius.only(
                        topLeft: Radius.circular(AppTokens.r28),
                        topRight: Radius.circular(AppTokens.r28),
                      ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeading(context, "Instructions"),
                    const SizedBox(height: AppTokens.s8),
                    _BulletPoint(
                        text: widget.testExamPaperListModel.instruction ?? ""),
                    const SizedBox(height: AppTokens.s8),
                    const _BulletPoint(text: "Marking Scheme :"),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: AppTokens.s16),
                      child: Wrap(
                        spacing: AppTokens.s16,
                        runSpacing: AppTokens.s8,
                        children: [
                          _MarkChip(
                            iconAsset: "assets/image/correct_i.svg",
                            label:
                                "Correct Marks (+${widget.testExamPaperListModel.marksAwarded})",
                            color: ThemeManager.greenSuccess,
                          ),
                          _MarkChip(
                            iconAsset: "assets/image/wrong_i.svg",
                            label:
                                "Incorrect Marks (-${widget.testExamPaperListModel.marksDeducted})",
                            color: ThemeManager.redAlert,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTokens.s8),
                    const _BulletPoint(
                      text:
                          "The Question Palette shows the status of each question.",
                    ),
                    const SizedBox(height: AppTokens.s16),
                    _sectionHeading(context, "Status Key"),
                    const SizedBox(height: AppTokens.s8),
                    ListView.builder(
                      itemCount: items.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemBuilder: (BuildContext context, int index) {
                        return _StatusPoint(
                          title: items[index]['title'],
                          subtitle: items[index]['subtitle'],
                          iconPath: items[index]['imagePath'],
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    _sectionHeading(context, "Navigation"),
                    const SizedBox(height: AppTokens.s8),
                    const _BulletPoint(
                      text:
                          "Click a question number in the Question Palette to jump directly to it. Progress will be saved automatically.",
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(BuildContext context, String text) {
    return Text(
      text,
      style: AppTokens.titleSm(context).copyWith(
        fontWeight: FontWeight.w700,
        color: AppTokens.ink(context),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTokens.s8,
        left: AppTokens.s8,
        right: AppTokens.s20,
        bottom: AppTokens.s16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(AppTokens.r8),
            child: Container(
              height: AppTokens.s32,
              width: AppTokens.s32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              widget.testExamPaperListModel.examName ?? "",
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> startExamApiCall(
    TestCategoryStore store,
    TestExamPaperListModel? testExamPaper,
    bool? isPractice,
    String type,
    String userExamIds,
  ) async {
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
    await store.onCreateTestHistoryCall(testExamPaper?.examId ?? '', 'exam');
    await store.startCreateExam(
      examId,
      startTime,
      endTime,
      isPractice,
      type,
      userExamIds,
    );
    String? userExamId = store.startExam.value?.id;
    bool? isPracticeExam = store.startExam.value?.isPractice;
    if (store.startExam.value?.err?.message == null) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
          builder: (context) => ExamScreen(
            type: "McqExam",
            testExamPaper: widget.testExamPaperListModel,
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
        errorMessage: store.startExam.value?.err?.message ?? "",
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }
}

class _PrimaryButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.isLoading,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTokens.brand, AppTokens.brand2],
          ),
          borderRadius: BorderRadius.circular(AppTokens.r12),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : Text(
                label,
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SvgPicture.asset('assets/image/bullet_icon.svg'),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w500,
              color: AppTokens.muted(context),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _MarkChip extends StatelessWidget {
  final String iconAsset;
  final String label;
  final Color color;
  const _MarkChip({
    required this.iconAsset,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(iconAsset),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatusPoint extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconPath;
  const _StatusPoint({
    required this.title,
    required this.subtitle,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(iconPath),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.muted(context),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Retained top-level helper (was used by `ListView.builder` in the old
/// layout); kept for any external callers importing it.
Widget bulletPoints(String text) {
  return _BulletPoint(text: text);
}

Widget statusPoints(String text, String subtext, String path) {
  return _StatusPoint(title: text, subtitle: subtext, iconPath: path);
}
