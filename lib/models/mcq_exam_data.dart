import 'package:json_annotation/json_annotation.dart';

part 'mcq_exam_data.g.dart';

@JsonSerializable()
class McqExamData {
  final bool isPractice;
  final bool isAttempt;
  final String lastPracticeTime;
  final String lastPracticeId;
  final String lastTestModeTime;
  final String lastTestModeId;
  final int totalQuestions;
  final int totalMarks;
  final int bookmarkCount;
  final PracticeReport practiceReport;
  final List<Attempt> attemptList;

  McqExamData({
    this.isPractice = false,
    this.isAttempt = false,
    this.lastPracticeTime = '',
    this.lastPracticeId = '',
    this.lastTestModeTime = '',
    this.lastTestModeId = '',
    this.totalQuestions = 0,
    this.totalMarks = 0,
    this.bookmarkCount = 0,
    PracticeReport? practiceReport,
    List<Attempt>? attemptList,
  })  : practiceReport = practiceReport ?? PracticeReport(),
        attemptList = attemptList ?? [];

  factory McqExamData.fromJson(Map<String, dynamic> json) => _$McqExamDataFromJson(json);
  Map<String, dynamic> toJson() => _$McqExamDataToJson(this);
}

@JsonSerializable()
class PracticeReport {
  final String userExam_id;
  final int correctAnswersCount;
  final int incorrectAnswersCount;
  final int skippedAnswersCount;
  final int attemptedQuestion;
  final int bookmarkCount;

  PracticeReport({
    this.userExam_id = '',
    this.correctAnswersCount = 0,
    this.incorrectAnswersCount = 0,
    this.skippedAnswersCount = 0,
    this.attemptedQuestion = 0,
    this.bookmarkCount = 0,
  });

  factory PracticeReport.fromJson(Map<String, dynamic> json) => _$PracticeReportFromJson(json);
  Map<String, dynamic> toJson() => _$PracticeReportToJson(this);
}

@JsonSerializable()
class Attempt {
  final String userExam_id;
  final String userExamType;
  final String mainUserExam_id;
  final int correctAnswersCount;
  final int incorrectAnswersCount;
  final int skippedAnswersCount;
  final int attemptedQuestion;
  final String accuracyPercentage;
  final int isAttemptcount;
  final int mymark;
  final int totalMarks;
  final int bookmarkCount;

  Attempt({
    this.userExam_id = '',
    this.userExamType = '',
    this.mainUserExam_id = '',
    this.correctAnswersCount = 0,
    this.incorrectAnswersCount = 0,
    this.skippedAnswersCount = 0,
    this.attemptedQuestion = 0,
    this.accuracyPercentage = '0.0',
    this.isAttemptcount = 0,
    this.mymark = 0,
    this.totalMarks = 0,
    this.bookmarkCount = 0,
  });

  factory Attempt.fromJson(Map<String, dynamic> json) => _$AttemptFromJson(json);
  Map<String, dynamic> toJson() => _$AttemptToJson(this);
}
