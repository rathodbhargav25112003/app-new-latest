// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_test_exam_by_topic_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomTestExamByTopicModel _$CustomTestExamByTopicModelFromJson(
        Map<String, dynamic> json) =>
    CustomTestExamByTopicModel(
      sId: json['_id'] as String?,
      examName: json['exam_name'] as String?,
      timeDuration: json['time_duration'] as String?,
      questionCount: (json['questionCount'] as num?)?.toInt(),
      remainingAttempts: (json['remainingAttempts'] as num?)?.toInt(),
      isAttempt: json['isAttempt'] as bool?,
      isGivenTest: json['isGivenTest'] as bool?,
      categoryId: json['category_id'] as String?,
      subCategoryId: json['subcategory_id'] as String?,
      topicId: json['topic_id'] as String?,
    );

Map<String, dynamic> _$CustomTestExamByTopicModelToJson(
        CustomTestExamByTopicModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'exam_name': instance.examName,
      'time_duration': instance.timeDuration,
      'questionCount': instance.questionCount,
      'remainingAttempts': instance.remainingAttempts,
      'isAttempt': instance.isAttempt,
      'isGivenTest': instance.isGivenTest,
      'category_id': instance.categoryId,
      'subcategory_id': instance.subCategoryId,
      'topic_id': instance.topicId,
    };
