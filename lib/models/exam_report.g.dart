// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExamReport _$ExamReportFromJson(Map<String, dynamic> json) => ExamReport(
      userRank: (json['userRank'] as num?)?.toInt(),
      mymark: (json['mymark'] as num?)?.toInt(),
      question: (json['Question'] as num?)?.toInt(),
      duration: json['Duration'] as String?,
      isDeclaration: json['isDeclaration'] as bool?,
      declarationTime: json['declarationTime'] as String?,
      mark: (json['mark'] as num?)?.toInt(),
      isAttemptcount: (json['isAttemptcount'] as num?)?.toInt(),
      date: json['Date'] as String?,
      percentage: json['percentage'] as String?,
      predicted_rank_2022: json['predicted_rank_2022'] as String?,
      predicted_rank_2023: json['predicted_rank_2023'] as String?,
      predicted_rank_2024: json['predicted_rank_2024'] as String?,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt(),
      incorrectAnswers: (json['incorrectAnswers'] as num?)?.toInt(),
      skippedAnswers: (json['skippedAnswers'] as num?)?.toInt(),
      correctAnswersPercentage: json['correctAnswersPercentage'] as String?,
      incorrectAnswersPercentage: json['incorrectAnswersPercentage'] as String?,
      skippedAnswersPercentage: json['skippedAnswersPercentage'] as String?,
      leftqusestion: (json['leftqusestion'] as num?)?.toInt(),
      accuracyPercentage: json['accuracyPercentage'] as String?,
      attemptquetion: (json['Attemptquetion'] as num?)?.toInt(),
      userExamId: json['userExamId'] as String?,
      timeOnQuestion: json['TimeOnQuestion'] as String?,
      time: json['Time'] as String?,
      guessedAnswersCount: (json['guessedAnswersCount'] as num?)?.toInt(),
      correctGuessCount: (json['correctGuessCount'] as num?)?.toInt(),
      correctGuessPercentage: json['correctGuessPercentage'] as String?,
      wrongGuessCount: (json['wrongGuessCount'] as num?)?.toInt(),
      wrongGuessPercentage: json['wrongGuessPercentage'] as String?,
      incorrect_correct: (json['incorrect_correct'] as num?)?.toInt(),
      correct_incorrect: (json['correct_incorrect'] as num?)?.toInt(),
      incorrect_incorres: (json['incorrect_incorres'] as num?)?.toInt(),
      topicNameReport: (json['topicNameReport'] as List<dynamic>?)
          ?.map((e) => TopicReport.fromJson(e as Map<String, dynamic>))
          .toList(),
      topThreeCorrect: (json['topThreeCorrect'] as List<dynamic>?)
          ?.map((e) => AccuracyReport.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastThreeIncorrect: (json['lastThreeIncorrect'] as List<dynamic>?)
          ?.map((e) => AccuracyReport.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalTime: json['totalTime'] as String?,
      timeAnalytics: (json['timeAnalytics'] as List<dynamic>?)
          ?.map((e) => TimeAnalytics.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ExamReportToJson(ExamReport instance) =>
    <String, dynamic>{
      'userRank': instance.userRank,
      'mymark': instance.mymark,
      'Question': instance.question,
      'Duration': instance.duration,
      'isDeclaration': instance.isDeclaration,
      'declarationTime': instance.declarationTime,
      'mark': instance.mark,
      'isAttemptcount': instance.isAttemptcount,
      'Date': instance.date,
      'percentage': instance.percentage,
      'predicted_rank_2022': instance.predicted_rank_2022,
      'predicted_rank_2023': instance.predicted_rank_2023,
      'predicted_rank_2024': instance.predicted_rank_2024,
      'correctAnswers': instance.correctAnswers,
      'incorrectAnswers': instance.incorrectAnswers,
      'skippedAnswers': instance.skippedAnswers,
      'correctAnswersPercentage': instance.correctAnswersPercentage,
      'incorrectAnswersPercentage': instance.incorrectAnswersPercentage,
      'skippedAnswersPercentage': instance.skippedAnswersPercentage,
      'leftqusestion': instance.leftqusestion,
      'accuracyPercentage': instance.accuracyPercentage,
      'Attemptquetion': instance.attemptquetion,
      'userExamId': instance.userExamId,
      'TimeOnQuestion': instance.timeOnQuestion,
      'Time': instance.time,
      'guessedAnswersCount': instance.guessedAnswersCount,
      'correctGuessCount': instance.correctGuessCount,
      'correctGuessPercentage': instance.correctGuessPercentage,
      'wrongGuessCount': instance.wrongGuessCount,
      'wrongGuessPercentage': instance.wrongGuessPercentage,
      'incorrect_correct': instance.incorrect_correct,
      'correct_incorrect': instance.correct_incorrect,
      'incorrect_incorres': instance.incorrect_incorres,
      'topicNameReport': instance.topicNameReport,
      'topThreeCorrect': instance.topThreeCorrect,
      'lastThreeIncorrect': instance.lastThreeIncorrect,
      'totalTime': instance.totalTime,
      'timeAnalytics': instance.timeAnalytics,
    };

TopicReport _$TopicReportFromJson(Map<String, dynamic> json) => TopicReport(
      topicName: json['topicName'] as String?,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt(),
      incorrectAnswers: (json['incorrectAnswers'] as num?)?.toInt(),
      skippedAnswers: (json['skippedAnswers'] as num?)?.toInt(),
      guessedAnswers: (json['guessedAnswers'] as num?)?.toInt(),
      totalQuestions: (json['totalQuestions'] as num?)?.toInt(),
      totalTime: json['totalTime'] as String?,
    );

Map<String, dynamic> _$TopicReportToJson(TopicReport instance) =>
    <String, dynamic>{
      'topicName': instance.topicName,
      'correctAnswers': instance.correctAnswers,
      'incorrectAnswers': instance.incorrectAnswers,
      'skippedAnswers': instance.skippedAnswers,
      'guessedAnswers': instance.guessedAnswers,
      'totalQuestions': instance.totalQuestions,
      'totalTime': instance.totalTime,
    };

AccuracyReport _$AccuracyReportFromJson(Map<String, dynamic> json) =>
    AccuracyReport(
      topicName: json['topicName'] as String?,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt(),
      incorrectAnswers: (json['incorrectAnswers'] as num?)?.toInt(),
      accuracyPercentage: json['accuracyPercentage'] as String?,
    );

Map<String, dynamic> _$AccuracyReportToJson(AccuracyReport instance) =>
    <String, dynamic>{
      'topicName': instance.topicName,
      'correctAnswers': instance.correctAnswers,
      'incorrectAnswers': instance.incorrectAnswers,
      'accuracyPercentage': instance.accuracyPercentage,
    };

TimeAnalytics _$TimeAnalyticsFromJson(Map<String, dynamic> json) =>
    TimeAnalytics(
      question_number: (json['question_number'] as num?)?.toInt(),
      topicName: json['topicName'] as String?,
      question_text: json['question_text'] as String?,
      timePerQuestion: json['timePerQuestion'] as String?,
      correct: json['correct'] as bool?,
      incorrect: json['incorrect'] as bool?,
      skipped: json['skipped'] as bool?,
      marks_awarded: (json['marks_awarded'] as num?)?.toInt(),
      marks_deducted: (json['marks_deducted'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TimeAnalyticsToJson(TimeAnalytics instance) =>
    <String, dynamic>{
      'question_number': instance.question_number,
      'topicName': instance.topicName,
      'question_text': instance.question_text,
      'timePerQuestion': instance.timePerQuestion,
      'correct': instance.correct,
      'incorrect': instance.incorrect,
      'skipped': instance.skipped,
      'marks_awarded': instance.marks_awarded,
      'marks_deducted': instance.marks_deducted,
    };
