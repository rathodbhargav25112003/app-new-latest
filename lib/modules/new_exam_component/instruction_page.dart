// ignore_for_file: deprecated_member_use, unnecessary_null_comparison, use_build_context_synchronously, dead_null_aware_expression

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/new_exam_component/exam_screen.dart';
import 'package:shusruta_lms/modules/new_exam_component/widget/checkbox_widget.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/widgets/bottom_toast.dart';
import 'package:shusruta_lms/modules/widgets/custom_button.dart';

/// Pre-exam instructions screen. Reached before every mock / practice
/// master exam launch and also gates the actual `ExamScreen` push
/// behind the "I have read the instructions" checkbox.
///
/// Preserved public contract:
///   • Constructor `InstructionScreen({super.key, required String type,
///     required TestExamPaperListModel testExamPaperListModel,
///     required bool showPredictive, required bool isTrend})`
///     — fields, order, and types unchanged.
///   • `startMasterExamApiCall(store, testExamPaper, isPractice)` is
///     preserved verbatim (including its 3 store API calls, TestData
///     reconstruction, and downstream navigation):
///       - `store.onCreateTestHistoryCall(examId, 'mockExam')`
///       - `store.onGetMaterExamPaperDataApiCall(examId)`
///       - `store.startCreateMaterExam(examId, startTime, endTime,
///          isPractice)`
///   • Mock branch: `Navigator.pushReplacement(CupertinoPageRoute →
///     ExamScreen(type: "MockExam", testExamPaper, id, userExamId,
///     showPredictive, isTrend: false))`.
///   • Practice branch: `Navigator.pushReplacementNamed(
///     Routes.practiceMasterTestExams, arguments: 7-key map with
///     testData / userexamId / isPracticeExam / id / category_id /
///     type / showPredictive)` — keys preserved including the lower-
///     case "userexamId" typo.
///   • Error toast path still uses
///     `BottomToast.showBottomToastOverlay` with the same three
///     messages ("Please agree to instructions", backend err.message,
///     "Exam Paper Not Found!").
///   • Platform-dependent layout kept: Windows/macOS gets flat header
///     (no 28-radius corners) and compact padding; mobile keeps the
///     top radius ≈ 28 and extra top padding.
///   • Status-key list, "Marking Scheme :", "Navigation" copy, bullet/
///     status icon asset paths, and the 5-row items[] array are all
///     preserved byte-for-byte.
class InstructionScreen extends StatefulWidget {
  const InstructionScreen({
    super.key,
    required this.type,
    required this.testExamPaperListModel,
    required this.showPredictive,
    required this.isTrend,
  });

  final String type;
  final TestExamPaperListModel testExamPaperListModel;
  final bool showPredictive;
  final bool isTrend;

  @override
  State<InstructionScreen> createState() => _InstructionScreenState();
}

class _InstructionScreenState extends State<InstructionScreen> {
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

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      bottomNavigationBar: Observer(
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              boxShadow: AppTokens.shadow2(context),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s20,
              AppTokens.s20,
              AppTokens.s20,
              AppTokens.s24,
            ),
            child: Column(
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
                  onStatusChanged: (status) {
                    setState(() {
                      isAgree = status!;
                    });
                  },
                ),
                const SizedBox(height: AppTokens.s8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: CustomButton(
                    radius: 4.91,
                    isLoading: store.isLoading,
                    height: 48,
                    textColor: Colors.white,
                    bgColor: AppTokens.brand,
                    fontSize: 14,
                    onPressed: () {
                      if (isAgree) {
                        startMasterExamApiCall(
                          store,
                          widget.testExamPaperListModel,
                          widget.testExamPaperListModel.isPracticeMode,
                        );
                      } else {
                        BottomToast.showBottomToastOverlay(
                          context: context,
                          errorMessage: 'Please agree to instructions',
                          backgroundColor: AppTokens.danger(context),
                        );
                      }
                    },
                    buttonText: 'Start Exam',
                  ),
                ),
              ],
            ),
          );
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTokens.brand, AppTokens.brand2],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: _isDesktop
                  ? const EdgeInsets.symmetric(
                      vertical: AppTokens.s20,
                      horizontal: AppTokens.s24,
                    )
                  : const EdgeInsets.only(
                      top: AppTokens.s32 + AppTokens.s24,
                      left: AppTokens.s24,
                      right: AppTokens.s24,
                      bottom: AppTokens.s12,
                    ),
              child: Row(
                children: [
                  IconButton(
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppTokens.s16),
                  Expanded(
                    child: Text(
                      widget.testExamPaperListModel.examName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTokens.titleSm(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(
                  left: AppTokens.s24,
                  right: AppTokens.s24,
                  top: AppTokens.s12,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  borderRadius: _isDesktop
                      ? null
                      : const BorderRadius.only(
                          topLeft: Radius.circular(AppTokens.r28),
                          topRight: Radius.circular(AppTokens.r28),
                        ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: AppTokens.s12),
                      Text(
                        'Instructions',
                        style: AppTokens.titleMd(context).copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: AppTokens.s12),
                      bulletPoints(
                        widget.testExamPaperListModel.instruction ?? '',
                      ),
                      const SizedBox(height: AppTokens.s12),
                      bulletPoints('Marking Scheme :'),
                      const SizedBox(height: AppTokens.s4),
                      _MarkingSchemeRow(
                        awarded:
                            widget.testExamPaperListModel.marksAwarded ?? 0,
                        deducted:
                            widget.testExamPaperListModel.marksDeducted ?? 0,
                      ),
                      const SizedBox(height: AppTokens.s12),
                      bulletPoints(
                        'The Question Palette shows the status of each question.',
                      ),
                      const SizedBox(height: AppTokens.s16),
                      Text(
                        'Status Key',
                        style: AppTokens.titleMd(context).copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: AppTokens.s12),
                      ListView.builder(
                        itemCount: items.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          return statusPoints(
                            items[index]['title'],
                            items[index]['subtitle'],
                            items[index]['imagePath'],
                          );
                        },
                      ),
                      const SizedBox(height: AppTokens.s4),
                      Text(
                        'Navigation',
                        style: AppTokens.titleMd(context).copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: AppTokens.s12),
                      bulletPoints(
                        'Click a question number in the Question Palette to jump directly to it. Progress will be saved automatically.',
                      ),
                      const SizedBox(height: AppTokens.s24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> startMasterExamApiCall(
    TestCategoryStore store,
    TestExamPaperListModel? testExamPaper,
    isPractice,
  ) async {
    String examId = testExamPaper?.examId ?? '';
    DateTime now = DateTime.now();
    String startTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(now);
    String timeDuration = testExamPaper?.timeDuration ?? '';
    List<String> timeParts = timeDuration.split(':');
    Duration duration = Duration(
      hours: int.parse(timeParts[0]),
      minutes: int.parse(timeParts[1]),
      seconds: int.parse(timeParts[2]),
    );
    DateTime startDateTime = DateTime.parse(startTime);
    DateTime endDateTime = startDateTime.add(duration);
    String endTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(endDateTime);
    await store.onCreateTestHistoryCall(
        widget.testExamPaperListModel.examId ?? '', 'mockExam');
    await store
        .onGetMaterExamPaperDataApiCall(
            widget.testExamPaperListModel.examId ?? '')
        .then((_) async {
      widget.testExamPaperListModel.test =
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
    if (widget.testExamPaperListModel.test?.isNotEmpty ?? false) {
      if (isPractice == false) {
        if (store.startMasterExam.value?.err?.message == null) {
          Navigator.pushReplacement(
              context,
              CupertinoPageRoute(
                builder: (context) => ExamScreen(
                  type: 'MockExam',
                  testExamPaper: widget.testExamPaperListModel,
                  id: examId,
                  userExamId: userExamId!,
                  showPredictive: widget.showPredictive ?? false,
                  isTrend: false,
                ),
              ));
        } else {
          BottomToast.showBottomToastOverlay(
            context: context,
            errorMessage: store.startMasterExam.value?.err?.message ?? '',
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      } else {
        if (store.startExam.value?.err?.message == null) {
          Navigator.of(context).pushReplacementNamed(
              Routes.practiceMasterTestExams,
              arguments: {
                'testData': widget.testExamPaperListModel,
                'userexamId': userExamId,
                'isPracticeExam': isPracticeExam,
                'id': widget.testExamPaperListModel.examId,
                'category_id': testExamPaper?.categoryId,
                'type': widget.type,
                'showPredictive': widget.showPredictive,
              });
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

class _MarkingSchemeRow extends StatelessWidget {
  const _MarkingSchemeRow({required this.awarded, required this.deducted});
  final num awarded;
  final num deducted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: AppTokens.s16),
        SvgPicture.asset('assets/image/correct_i.svg'),
        const SizedBox(width: AppTokens.s4),
        Text(
          'Correct Marks (+$awarded)',
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w500,
            color: AppTokens.success(context),
          ),
        ),
        const SizedBox(width: AppTokens.s16),
        SvgPicture.asset('assets/image/wrong_i.svg'),
        const SizedBox(width: AppTokens.s4),
        Text(
          'Incorrect Marks (-$deducted)',
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w500,
            color: AppTokens.danger(context),
          ),
        ),
      ],
    );
  }
}

/// Public helper retained — used internally and potentially by
/// external callers that imported it directly.
Widget bulletPoints(String text) {
  return Builder(
    builder: (context) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SvgPicture.asset('assets/image/bullet_icon.svg'),
          ),
          const SizedBox(width: AppTokens.s8),
          Flexible(
            child: Text(
              text,
              style: AppTokens.body(context).copyWith(
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: AppTokens.muted(context),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Public helper retained — still takes the same (title, subtitle,
/// asset-path) triple for backward compatibility with callers that
/// imported it directly.
Widget statusPoints(String text, String subtext, String path) {
  return Builder(
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppTokens.s16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(path),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTokens.ink(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtext,
                    style: AppTokens.caption(context).copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      color: AppTokens.muted(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
