// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strength_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportSrengthModel _$ReportSrengthModelFromJson(Map<String, dynamic> json) =>
    ReportSrengthModel(
      topThreeCorrect: (json['topThreeCorrect'] as List<dynamic>?)
          ?.map((e) => TopThreeCorrect.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastThreeIncorrect: (json['lastThreeIncorrect'] as List<dynamic>?)
          ?.map((e) => LastThreeIncorrect.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReportSrengthModelToJson(ReportSrengthModel instance) =>
    <String, dynamic>{
      'topThreeCorrect': instance.topThreeCorrect,
      'lastThreeIncorrect': instance.lastThreeIncorrect,
    };

TopThreeCorrect _$TopThreeCorrectFromJson(Map<String, dynamic> json) =>
    TopThreeCorrect(
      topicName: json['topicName'] as String?,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt(),
      correctAnswers: (json['correctAnswers'] as num?)?.toInt(),
      incorrectAnswers: (json['incorrectAnswers'] as num?)?.toInt(),
      correctAnswersPercentage: json['correctAnswersPercentage'] as String?,
      incorrectAnswersPercentage: json['incorrectAnswersPercentage'] as String?,
    );

Map<String, dynamic> _$TopThreeCorrectToJson(TopThreeCorrect instance) =>
    <String, dynamic>{
      'topicName': instance.topicName,
      'totalQuestions': instance.totalQuestions,
      'correctAnswers': instance.correctAnswers,
      'incorrectAnswers': instance.incorrectAnswers,
      'correctAnswersPercentage': instance.correctAnswersPercentage,
      'incorrectAnswersPercentage': instance.incorrectAnswersPercentage,
    };

LastThreeIncorrect _$LastThreeIncorrectFromJson(Map<String, dynamic> json) =>
    LastThreeIncorrect(
      topicName: json['topicName'] as String?,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt(),
      correctAnswers: (json['correctAnswers'] as num?)?.toInt(),
      incorrectAnswers: (json['incorrectAnswers'] as num?)?.toInt(),
      correctAnswersPercentage: json['correctAnswersPercentage'] as String?,
      incorrectAnswersPercentage: json['incorrectAnswersPercentage'] as String?,
    );

Map<String, dynamic> _$LastThreeIncorrectToJson(LastThreeIncorrect instance) =>
    <String, dynamic>{
      'topicName': instance.topicName,
      'totalQuestions': instance.totalQuestions,
      'correctAnswers': instance.correctAnswers,
      'incorrectAnswers': instance.incorrectAnswers,
      'correctAnswersPercentage': instance.correctAnswersPercentage,
      'incorrectAnswersPercentage': instance.incorrectAnswersPercentage,
    };
