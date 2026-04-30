// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_topic_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookMarkTopicModel _$BookMarkTopicModelFromJson(Map<String, dynamic> json) =>
    BookMarkTopicModel(
      topic_id: json['topic_id'] as String?,
      topic_name: json['topic_name'] as String?,
      created_at: json['created_at'] as String?,
      subcategory_id: json['subcategory_id'] as String?,
      questionCount: (json['questionCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BookMarkTopicModelToJson(BookMarkTopicModel instance) =>
    <String, dynamic>{
      'topic_id': instance.topic_id,
      'topic_name': instance.topic_name,
      'created_at': instance.created_at,
      'subcategory_id': instance.subcategory_id,
      'questionCount': instance.questionCount,
    };
