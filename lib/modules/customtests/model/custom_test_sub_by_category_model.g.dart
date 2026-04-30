// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_test_sub_by_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomTestSubByCategoryModel _$CustomTestSubByCategoryModelFromJson(
        Map<String, dynamic> json) =>
    CustomTestSubByCategoryModel(
      sId: json['_id'] as String?,
      subcategoryName: json['subcategory_name'] as String?,
      description: json['description'] as String?,
      questionCount: (json['questionCount'] as num?)?.toInt(),
      categoryId: json['category_id'] as String?,
    );

Map<String, dynamic> _$CustomTestSubByCategoryModelToJson(
        CustomTestSubByCategoryModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'subcategory_name': instance.subcategoryName,
      'description': instance.description,
      'questionCount': instance.questionCount,
      'category_id': instance.categoryId,
    };
