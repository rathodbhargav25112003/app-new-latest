// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_subcategory_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookMarkSubCategoryModel _$BookMarkSubCategoryModelFromJson(
        Map<String, dynamic> json) =>
    BookMarkSubCategoryModel(
      subcategory_id: json['subcategory_id'] as String?,
      subcategory_name: json['subcategory_name'] as String?,
      created_at: json['created_at'] as String?,
      category_id: json['category_id'] as String?,
      questionCount: (json['questionCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BookMarkSubCategoryModelToJson(
        BookMarkSubCategoryModel instance) =>
    <String, dynamic>{
      'subcategory_id': instance.subcategory_id,
      'subcategory_name': instance.subcategory_name,
      'created_at': instance.created_at,
      'category_id': instance.category_id,
      'questionCount': instance.questionCount,
    };
