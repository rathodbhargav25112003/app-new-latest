// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_report_by_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizReportByCategoryModel _$QuizReportByCategoryModelFromJson(
        Map<String, dynamic> json) =>
    QuizReportByCategoryModel(
      id: json['_id'] as String?,
      questionCount: (json['questionCount'] as num?)?.toInt(),
      incorrectAnswers: (json['incorrectAnswers'] as num?)?.toInt(),
      correctAnswers: (json['correctAnswers'] as num?)?.toInt(),
      myScore: json['myScore'] as num?,
      percentage: json['percentage'] as num?,
      totalMarks: json['totalMarks'] as num?,
    );

Map<String, dynamic> _$QuizReportByCategoryModelToJson(
        QuizReportByCategoryModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'myScore': instance.myScore,
      'totalMarks': instance.totalMarks,
      'correctAnswers': instance.correctAnswers,
      'incorrectAnswers': instance.incorrectAnswers,
      'questionCount': instance.questionCount,
      'percentage': instance.percentage,
    };
