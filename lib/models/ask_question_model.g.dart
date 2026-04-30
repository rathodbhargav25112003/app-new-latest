// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ask_question_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AskQuestionModel _$AskQuestionModelFromJson(Map<String, dynamic> json) =>
    AskQuestionModel(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'] as String?,
      question: json['question'] as String?,
      answer: json['answer'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      sId: json['_id'] as String?,
      iV: (json['__v'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AskQuestionModelToJson(AskQuestionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      '_id': instance.sId,
      '__v': instance.iV,
      'user_id': instance.userId,
      'question': instance.question,
      'answer': instance.answer,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
    };
