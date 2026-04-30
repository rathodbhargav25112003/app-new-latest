import '../models/get_all_my_custom_test_model.dart' as ctest;
import '../models/master_solution_reports_model.dart' as msr;
import '../models/solution_reports_model.dart' as sol;
import '../models/test_exampaper_list_model.dart' as test;
import '../modules/customtests/model/custom_test_solution_reports_model.dart' as csol;
import '../modules/quiztest/model/quiz_solution_reports_model.dart' as qsol;
import 'daily_review_service.dart';

/// DailyReviewRecorder — adapters that convert in-app models into
/// [ReviewQuestion] payloads and delegate to [DailyReviewService].
///
/// Keep practice screens dumb: they just call `DailyReviewRecorder.x(...)`
/// after their store action and never know how SharedPreferences works.
class DailyReviewRecorder {
  DailyReviewRecorder._();

  /// User toggled the bookmark icon on a [test.TestData] question.
  /// [bookmarkedNow] = the new state after the toggle.
  static Future<void> bookmarkToggle(
    test.TestData q,
    String? examId,
    bool bookmarkedNow,
  ) async {
    if (q.sId == null || q.sId!.isEmpty) return;
    if (bookmarkedNow) {
      await DailyReviewService.instance.recordBookmark(_fromTestData(q, examId));
    } else {
      await DailyReviewService.instance.unrecordBookmark(q.sId!);
    }
  }

  /// User submitted a wrong answer on a practice question.
  /// [pickedValue] is the option the user picked.
  static Future<void> recordWrong(
    test.TestData q,
    String? examId,
    String? pickedValue,
  ) async {
    if (q.sId == null || q.sId!.isEmpty) return;
    if (q.correctOption == null || q.correctOption!.isEmpty) return;
    final review = _fromTestData(q, examId).copyWith(
      userPickedValue: pickedValue,
    );
    await DailyReviewService.instance.recordIncorrect(review);
  }

  /// User got it right on retake — pull from incorrect pool.
  static Future<void> recordCorrect(test.TestData q) async {
    if (q.sId == null || q.sId!.isEmpty) return;
    await DailyReviewService.instance.unrecordIncorrect(q.sId!);
  }

  /// User flagged "review later" during a test.
  static Future<void> recordReviewMark(
    test.TestData q,
    String? examId,
  ) async {
    if (q.sId == null || q.sId!.isEmpty) return;
    await DailyReviewService.instance.recordReview(_fromTestData(q, examId));
  }

  /// User unmarked review.
  static Future<void> recordReviewUnmark(test.TestData q) async {
    if (q.sId == null || q.sId!.isEmpty) return;
    await DailyReviewService.instance.unrecordReview(q.sId!);
  }

  // ── Solution-screen adapters (model: SolutionReportsModel) ──────

  /// User toggled bookmark on a solution-review screen. The bookmark
  /// state on the SolutionReportsModel itself is the source of truth.
  static Future<void> bookmarkToggleSolution(
    sol.SolutionReportsModel q,
    bool bookmarkedNow,
  ) async {
    if (q.questionId == null || q.questionId!.isEmpty) return;
    if (bookmarkedNow) {
      await DailyReviewService.instance
          .recordBookmark(_fromSolutionReport(q));
    } else {
      await DailyReviewService.instance.unrecordBookmark(q.questionId!);
    }
  }

  /// Fold an entire solution-report list into the daily-review pools
  /// after the user finishes a test. Surfaces every wrong answer +
  /// every bookmarked question. No-op for skipped questions.
  ///
  /// Call from: solution screen `initState` or post-submit.
  static Future<void> ingestSolutionReport(
    List<sol.SolutionReportsModel?> report,
  ) async {
    for (final q in report) {
      if (q == null || (q.questionId ?? '').isEmpty) continue;
      if (q.bookmarks == true) {
        await DailyReviewService.instance
            .recordBookmark(_fromSolutionReport(q));
      }
      if (q.isCorrect == false &&
          (q.selectedOption ?? '').isNotEmpty &&
          (q.correctOption ?? '').isNotEmpty) {
        await DailyReviewService.instance.recordIncorrect(
          _fromSolutionReport(q).copyWith(userPickedValue: q.selectedOption),
        );
      }
      // marked_for_review is a String "true"/"false" in this model.
      if ((q.markedforreview ?? '').toLowerCase() == 'true' ||
          (q.attemptedmarkedforreview ?? '').toLowerCase() == 'true') {
        await DailyReviewService.instance
            .recordReview(_fromSolutionReport(q));
      }
    }
  }

  // ── Master-solution adapters (model: master_solution_reports_model.Questions) ──

  static Future<void> bookmarkToggleMaster(
    msr.Questions q,
    bool bookmarkedNow,
  ) async {
    if (q.questionId == null || q.questionId!.isEmpty) return;
    if (bookmarkedNow) {
      await DailyReviewService.instance.recordBookmark(_fromMasterQuestion(q));
    } else {
      await DailyReviewService.instance.unrecordBookmark(q.questionId!);
    }
  }

  static Future<void> ingestMasterReport(List<msr.Questions>? report) async {
    if (report == null) return;
    for (final q in report) {
      if ((q.questionId ?? '').isEmpty) continue;
      if (q.bookmarks == true) {
        await DailyReviewService.instance.recordBookmark(_fromMasterQuestion(q));
      }
      if (q.isCorrect == false &&
          (q.selectedOption ?? '').isNotEmpty &&
          (q.correctOption ?? '').isNotEmpty) {
        await DailyReviewService.instance.recordIncorrect(
          _fromMasterQuestion(q).copyWith(userPickedValue: q.selectedOption),
        );
      }
      if ((q.markedforreview ?? '').toLowerCase() == 'true' ||
          (q.attemptedmarkedforreview ?? '').toLowerCase() == 'true') {
        await DailyReviewService.instance.recordReview(_fromMasterQuestion(q));
      }
    }
  }

  static ReviewQuestion _fromMasterQuestion(msr.Questions q) {
    final opts = (q.options ?? const <msr.Options>[])
        .map((o) => ReviewOption(
              value: o.value ?? '',
              label: o.answerTitle ?? o.value ?? '',
            ))
        .toList(growable: false);
    return ReviewQuestion(
      id: q.questionId ?? '',
      text: q.questionText ?? '',
      options: opts,
      correctValue: q.correctOption ?? '',
      explanation: q.explanation,
      topicName: q.topicName,
      examId: q.examId,
      questionImages: q.questionImg ?? const [],
      explanationImages: q.explanationImg ?? const [],
      annotationData: q.annotationData,
    );
  }

  // ─────────────────────────────────────────────────────────────────

  static ReviewQuestion _fromSolutionReport(sol.SolutionReportsModel q) {
    final opts = (q.options ?? const <sol.Options>[])
        .map((o) => ReviewOption(
              value: o.value ?? '',
              label: o.answerTitle ?? o.value ?? '',
            ))
        .toList(growable: false);
    return ReviewQuestion(
      id: q.questionId ?? '',
      text: q.questionText ?? '',
      options: opts,
      correctValue: q.correctOption ?? '',
      explanation: q.explanation,
      topicName: q.topicName,
      examId: q.examId,
      questionImages: q.questionImg ?? const [],
      explanationImages: q.explanationImg ?? const [],
      annotationData: q.annotationData,
    );
  }

  // ── Custom-test solution adapters ──────────────────────────────────────

  static Future<void> bookmarkToggleCustomSolution(
    csol.CustomTestSolutionReportsModel q,
    bool bookmarkedNow,
  ) async {
    if (q.questionId == null || q.questionId!.isEmpty) return;
    if (bookmarkedNow) {
      await DailyReviewService.instance
          .recordBookmark(_fromCustomSolutionReport(q));
    } else {
      await DailyReviewService.instance.unrecordBookmark(q.questionId!);
    }
  }

  static Future<void> ingestCustomSolutionReport(
    List<csol.CustomTestSolutionReportsModel> report,
  ) async {
    for (final q in report) {
      if ((q.questionId ?? '').isEmpty) continue;
      if (q.bookmarks == true) {
        await DailyReviewService.instance
            .recordBookmark(_fromCustomSolutionReport(q));
      }
      if (q.isCorrect == false &&
          (q.selectedOption ?? '').isNotEmpty &&
          (q.correctOption ?? '').isNotEmpty) {
        await DailyReviewService.instance.recordIncorrect(
          _fromCustomSolutionReport(q).copyWith(userPickedValue: q.selectedOption),
        );
      }
    }
  }

  static ReviewQuestion _fromCustomSolutionReport(csol.CustomTestSolutionReportsModel q) {
    final opts = (q.options ?? const <csol.Options>[])
        .map((o) => ReviewOption(
              value: o.value ?? '',
              label: o.answerTitle ?? o.value ?? '',
            ))
        .toList(growable: false);
    return ReviewQuestion(
      id: q.questionId ?? '',
      text: q.questionText ?? '',
      options: opts,
      correctValue: q.correctOption ?? '',
      explanation: q.explanation,
      topicName: q.topicName,
      examId: q.examId,
      questionImages: q.questionImg ?? const [],
      explanationImages: q.explanationImg ?? const [],
    );
  }

  // ── Quiz solution adapters ────────────────────────────────────────────

  static Future<void> bookmarkToggleQuizSolution(
    qsol.QuizSolutionReportsModel q,
    bool bookmarkedNow,
  ) async {
    if (q.questionId == null || q.questionId!.isEmpty) return;
    if (bookmarkedNow) {
      await DailyReviewService.instance
          .recordBookmark(_fromQuizSolutionReport(q));
    } else {
      await DailyReviewService.instance.unrecordBookmark(q.questionId!);
    }
  }

  static Future<void> ingestQuizSolutionReport(
    List<qsol.QuizSolutionReportsModel> report,
  ) async {
    for (final q in report) {
      if ((q.questionId ?? '').isEmpty) continue;
      if (q.bookmarks == true) {
        await DailyReviewService.instance
            .recordBookmark(_fromQuizSolutionReport(q));
      }
      if (q.isCorrect == false &&
          (q.selectedOption ?? '').isNotEmpty &&
          (q.correctOption ?? '').isNotEmpty) {
        await DailyReviewService.instance.recordIncorrect(
          _fromQuizSolutionReport(q).copyWith(userPickedValue: q.selectedOption),
        );
      }
    }
  }

  static ReviewQuestion _fromQuizSolutionReport(qsol.QuizSolutionReportsModel q) {
    final opts = (q.options ?? const <qsol.Options>[])
        .map((o) => ReviewOption(
              value: o.value ?? '',
              label: o.answerTitle ?? o.value ?? '',
            ))
        .toList(growable: false);
    return ReviewQuestion(
      id: q.questionId ?? '',
      text: q.questionText ?? '',
      options: opts,
      correctValue: q.correctOption ?? '',
      explanation: q.explanation,
      topicName: q.topicName,
      examId: q.examId,
      questionImages: q.questionImg ?? const [],
      explanationImages: q.explanationImg ?? const [],
    );
  }

  // ─────────────────────────────────────────────────────────────────────

  static ReviewQuestion _fromTestData(test.TestData q, String? examId) {
    final opts = (q.optionsData ?? const <test.Options>[])
        .map((o) => ReviewOption(
              value: o.value ?? '',
              label: o.answerTitle ?? o.value ?? '',
            ))
        .toList(growable: false);
    return ReviewQuestion(
      id: q.sId ?? '',
      text: q.questionText ?? '',
      options: opts,
      correctValue: q.correctOption ?? '',
      explanation: q.explanation,
      examId: examId,
      questionImages: q.questionImg ?? const [],
      explanationImages: q.explanationImg ?? const [],
      annotationData: q.annotationData,
    );
  }

  // ── Custom-test TestData adapters (get_all_my_custom_test_model) ──────

  static Future<void> bookmarkToggleCustomTest(
    ctest.TestData q,
    String? examId,
    bool bookmarkedNow,
  ) async {
    if (q.sId == null || q.sId!.isEmpty) return;
    if (bookmarkedNow) {
      await DailyReviewService.instance
          .recordBookmark(_fromCustomTestData(q, examId));
    } else {
      await DailyReviewService.instance.unrecordBookmark(q.sId!);
    }
  }

  static Future<void> recordWrongCustomTest(
      ctest.TestData q, String? examId, String pickedValue) async {
    if (q.sId == null || q.sId!.isEmpty) return;
    await DailyReviewService.instance.recordIncorrect(
      _fromCustomTestData(q, examId).copyWith(userPickedValue: pickedValue),
    );
  }

  static Future<void> recordCorrectCustomTest(ctest.TestData q) async {
    if (q.sId == null || q.sId!.isEmpty) return;
    await DailyReviewService.instance.unrecordIncorrect(q.sId!);
  }

  static Future<void> recordReviewMarkCustomTest(
      ctest.TestData q, String? examId) async {
    if (q.sId == null || q.sId!.isEmpty) return;
    await DailyReviewService.instance
        .recordReview(_fromCustomTestData(q, examId));
  }

  static Future<void> recordReviewUnmarkCustomTest(ctest.TestData q) async {
    if (q.sId == null || q.sId!.isEmpty) return;
    await DailyReviewService.instance.unrecordReview(q.sId!);
  }

  static ReviewQuestion _fromCustomTestData(ctest.TestData q, String? examId) {
    final opts = (q.optionsData ?? const <ctest.Options>[])
        .map((o) => ReviewOption(
              value: o.value ?? '',
              label: o.answerTitle ?? o.value ?? '',
            ))
        .toList(growable: false);
    return ReviewQuestion(
      id: q.sId ?? '',
      text: q.questionText ?? '',
      options: opts,
      correctValue: q.correctOption ?? '',
      explanation: q.explanation,
      examId: examId,
      questionImages: q.questionImg ?? const [],
      explanationImages: q.explanationImg ?? const [],
    );
  }
}
