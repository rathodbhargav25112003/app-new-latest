// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_test_topic_by_subcategory_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomTestTopicBySubCategoryModel _$CustomTestTopicBySubCategoryModelFromJson(
        Map<String, dynamic> json) =>
    CustomTestTopicBySubCategoryModel(
      sId: json['_id'] as String?,
      topicName: json['topic_name'] as String?,
      description: json['description'] as String?,
      questionCount: (json['questionCount'] as num?)?.toInt(),
      subCategoryId: json['subcategory_id'] as String?,
      categoryId: json['category_id'] as String?,
    );

Map<String, dynamic> _$CustomTestTopicBySubCategoryModelToJson(
        CustomTestTopicBySubCategoryModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'topic_name': instance.topicName,
      'description': instance.description,
      'questionCount': instance.questionCount,
      'subcategory_id': instance.subCategoryId,
      'category_id': instance.categoryId,
    };
