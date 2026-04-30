// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_by_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportByCategoryModel _$ReportByCategoryModelFromJson(
        Map<String, dynamic> json) =>
    ReportByCategoryModel(
      categoryName: json['category_name'] as String?,
      userRank: json['userRank'] as num?,
      userFirstRank: json['userFirstRank'] as num?,
      myMark: json['mymark'] as num?,
      candidate: (json['candidate'] as num?)?.toInt(),
      question: (json['Question'] as num?)?.toInt(),
      isAttemptcount: (json['isAttemptcount'] as num?)?.toInt(),
      duration: json['Duration'] as String?,
      date: json['Date'] as String?,
      mark: json['mark'] as num?,
      percentage: json['percentage'] as String?,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt(),
      incorrectAnswers: (json['incorrectAnswers'] as num?)?.toInt(),
      skippedAnswers: (json['skippedAnswers'] as num?)?.toInt(),
      correctAnswersPercentage: json['correctAnswersPercentage'] as String?,
      incorrectAnswersPercentage: json['incorrectAnswersPercentage'] as String?,
      skippedAnswersPercentage: json['skippedAnswersPercentage'] as String?,
      leftqusestion: (json['leftqusestion'] as num?)?.toInt(),
      accuracyPercentage: json['accuracyPercentage'] as String?,
      attemptQuetion: (json['Attemptquetion'] as num?)?.toInt(),
      userExamId: json['userExamId'] as String?,
      isDeclaration: json['isDeclaration'] as bool?,
      declarationTime: json['declarationTime'] as String?,
      timeOnQuestion: json['TimeOnQuestion'] as String?,
      guessedAnswersCount: json['guessedAnswersCount'] as num?,
      correctGuessCount: (json['correctGuessCount'] as num?)?.toInt(),
      wrongGuessCount: (json['wrongGuessCount'] as num?)?.toInt(),
      incorrect_correct: (json['incorrect_correct'] as num?)?.toInt(),
      correct_incorrect: (json['correct_incorrect'] as num?)?.toInt(),
      incorrect_incorres: (json['incorrect_incorres'] as num?)?.toInt(),
    )..Time = json['Time'] as String?;

Map<String, dynamic> _$ReportByCategoryModelToJson(
        ReportByCategoryModel instance) =>
    <String, dynamic>{
      'category_name': instance.categoryName,
      'userRank': instance.userRank,
      'userFirstRank': instance.userFirstRank,
      'mymark': instance.myMark,
      'candidate': instance.candidate,
      'isDeclaration': instance.isDeclaration,
      'declarationTime': instance.declarationTime,
      'Question': instance.question,
      'isAttemptcount': instance.isAttemptcount,
      'Duration': instance.duration,
      'Date': instance.date,
      'mark': instance.mark,
      'percentage': instance.percentage,
      'correctAnswers': instance.correctAnswers,
      'incorrectAnswers': instance.incorrectAnswers,
      'skippedAnswers': instance.skippedAnswers,
      'correctAnswersPercentage': instance.correctAnswersPercentage,
      'incorrectAnswersPercentage': instance.incorrectAnswersPercentage,
      'skippedAnswersPercentage': instance.skippedAnswersPercentage,
      'leftqusestion': instance.leftqusestion,
      'accuracyPercentage': instance.accuracyPercentage,
      'Attemptquetion': instance.attemptQuetion,
      'userExamId': instance.userExamId,
      'TimeOnQuestion': instance.timeOnQuestion,
      'guessedAnswersCount': instance.guessedAnswersCount,
      'correctGuessCount': instance.correctGuessCount,
      'wrongGuessCount': instance.wrongGuessCount,
      'incorrect_correct': instance.incorrect_correct,
      'correct_incorrect': instance.correct_incorrect,
      'incorrect_incorres': instance.incorrect_incorres,
      'Time': instance.Time,
    };
