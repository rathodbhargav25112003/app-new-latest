// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_practice_count_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportPracticeCountModel _$ReportPracticeCountModelFromJson(
        Map<String, dynamic> json) =>
    ReportPracticeCountModel(
      correctAnswers: (json['correctAnswers'] as num?)?.toInt(),
      incorrectAnswers: (json['incorrectAnswers'] as num?)?.toInt(),
      notVisited: (json['not_visited'] as num?)?.toInt(),
      totalQuestions: (json['totalQuestions'] as num?)?.toInt(),
      bookmarkCount: (json['bookmarkCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ReportPracticeCountModelToJson(
        ReportPracticeCountModel instance) =>
    <String, dynamic>{
      'correctAnswers': instance.correctAnswers,
      'incorrectAnswers': instance.incorrectAnswers,
      'not_visited': instance.notVisited,
      'bookmarkCount': instance.bookmarkCount,
      'totalQuestions': instance.totalQuestions,
    };
