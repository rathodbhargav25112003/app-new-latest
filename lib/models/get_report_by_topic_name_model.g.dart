// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_report_by_topic_name_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportByTopicNameModel _$ReportByTopicNameModelFromJson(
        Map<String, dynamic> json) =>
    ReportByTopicNameModel(
      correctAnswers: (json['correctAnswers'] as num?)?.toInt(),
      incorrectAnswers: (json['incorrectAnswers'] as num?)?.toInt(),
      skippedAnswers: (json['skippedAnswers'] as num?)?.toInt(),
      guessedAnswers: (json['guessedAnswers'] as num?)?.toInt(),
      totalQuestions: (json['totalQuestions'] as num?)?.toInt(),
      topicName: json['topicName'] as String?,
      totalTime: json['totalTime'] as String?,
    );

Map<String, dynamic> _$ReportByTopicNameModelToJson(
        ReportByTopicNameModel instance) =>
    <String, dynamic>{
      'correctAnswers': instance.correctAnswers,
      'incorrectAnswers': instance.incorrectAnswers,
      'skippedAnswers': instance.skippedAnswers,
      'guessedAnswers': instance.guessedAnswers,
      'totalQuestions': instance.totalQuestions,
      'topicName': instance.topicName,
      'totalTime': instance.totalTime,
    };
