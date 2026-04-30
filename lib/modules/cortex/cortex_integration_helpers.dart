// CortexIntegrationHelpers — drop-in helpers the dev can call from
// existing screens (test_exam_screen.dart, test_report_details_screen.dart,
// dashboard, etc.) without touching long, complex files.
//
// All you need to do in the existing screens:
//
//   1. Replace the legacy "Ask Cortex AI" button onTap with:
//        CortexIntegrationHelpers.openAskCortex(
//          context,
//          questionId: q.id,
//          examId: examId,
//          userExamId: userExamId,
//        );
//
//   2. On the result-screen wrong-answer row, add a button:
//        CortexIntegrationHelpers.showMistakeDebrief(
//          context,
//          questionId: q.id,
//          selectedOption: userAnswer,
//          correctOption: correctAnswer,
//          examId: examId,
//          userExamId: userExamId,
//        );
//
//   3. Below each result row, drop:
//        CortexIntegrationHelpers.relatedMcqs(questionId: q.id)
//
// That's it. No store wiring needed in the host screen — these helpers
// resolve the CortexStore via Provider internally.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'cortex_chat_screen.dart';
import 'store/cortex_store.dart';
import 'widgets/mistake_debrief_sheet.dart';
import 'widgets/related_mcqs_carousel.dart';
import '../../models/cortex_models.dart';

class CortexIntegrationHelpers {
  CortexIntegrationHelpers._();

  /// Opens the multi-turn Cortex chat for the given MCQ. If a chat already
  /// exists for this question, resumes it; otherwise creates a new one.
  /// Replaces the old single-shot `getExplanation` flow.
  static Future<void> openAskCortex(
    BuildContext context, {
    required String questionId,
    String? examId,
    String? userExamId,
  }) async {
    final store = Provider.of<CortexStore>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final chat = await store.findOrCreateMcqChat(
      questionId: questionId,
      examId: examId,
      userExamId: userExamId,
    );
    if (context.mounted) Navigator.pop(context); // close loader
    if (chat == null || !context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Cortex chat')),
      );
      return;
    }
    Navigator.of(context).push(CortexChatScreen.routeForChat(chat));
  }

  /// Shows the post-attempt mistake debrief modal. Use on the result/review
  /// screen when the student got the question wrong.
  static Future<void> showMistakeDebrief(
    BuildContext context, {
    required String questionId,
    required String selectedOption,
    String? correctOption,
    String? examId,
    String? userExamId,
    String examType = 'regular',
  }) {
    return MistakeDebriefSheet.show(
      context,
      questionId: questionId,
      selectedOption: selectedOption,
      correctOption: correctOption,
      examId: examId,
      userExamId: userExamId,
      examType: examType,
    );
  }

  /// Builds a Related-MCQs carousel widget — drop below any result/review row.
  static Widget relatedMcqs({
    required String questionId,
    String examType = 'regular',
    void Function(CortexRelatedMcq mcq)? onTap,
  }) {
    return RelatedMcqsCarousel(
      questionId: questionId,
      examType: examType,
      onTap: onTap,
    );
  }
}
