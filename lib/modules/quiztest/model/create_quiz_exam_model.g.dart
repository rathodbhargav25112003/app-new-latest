// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_quiz_exam_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateQuizExamModel _$CreateQuizExamModelFromJson(Map<String, dynamic> json) =>
    CreateQuizExamModel(
      score: json['score'] as num?,
      isAttemptcount: (json['isAttemptcount'] as num?)?.toInt(),
      isPractice: json['isPractice'] as bool?,
      id: json['_id'] as String?,
      examId: json['exam_id'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      userId: json['user_id'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      sid: (json['id'] as num?)?.toInt(),
      err: json['err'] == null
          ? null
          : errMsg.fromJson(json['err'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CreateQuizExamModelToJson(
        CreateQuizExamModel instance) =>
    <String, dynamic>{
      'score': instance.score,
      'isAttemptcount': instance.isAttemptcount,
      'isPractice': instance.isPractice,
      '_id': instance.id,
      'exam_id': instance.examId,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'user_id': instance.userId,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'id': instance.sid,
      'err': instance.err?.toJson(),
    };

errMsg _$errMsgFromJson(Map<String, dynamic> json) => errMsg(
      message: json['message'] as String?,
    );

Map<String, dynamic> _$errMsgToJson(errMsg instance) => <String, dynamic>{
      'message': instance.message,
    };
