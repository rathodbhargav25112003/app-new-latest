import 'package:json_annotation/json_annotation.dart';

part 'exam_report.g.dart';

@JsonSerializable()
class ExamReport {
  final int? userRank;
  final int? mymark;
  @JsonKey(name: "Question")
  final int? question;
  @JsonKey(name: "Duration")
  final String? duration;
  final bool? isDeclaration;
  final String? declarationTime;
  final int? mark;
  final int? isAttemptcount;
  @JsonKey(name: "Date")
  final String? date;
  final String? percentage;
  final String? predicted_rank_2022;
  final String? predicted_rank_2023;
  final String? predicted_rank_2024;
  final int? correctAnswers;
  final int? incorrectAnswers;
  final int? skippedAnswers;
  final String? correctAnswersPercentage;
  final String? incorrectAnswersPercentage;
  final String? skippedAnswersPercentage;
  final int? leftqusestion;
  final String? accuracyPercentage;
  @JsonKey(name: "Attemptquetion")
  final int? attemptquetion;
  final String? userExamId;
  @JsonKey(name: "TimeOnQuestion")
  final String? timeOnQuestion;
  @JsonKey(name: "Time")
  final String? time;
  final int? guessedAnswersCount;
  final int? correctGuessCount;
  final String? correctGuessPercentage;
  final int? wrongGuessCount;
  final String? wrongGuessPercentage;
  final int? incorrect_correct;
  final int? correct_incorrect;
  final int? incorrect_incorres;
  final List<TopicReport>? topicNameReport;
  final List<AccuracyReport>? topThreeCorrect;
  final List<AccuracyReport>? lastThreeIncorrect;
  final String? totalTime;
  final List<TimeAnalytics>? timeAnalytics;

  ExamReport({
    required this.userRank,
    required this.mymark,
    required this.question,
    required this.duration,
    required this.isDeclaration,
    required this.declarationTime,
    required this.mark,
    required this.isAttemptcount,
    required this.date,
    required this.percentage,
    required this.predicted_rank_2022,
    required this.predicted_rank_2023,
    required this.predicted_rank_2024,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.skippedAnswers,
    required this.correctAnswersPercentage,
    required this.incorrectAnswersPercentage,
    required this.skippedAnswersPercentage,
    required this.leftqusestion,
    required this.accuracyPercentage,
    required this.attemptquetion,
    required this.userExamId,
    required this.timeOnQuestion,
    required this.time,
    required this.guessedAnswersCount,
    required this.correctGuessCount,
    required this.correctGuessPercentage,
    required this.wrongGuessCount,
    required this.wrongGuessPercentage,
    required this.incorrect_correct,
    required this.correct_incorrect,
    required this.incorrect_incorres,
    required this.topicNameReport,
    required this.topThreeCorrect,
    required this.lastThreeIncorrect,
    required this.totalTime,
    required this.timeAnalytics,
  });

  factory ExamReport.fromJson(Map<String, dynamic> json) =>
      _$ExamReportFromJson(json);

  Map<String, dynamic> toJson() => _$ExamReportToJson(this);
}

@JsonSerializable()
class TopicReport {
  final String? topicName;
  final int? correctAnswers;
  final int? incorrectAnswers;
  final int? skippedAnswers;
  final int? guessedAnswers;
  final int? totalQuestions;
  final String? totalTime;

  TopicReport({
    required this.topicName,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.skippedAnswers,
    required this.guessedAnswers,
    required this.totalQuestions,
    required this.totalTime,
  });

  factory TopicReport.fromJson(Map<String, dynamic> json) =>
      _$TopicReportFromJson(json);

  Map<String, dynamic> toJson() => _$TopicReportToJson(this);
}

@JsonSerializable()
class AccuracyReport {
  final String? topicName;
  final int? correctAnswers;
  final int? incorrectAnswers;
  final String? accuracyPercentage;

  AccuracyReport({
    required this.topicName,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.accuracyPercentage,
  });

  factory AccuracyReport.fromJson(Map<String, dynamic> json) =>
      _$AccuracyReportFromJson(json);

  Map<String, dynamic> toJson() => _$AccuracyReportToJson(this);
}

@JsonSerializable()
class TimeAnalytics {
  final int? question_number;
  final String? topicName;
  final String? question_text;
  final String? timePerQuestion;
  final bool? correct;
  final bool? incorrect;
  final bool? skipped;
  final int? marks_awarded;
  final int? marks_deducted;

  TimeAnalytics({
    required this.question_number,
    required this.topicName,
    required this.question_text,
    this.timePerQuestion,
    this.correct,
    this.incorrect,
    required this.skipped,
    required this.marks_awarded,
    required this.marks_deducted,
  });

  factory TimeAnalytics.fromJson(Map<String, dynamic> json) =>
      _$TimeAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$TimeAnalyticsToJson(this);
}
