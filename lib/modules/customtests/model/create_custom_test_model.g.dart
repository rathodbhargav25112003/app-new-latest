// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_custom_test_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomTestModel _$CustomTestModelFromJson(Map<String, dynamic> json) =>
    CustomTestModel(
      sId: json['_id'] as String?,
      timeDuration: json['time_duration'] as String?,
      testName: json['testName'] as String?,
      numberOfQuestions: (json['NumberOfQuestions'] as num?)?.toInt(),
      description: json['Description'] as String?,
      questionId: (json['question_id'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      exam: (json['exam'] as List<dynamic>?)
          ?.map((e) => ExamModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      topic: (json['topic'] as List<dynamic>?)
          ?.map((e) => TopicModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      subcategory: (json['subcategory'] as List<dynamic>?)
          ?.map((e) => SubcategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      category: (json['category'] as List<dynamic>?)
          ?.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      marksDeducted: (json['marks_deducted'] as num?)?.toInt(),
      marksAwarded: (json['marks_awarded'] as num?)?.toInt(),
      attempt: (json['attempt'] as num?)?.toInt(),
      userId: json['user_id'] as String?,
    );

Map<String, dynamic> _$CustomTestModelToJson(CustomTestModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'attempt': instance.attempt,
      'marks_deducted': instance.marksDeducted,
      'marks_awarded': instance.marksAwarded,
      'user_id': instance.userId,
      'testName': instance.testName,
      'Description': instance.description,
      'NumberOfQuestions': instance.numberOfQuestions,
      'time_duration': instance.timeDuration,
      'category': instance.category?.map((e) => e.toJson()).toList(),
      'subcategory': instance.subcategory?.map((e) => e.toJson()).toList(),
      'topic': instance.topic?.map((e) => e.toJson()).toList(),
      'exam': instance.exam?.map((e) => e.toJson()).toList(),
      'question_id': instance.questionId,
    };

CategoryModel _$CategoryModelFromJson(Map<String, dynamic> json) =>
    CategoryModel(
      sId: json['_id'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
    );

Map<String, dynamic> _$CategoryModelToJson(CategoryModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'category_id': instance.categoryId,
      'category_name': instance.categoryName,
    };

SubcategoryModel _$SubcategoryModelFromJson(Map<String, dynamic> json) =>
    SubcategoryModel(
      sId: json['_id'] as String?,
      subcategoryName: json['subcategory_name'] as String?,
      subcategoryId: json['subcategory_id'] as String?,
    );

Map<String, dynamic> _$SubcategoryModelToJson(SubcategoryModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'subcategory_id': instance.subcategoryId,
      'subcategory_name': instance.subcategoryName,
    };

TopicModel _$TopicModelFromJson(Map<String, dynamic> json) => TopicModel(
      sId: json['_id'] as String?,
      topicId: json['topic_id'] as String?,
      topicName: json['topic_name'] as String?,
    );

Map<String, dynamic> _$TopicModelToJson(TopicModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'topic_id': instance.topicId,
      'topic_name': instance.topicName,
    };

ExamModel _$ExamModelFromJson(Map<String, dynamic> json) => ExamModel(
      sId: json['_id'] as String?,
      examName: json['exam_name'] as String?,
      examId: json['exam_id'] as String?,
    );

Map<String, dynamic> _$ExamModelToJson(ExamModel instance) => <String, dynamic>{
      '_id': instance.sId,
      'exam_id': instance.examId,
      'exam_name': instance.examName,
    };
