// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, use_build_context_synchronously, non_constant_identifier_names

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:shusruta_lms/modules/quiztest/model/quiz_model.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/modules/widgets/bottom_toast.dart';

/// "Quiz Of The Day" start confirmation bottom sheet — shows time
/// duration, marking scheme, and a "Start the Quiz" CTA that creates
/// the quiz attempt and pushes to `Routes.quizTestExamScreen`.
///
/// Preserved public contract:
///   • `CustomStartQuizBottomSheet({super.key, required this.store})`
///     with `final TestCategoryStore store`.
///   • `_startExamApiCall(TestCategoryStore store)` builds `startTime`
///     / `endTime` from `getTodayQuizData.value?.timeDuration`
///     (`HH:mm:ss` parse), calls
///     `onGetQuizExamPaperDataApiCall(quizId)` then
///     `startCreateQuizExam(examId, startTime, endTime)`.
///   • Maps `store.quizExamPaperData` into `TestData` with field-for-
///     field preservation (questionImg, explanationImg, sId, examId,
///     questionText, correctOption, explanation, created_at,
///     updated_at, id, optionsData (answerImg/answerTitle/sId/value),
///     questionNumber, statusColor, txtColor, bookmarks).
///   • Route push args preserved: `testData`, `userexamId`,
///     `isPracticeExam`, `id` (= quizId), `type: 'topic'`.
///   • Error toasts preserved byte-for-byte:
///     `store.startQuizExam.value?.err?.message ?? ""` and
///     `"Exam Paper Not Found!"`.
///   • Label strings preserved: 'Quiz Of The Day',
///     'Time Duration : ', 'Marking Scheme : ',
///     'Read the questions carefully before answering. All the Best!',
///     'Start the Quiz'.
class CustomStartQuizBottomSheet extends StatefulWidget {
  final TestCategoryStore store;
  const CustomStartQuizBottomSheet({super.key, required this.store});

  @override
  State<CustomStartQuizBottomSheet> createState() =>
      _CustomStartQuizBottomSheetState();
}

class _CustomStartQuizBottomSheetState
    extends State<CustomStartQuizBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Platform.isWindows || Platform.isMacOS;
    return FractionallySizedBox(
      child: FittedBox(
        fit: BoxFit.fitWidth,
        child: Container(
          width: MediaQuery.of(context).size.width,
          constraints: isDesktop
              ? const BoxConstraints(maxWidth: Dimensions.WEB_MAX_WIDTH * 0.4)
              : null,
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: isDesktop
                ? BorderRadius.circular(AppTokens.r20)
                : const BorderRadius.vertical(
                    top: Radius.circular(AppTokens.r20),
                  ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: AppTokens.s20),
              if (Platform.isAndroid || Platform.isIOS)
                Container(
                  width: AppTokens.s32 + AppTokens.s16,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTokens.border(context),
                    borderRadius: BorderRadius.circular(AppTokens.r8),
                  ),
                ),
              if (Platform.isAndroid || Platform.isIOS)
                const SizedBox(height: AppTokens.s16),
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.quiz_rounded,
                  color: AppTokens.accent(context),
                  size: 28,
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              Text(
                'Quiz Of The Day',
                style: AppTokens.titleSm(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTokens.ink(context),
                ),
              ),
              const SizedBox(height: AppTokens.s24),
              Container(
                padding: const EdgeInsets.all(AppTokens.s16),
                decoration: BoxDecoration(
                  color: AppTokens.surface2(context),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  border: Border.all(color: AppTokens.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Time Duration : ',
                          style: AppTokens.body(context).copyWith(
                            color: AppTokens.muted(context),
                          ),
                        ),
                        Text(
                          '${widget.store.getTodayQuizData.value?.timeDuration}',
                          style: AppTokens.body(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.s8),
                    Row(
                      children: [
                        Text(
                          'Marking Scheme : ',
                          style: AppTokens.body(context).copyWith(
                            color: AppTokens.muted(context),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTokens.successSoft(context),
                            borderRadius:
                                BorderRadius.circular(AppTokens.r8),
                          ),
                          child: Text(
                            '+${widget.store.getTodayQuizData.value?.marksAwarded}',
                            style: AppTokens.caption(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTokens.success(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.s8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTokens.dangerSoft(context),
                            borderRadius:
                                BorderRadius.circular(AppTokens.r8),
                          ),
                          child: Text(
                            '-${widget.store.getTodayQuizData.value?.marksDeducted}',
                            style: AppTokens.caption(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTokens.danger(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.s16),
              Text(
                'Read the questions carefully before answering. All the Best!',
                textAlign: TextAlign.center,
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.muted(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTokens.s20),
              InkWell(
                onTap: () async {
                  await _startExamApiCall(widget.store);
                },
                borderRadius: BorderRadius.circular(AppTokens.r12),
                child: Container(
                  height: AppTokens.s32 + AppTokens.s20,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTokens.brand, AppTokens.brand2],
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                    boxShadow: AppTokens.shadow2(context),
                  ),
                  child: Text(
                    "Start the Quiz",
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startExamApiCall(TestCategoryStore store) async {
    String examId = store.getTodayQuizData.value?.quizId ?? "";
    DateTime now = DateTime.now();
    String startTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(now);
    String timeDuration = store.getTodayQuizData.value?.timeDuration ?? "";
    debugPrint("timeDuration:$timeDuration");
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
        .onGetQuizExamPaperDataApiCall(
            widget.store.getTodayQuizData.value?.quizId ?? "")
        .then((_) async {
      widget.store.getTodayQuizData.value?.test =
          store.quizExamPaperData.map((examPaperData) {
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
    await store.startCreateQuizExam(examId, startTime, endTime);
    String? userExamId = store.startQuizExam.value?.id;
    bool? isPracticeExam = store.startQuizExam.value?.isPractice;
    if (widget.store.getTodayQuizData.value?.test?.isNotEmpty ?? false) {
      if (store.startQuizExam.value?.err?.message == null) {
        Navigator.of(context).pushNamed(Routes.quizTestExamScreen, arguments: {
          'testData': store.getTodayQuizData.value,
          'userexamId': userExamId,
          'isPracticeExam': isPracticeExam,
          'id': store.getTodayQuizData.value?.quizId,
          'type': 'topic'
        });
      } else {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: store.startQuizExam.value?.err?.message ?? "",
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "Exam Paper Not Found!",
        backgroundColor: AppTokens.danger(context),
      );
    }
  }
}
