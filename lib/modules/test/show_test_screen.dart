// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, avoid_print, non_constant_identifier_names, dead_code, unused_element, prefer_final_fields

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/new_exam_component/instruction_page.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/test/test_instruction_screen.dart';
import 'package:shusruta_lms/modules/test/test_mode_card.dart';
import 'package:shusruta_lms/modules/widgets/bottom_practice_sheet.dart';
import 'package:shusruta_lms/modules/widgets/custom_button.dart';
import 'package:shusruta_lms/modules/widgets/custom_test_bottom_sheet.dart';
import 'package:shusruta_lms/modules/widgets/no_access_alert_dialog.dart';
import 'package:shusruta_lms/modules/widgets/no_access_bottom_sheet.dart';

/// Test overview — total question count card, practice-mode summary
/// (running or start fresh), and test-mode entry (attempts list or
/// "Attempt Now").
///
/// Preserved public contract:
///   • `ShowTestScreen({super.key, required testExamPaperListModel,
///     required type, required id})`
///   • Static `route(RouteSettings)` reads `{testExamPaperListModel,
///     type, id}`.
///   • `store.onExamAttemptList(testExamPaperListModel.sid!)` in
///     initState.
///   • Back button → `Navigator.pushReplacementNamed(
///     Routes.selectTestList, arguments: {id, type})`.
///   • `startPractice()` — access-gated flow:
///       - isAccess && exitUserExamId == "" → CustomTestBottomSheet
///         (desktop AlertDialog / mobile bottom sheet).
///       - isAccess && exitUserExamId != "" → PracticeBottomSheet
///         (desktop AlertDialog / mobile bottom sheet).
///       - !isAccess → NoAccessAlertDialog / NoAccessBottomSheet with
///         `planId`, `day`, `isFree`.
///   • "Attempt Now" pushes CupertinoPageRoute to TestInstructionScreen
///     with `userExamId: store.userExamId ?? ""`,
///     `type: widget.type`, `examType: "All Questions"`,
///     `id: widget.id`, `testExamPaperListModel`.
///   • Labels verbatim: "Questions", "Practice Mode",
///     "Last Practice Session : {time}", "Attempted", "Unattempted",
///     "Correct", "Incorrect", "Bookmarked", "Resume Practice",
///     "Practice not started yet", "Begin now to improve!",
///     "Start Practice", "Test Mode", "Test not started yet",
///     "Start now to track your progress!", "Attempt Now".
///   • Top-level helpers retained: `buildDetail(label, value, path)`,
///     `buildStat(label, value, path)`.
class ShowTestScreen extends StatefulWidget {
  const ShowTestScreen({
    super.key,
    required this.testExamPaperListModel,
    required this.type,
    required this.id,
  });

  final TestExamPaperListModel testExamPaperListModel;
  final String type;
  final String id;

  @override
  State<ShowTestScreen> createState() => _ShowTestScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => ShowTestScreen(
        testExamPaperListModel: arguments['testExamPaperListModel'],
        type: arguments['type'],
        id: arguments['id'],
      ),
    );
  }
}

class _ShowTestScreenState extends State<ShowTestScreen> {
  bool _hasShownBottomSheet = false;

  @override
  void initState() {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    store.onExamAttemptList(widget.testExamPaperListModel.sid!);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(widget.testExamPaperListModel.sid!);
    final bool isDesktop = Platform.isWindows || Platform.isMacOS;
    final store = Provider.of<TestCategoryStore>(context);

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                AppTokens.s20,
                AppTokens.s20,
                AppTokens.s20,
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
              child: Observer(builder: (_) {
                if (store.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTokens.accent(context),
                    ),
                  );
                }
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuestionCountCard(context, store),
                      const SizedBox(height: AppTokens.s12),
                      if (widget.testExamPaperListModel.isPracticeMode! &&
                          store.mcqExamData.value!.isPractice) ...[
                        _buildActivePractice(context, store),
                        const SizedBox(height: AppTokens.s12),
                      ],
                      if (widget.testExamPaperListModel.isPracticeMode! &&
                          !store.mcqExamData.value!.isPractice) ...[
                        _buildIdlePractice(context),
                        const SizedBox(height: AppTokens.s12),
                      ],
                      if (store.mcqExamData.value!.isAttempt) ...[
                        TestModeCard(
                          id: widget.id,
                          type: widget.type,
                          testExamPaperListModel: widget.testExamPaperListModel,
                          data: store.mcqExamData.value!,
                        ),
                      ],
                      if (!store.mcqExamData.value!.isAttempt) ...[
                        _buildIdleTest(context, store),
                      ],
                      const SizedBox(height: AppTokens.s24),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTokens.s8,
        (Platform.isWindows || Platform.isMacOS)
            ? AppTokens.s16
            : MediaQuery.of(context).padding.top + AppTokens.s8,
        AppTokens.s20,
        AppTokens.s20,
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
            onTap: () {
              Navigator.of(context).pushReplacementNamed(
                Routes.selectTestList,
                arguments: {'id': widget.id, 'type': widget.type},
              );
            },
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCountCard(BuildContext context, TestCategoryStore store) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s16,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        border: Border.all(color: AppTokens.border(context)),
        borderRadius: BorderRadius.circular(AppTokens.r16),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accent(context),
              borderRadius: BorderRadius.circular(AppTokens.r12),
            ),
            child: SvgPicture.asset(
              "assets/image/question.svg",
              height: 18,
              width: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${store.mcqExamData.value!.totalQuestions}",
                style: AppTokens.titleSm(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink(context),
                ),
              ),
              Text(
                "Questions",
                style: AppTokens.caption(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppTokens.muted(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivePractice(BuildContext context, TestCategoryStore store) {
    final pr = store.mcqExamData.value!.practiceReport;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        border: Border.all(color: AppTokens.border(context)),
        borderRadius: BorderRadius.circular(AppTokens.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s16,
              AppTokens.s12,
              AppTokens.s16,
              AppTokens.s4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Practice Mode",
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  "Last Practice Session : ${store.mcqExamData.value!.lastPracticeTime}",
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.muted(context),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s16,
              AppTokens.s12,
              AppTokens.s16,
              AppTokens.s16,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: buildDetail(
                        "Attempted",
                        "${pr.attemptedQuestion}",
                        "assets/image/attempted1.svg",
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: buildDetail(
                        "Unattempted",
                        "${pr.skippedAnswersCount}",
                        "assets/image/skipped1.svg",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: buildDetail(
                        "Correct",
                        "${pr.correctAnswersCount}",
                        "assets/image/correct.svg",
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: buildDetail(
                        "Incorrect",
                        "${pr.incorrectAnswersCount}",
                        "assets/image/incorrect.svg",
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: buildDetail(
                        "Bookmarked",
                        "${pr.bookmarkCount}",
                        "assets/image/bookmark2.svg",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s16),
                CustomButton(
                  radius: AppTokens.r8.toDouble(),
                  height: 42,
                  width:
                      (Platform.isMacOS || Platform.isWindows) ? 500 : null,
                  textColor: Colors.white,
                  bgColor: AppTokens.accent(context),
                  onPressed: () async {
                    startPractice();
                  },
                  buttonText: "Resume Practice",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdlePractice(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        border: Border.all(color: AppTokens.border(context)),
        borderRadius: BorderRadius.circular(AppTokens.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s16,
              AppTokens.s12,
              AppTokens.s16,
              AppTokens.s8,
            ),
            child: Text(
              "Practice Mode",
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
            ),
          ),
          Divider(height: 1, color: AppTokens.border(context)),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s16,
              vertical: AppTokens.s16,
            ),
            child: Column(
              children: [
                SvgPicture.asset("assets/image/attemp.svg"),
                const SizedBox(height: AppTokens.s12),
                Text(
                  "Practice not started yet",
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTokens.ink(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  "Begin now to improve!",
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.muted(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                CustomButton(
                  radius: AppTokens.r8.toDouble(),
                  height: 42,
                  width:
                      (Platform.isMacOS || Platform.isWindows) ? 500 : null,
                  textColor: Colors.white,
                  bgColor: AppTokens.accent(context),
                  onPressed: () async {
                    startPractice();
                  },
                  buttonText: "Start Practice",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleTest(BuildContext context, TestCategoryStore store) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        border: Border.all(color: AppTokens.border(context)),
        borderRadius: BorderRadius.circular(AppTokens.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s16,
              AppTokens.s12,
              AppTokens.s16,
              AppTokens.s8,
            ),
            child: Text(
              "Test Mode",
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
            ),
          ),
          Divider(height: 1, color: AppTokens.border(context)),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s16,
              vertical: AppTokens.s16,
            ),
            child: Column(
              children: [
                SvgPicture.asset("assets/image/attemp.svg"),
                const SizedBox(height: AppTokens.s12),
                Text(
                  "Test not started yet",
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTokens.ink(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  "Start now to track your progress!",
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.muted(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                CustomButton(
                  radius: AppTokens.r8.toDouble(),
                  height: 42,
                  width:
                      (Platform.isMacOS || Platform.isWindows) ? 500 : null,
                  textColor: Colors.white,
                  bgColor: AppTokens.accent(context),
                  onPressed: () async {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => TestInstructionScreen(
                          userExamId: store.userExamId ?? "",
                          type: widget.type,
                          examType: "All Questions",
                          id: widget.id,
                          testExamPaperListModel: widget.testExamPaperListModel,
                        ),
                      ),
                    );
                  },
                  buttonText: "Attempt Now",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void startPractice() {
    if (widget.testExamPaperListModel.isAccess == true) {
      if (widget.testExamPaperListModel.exitUserExamId == "") {
        if (Platform.isWindows || Platform.isMacOS) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                actionsPadding: EdgeInsets.zero,
                actions: [
                  CustomTestBottomSheet(
                    context,
                    widget.testExamPaperListModel,
                    widget.id,
                    widget.type,
                    isUseHightWidthWindow: false,
                    true,
                  ),
                ],
              );
            },
          );
        } else {
          showModalBottomSheet<void>(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTokens.r28),
              ),
            ),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            context: context,
            builder: (BuildContext context) {
              return CustomTestBottomSheet(
                context,
                widget.testExamPaperListModel,
                widget.id,
                widget.type,
                true,
              );
            },
          );
        }
      } else {
        if (Platform.isWindows || Platform.isMacOS) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                actionsPadding: EdgeInsets.zero,
                actions: [
                  PracticeBottomSheet(
                    context,
                    widget.testExamPaperListModel,
                    widget.id,
                    widget.type,
                    true,
                    "",
                    "",
                    null,
                    "",
                    false,
                  ),
                ],
              );
            },
          );
        } else {
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
              return PracticeBottomSheet(
                context,
                widget.testExamPaperListModel,
                widget.id,
                widget.type,
                true,
                "",
                "",
                null,
                "",
                false,
              );
            },
          );
        }
      }
    } else {
      if (Platform.isWindows || Platform.isMacOS) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppTokens.scaffold(context),
              insetPadding: const EdgeInsets.symmetric(horizontal: 100),
              actionsPadding: EdgeInsets.zero,
              actions: [
                NoAccessAlertDialog(
                  planId: widget.testExamPaperListModel.plan_id ?? "",
                  day: int.parse(widget.testExamPaperListModel.day ?? "0"),
                  isFree: widget.testExamPaperListModel.isfreeTrail!,
                ),
              ],
            );
          },
        );
      } else {
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
            return NoAccessBottomSheet(
              planId: widget.testExamPaperListModel.plan_id ?? "",
              day: int.parse(widget.testExamPaperListModel.day ?? "0"),
              isFree: widget.testExamPaperListModel.isfreeTrail!,
            );
          },
        );
      }
    }
  }
}

/// Retained public helper — 2-col stat with leading SVG, value on top,
/// caption below. Used inside practice summary.
Widget buildDetail(String label, String value, String path) {
  return Builder(
    builder: (context) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        border: Border.all(color: AppTokens.border(context)),
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(path, height: 28, width: 28),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.muted(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Retained public helper — horizontal stat row with leading SVG and
/// (label, value) stack.
Widget buildStat(String label, String value, String path) {
  return Builder(
    builder: (context) => Row(
      children: [
        SvgPicture.asset(path, height: 25, width: 25),
        const SizedBox(width: AppTokens.s8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTokens.caption(context).copyWith(
                color: AppTokens.muted(context),
              ),
            ),
            Text(
              value,
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppTokens.ink(context),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
