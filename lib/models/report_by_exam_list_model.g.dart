// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_by_exam_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportByExamListModel _$ReportByExamListModelFromJson(
        Map<String, dynamic> json) =>
    ReportByExamListModel(
      score: json['score'] as num?,
      isAttemptcount: (json['isAttemptcount'] as num?)?.toInt(),
      id: json['_id'] as String?,
      examId: json['exam_id'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      userId: json['user_id'] as String?,
      createdAt: json['created_at'] as String?,
      examName: json['exam_name'] as String?,
      declarationTime: json['declarationTime'] as String?,
      isAccess: json['isAccess'] as bool?,
      isDeclaration: json['isDeclaration'] as bool?,
    );

Map<String, dynamic> _$ReportByExamListModelToJson(
        ReportByExamListModel instance) =>
    <String, dynamic>{
      'score': instance.score,
      'isAttemptcount': instance.isAttemptcount,
      '_id': instance.id,
      'exam_id': instance.examId,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'user_id': instance.userId,
      'created_at': instance.createdAt,
      'exam_name': instance.examName,
      'declarationTime': instance.declarationTime,
      'isAccess': instance.isAccess,
      'isDeclaration': instance.isDeclaration,
    };
