// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mock_analysis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

McqAnalysis _$McqAnalysisFromJson(Map<String, dynamic> json) => McqAnalysis(
      mymark: (json['mymark'] as num).toInt(),
      totalQuestions: (json['totalQuestions'] as num).toInt(),
      mark: (json['mark'] as num).toInt(),
      totalTime: json['totalTime'] as String,
      percentage: json['percentage'] as String,
      correctAnswers: (json['correctAnswers'] as num).toInt(),
      incorrectAnswers: (json['incorrectAnswers'] as num).toInt(),
      skippedAnswers: (json['skippedAnswers'] as num).toInt(),
      correctAnswersPercentage: json['correctAnswersPercentage'] as String,
      incorrectAnswersPercentage: json['incorrectAnswersPercentage'] as String,
      skippedAnswersPercentage: json['skippedAnswersPercentage'] as String,
      accuracyPercentage: json['accuracyPercentage'] as String,
      guessedAnswersCount: (json['guessedAnswersCount'] as num).toInt(),
      correctGuessCount: (json['correctGuessCount'] as num).toInt(),
      correctGuessPercentage: json['correctGuessPercentage'] as String,
      wrongGuessCount: (json['wrongGuessCount'] as num).toInt(),
      wrongGuessPercentage: json['wrongGuessPercentage'] as String,
      incorrect_correct: (json['incorrect_correct'] as num).toInt(),
      correct_incorrect: (json['correct_incorrect'] as num).toInt(),
      incorrect_incorres: (json['incorrect_incorres'] as num).toInt(),
    );

Map<String, dynamic> _$McqAnalysisToJson(McqAnalysis instance) =>
    <String, dynamic>{
      'mymark': instance.mymark,
      'totalQuestions': instance.totalQuestions,
      'mark': instance.mark,
      'totalTime': instance.totalTime,
      'percentage': instance.percentage,
      'correctAnswers': instance.correctAnswers,
      'incorrectAnswers': instance.incorrectAnswers,
      'skippedAnswers': instance.skippedAnswers,
      'correctAnswersPercentage': instance.correctAnswersPercentage,
      'incorrectAnswersPercentage': instance.incorrectAnswersPercentage,
      'skippedAnswersPercentage': instance.skippedAnswersPercentage,
      'accuracyPercentage': instance.accuracyPercentage,
      'guessedAnswersCount': instance.guessedAnswersCount,
      'correctGuessCount': instance.correctGuessCount,
      'correctGuessPercentage': instance.correctGuessPercentage,
      'wrongGuessCount': instance.wrongGuessCount,
      'wrongGuessPercentage': instance.wrongGuessPercentage,
      'incorrect_correct': instance.incorrect_correct,
      'correct_incorrect': instance.correct_incorrect,
      'incorrect_incorres': instance.incorrect_incorres,
    };
