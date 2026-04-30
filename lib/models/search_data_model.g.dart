// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchDataModel _$SearchDataModelFromJson(Map<String, dynamic> json) =>
    SearchDataModel(
      id: json['_id'] as String?,
      category_name: json['category_name'] as String?,
      category_id: json['category_id'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      subcategory_id: json['subcategory_id'] as String?,
      subcategory_name: json['subcategory_name'] as String?,
      topic_id: json['topic_id'] as String?,
      topic_name: json['topic_name'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$SearchDataModelToJson(SearchDataModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'category_name': instance.category_name,
      'category_id': instance.category_id,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'subcategory_id': instance.subcategory_id,
      'subcategory_name': instance.subcategory_name,
      'topic_id': instance.topic_id,
      'topic_name': instance.topic_name,
      'description': instance.description,
    };
