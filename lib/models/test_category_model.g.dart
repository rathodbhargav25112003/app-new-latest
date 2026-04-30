// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestCategoryModel _$TestCategoryModelFromJson(Map<String, dynamic> json) =>
    TestCategoryModel(
      id: (json['id'] as num?)?.toInt(),
      category_id: json['category_id'] as String?,
      category_name: json['category_name'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      Test: (json['Test'] as num?)?.toInt(),
      subcategory: (json['subcategory'] as num?)?.toInt(),
      examCount: (json['examCount'] as num?)?.toInt(),
      sid: json['sid'] as String?,
      isNeetSS: json['Neet_SS'] as bool? ?? true,
      description: json['description'] as String?,
      isAttempt: json['isAttempt'] as bool?,
      isCompleted: json['isCompleted'] as bool?,
      isSeries: json['isSeries'] as bool? ?? false,
      allTestCount: (json['AllTestCount'] as num?)?.toInt(),
      sId: json['_id'] as String?,
    )
      ..userExamCount = (json['userExamCount'] as num?)?.toInt()
      ..questionCount = (json['questionCount'] as num?)?.toInt()
      ..practiceAnswersCount = (json['practiceAnswersCount'] as num?)?.toInt();

Map<String, dynamic> _$TestCategoryModelToJson(TestCategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category_id': instance.category_id,
      'category_name': instance.category_name,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'subcategory': instance.subcategory,
      'Test': instance.Test,
      'examCount': instance.examCount,
      'userExamCount': instance.userExamCount,
      'questionCount': instance.questionCount,
      'practiceAnswersCount': instance.practiceAnswersCount,
      'sid': instance.sid,
      'description': instance.description,
      'Neet_SS': instance.isNeetSS,
      '_id': instance.sId,
      'isAttempt': instance.isAttempt,
      'isSeries': instance.isSeries,
      'isCompleted': instance.isCompleted,
      'AllTestCount': instance.allTestCount,
    };
