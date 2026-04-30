// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'searched_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchedDataModel _$SearchedDataModelFromJson(Map<String, dynamic> json) =>
    SearchedDataModel(
      id: json['_id'] as String?,
      categoryName: json['category_name'] as String?,
      subcategoryName: json['subcategory_name'] as String?,
      subName: json['sub_name'] as String?,
      topicName: json['topic_name'] as String?,
      description: json['description'] as String?,
      title: json['title'] as String?,
      contentUrl: json['content_url'] as String?,
      topicId: json['topic_id'] as String?,
      subcategoryId: json['subcategory_id'] as String?,
      categoryId: json['category_id'] as String?,
      err: json['err'] == null
          ? null
          : ErrorModel.fromJson(json['err'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SearchedDataModelToJson(SearchedDataModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'category_name': instance.categoryName,
      'subcategory_name': instance.subcategoryName,
      'sub_name': instance.subName,
      'content_url': instance.contentUrl,
      'topic_name': instance.topicName,
      'subcategory_id': instance.subcategoryId,
      'topic_id': instance.topicId,
      'category_id': instance.categoryId,
      'title': instance.title,
      'description': instance.description,
      'err': instance.err?.toJson(),
    };

ErrorModel _$ErrorModelFromJson(Map<String, dynamic> json) => ErrorModel(
      code: json['code'],
      message: json['message'] as String?,
      params: json['params'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ErrorModelToJson(ErrorModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'params': instance.params,
    };
