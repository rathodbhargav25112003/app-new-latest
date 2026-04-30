// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_subcategory_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestSubCategoryModel _$TestSubCategoryModelFromJson(
        Map<String, dynamic> json) =>
    TestSubCategoryModel(
      id: (json['id'] as num?)?.toInt(),
      subcategory_id: json['subcategory_id'] as String?,
      subcategory_name: json['subcategory_name'] as String?,
      category_id: json['category_id'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      userExamCount: (json['userExamCount'] as num?)?.toInt(),
      examCount: (json['examCount'] as num).toInt(),
      practiceAnswersCount: (json['practiceAnswersCount'] as num?)?.toInt(),
      questionCount: (json['questionCount'] as num?)?.toInt(),
      description: json['description'] as String?,
      isAttempt: json['isAttempt'] as bool?,
      isCompleted: json['isCompleted'] as bool,
      sid: json['sid'] as String?,
      examdata: (json['examdata'] as List<dynamic>?)
          ?.map((e) => Examdata.fromJson(e as Map<String, dynamic>))
          .toList(),
      allTestCount: (json['AllTestCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TestSubCategoryModelToJson(
        TestSubCategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subcategory_id': instance.subcategory_id,
      'subcategory_name': instance.subcategory_name,
      'category_id': instance.category_id,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'description': instance.description,
      'examCount': instance.examCount,
      'isCompleted': instance.isCompleted,
      'userExamCount': instance.userExamCount,
      'questionCount': instance.questionCount,
      'practiceAnswersCount': instance.practiceAnswersCount,
      'isAttempt': instance.isAttempt,
      'sid': instance.sid,
      'examdata': instance.examdata?.map((e) => e.toJson()).toList(),
      'AllTestCount': instance.allTestCount,
    };

Examdata _$ExamdataFromJson(Map<String, dynamic> json) => Examdata(
      negative_marking: json['negative_marking'] as bool?,
      deleted_at: json['deleted_at'] as String?,
      sId: json['_id'] as String?,
      examId: json['exam_id'] as String?,
      examName: json['exam_name'] as String?,
      subcategoryId: json['subcategory_id'] as String?,
      timeDuration: json['time_duration'] as String?,
      marksDeducted: (json['marks_deducted'] as num?)?.toDouble(),
      marksAwarded: (json['marks_awarded'] as num?)?.toInt(),
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      id: (json['id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ExamdataToJson(Examdata instance) => <String, dynamic>{
      'negative_marking': instance.negative_marking,
      'deleted_at': instance.deleted_at,
      '_id': instance.sId,
      'exam_id': instance.examId,
      'exam_name': instance.examName,
      'subcategory_id': instance.subcategoryId,
      'time_duration': instance.timeDuration,
      'marks_deducted': instance.marksDeducted,
      'marks_awarded': instance.marksAwarded,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'id': instance.id,
    };
