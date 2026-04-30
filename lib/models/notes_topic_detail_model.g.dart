// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_topic_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotesTopicDetailModel _$NotesTopicDetailModelFromJson(
        Map<String, dynamic> json) =>
    NotesTopicDetailModel(
      topicId: json['sid'] as String?,
      topicName: json['topic_name'] as String?,
      description: json['description'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
    )..contents = json['contents'] == null
        ? null
        : Contents.fromJson(json['contents'] as Map<String, dynamic>);

Map<String, dynamic> _$NotesTopicDetailModelToJson(
        NotesTopicDetailModel instance) =>
    <String, dynamic>{
      'sid': instance.topicId,
      'topic_name': instance.topicName,
      'description': instance.description,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'contents': instance.contents?.toJson(),
    };

Contents _$ContentsFromJson(Map<String, dynamic> json) => Contents(
      is_access: json['is_access'] as bool?,
      id: json['_id'] as String?,
      contentId: json['content_id'] as String?,
      contentType: json['content_type'] as String?,
      contentUrl: json['content_url'] as String?,
      topicId: json['topic_id'] as String?,
      subcategoryName: json['subcategory_name'] as String?,
      categoryName: json['category_name'] as String?,
      subcategoryId: json['subcategory_id'] as String?,
      categoryId: json['category_id'] as String?,
    );

Map<String, dynamic> _$ContentsToJson(Contents instance) => <String, dynamic>{
      'is_access': instance.is_access,
      '_id': instance.id,
      'content_id': instance.contentId,
      'content_type': instance.contentType,
      'content_url': instance.contentUrl,
      'topic_id': instance.topicId,
      'subcategory_name': instance.subcategoryName,
      'category_name': instance.categoryName,
      'subcategory_id': instance.subcategoryId,
      'category_id': instance.categoryId,
    };
