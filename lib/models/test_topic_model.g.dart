// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_topic_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestTopicModel _$TestTopicModelFromJson(Map<String, dynamic> json) =>
    TestTopicModel(
      id: (json['id'] as num?)?.toInt(),
      topicId: json['topic_id'] as String?,
      topicName: json['topic_name'] as String?,
      subcategoryId: json['subcategory_id'] as String?,
      description: json['description'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      userExamCount: (json['userExamCount'] as num?)?.toInt(),
      examCount: (json['examCount'] as num).toInt(),
      isCompleted: json['isCompleted'] as bool,
      practiceAnswersCount: (json['practiceAnswersCount'] as num?)?.toInt(),
      questionCount: (json['questionCount'] as num?)?.toInt(),
      sid: json['sid'] as String?,
      isAttempt: json['isAttempt'] as bool?,
      allTestCount: (json['AllTestCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TestTopicModelToJson(TestTopicModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'topic_id': instance.topicId,
      'topic_name': instance.topicName,
      'subcategory_id': instance.subcategoryId,
      'description': instance.description,
      'examCount': instance.examCount,
      'isCompleted': instance.isCompleted,
      'userExamCount': instance.userExamCount,
      'questionCount': instance.questionCount,
      'practiceAnswersCount': instance.practiceAnswersCount,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'sid': instance.sid,
      'isAttempt': instance.isAttempt,
      'AllTestCount': instance.allTestCount,
    };
