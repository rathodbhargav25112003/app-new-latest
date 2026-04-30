// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoCategoryModel _$VideoCategoryModelFromJson(Map<String, dynamic> json) =>
    VideoCategoryModel(
      id: json['_id'] as String?,
      category_id: json['category_id'] as String?,
      category_name: json['category_name'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      video: (json['video'] as num?)?.toInt(),
      subcategory: (json['subcategory'] as num?)?.toInt(),
      sid: json['sid'] as String?,
      description: json['description'] as String?,
      subcategory_id: json['subcategory_id'] as String?,
      subcategory_name: json['subcategory_name'] as String?,
      topic_id: json['topic_id'] as String?,
      topic_name: json['topic_name'] as String?,
      progressCount: (json['progressCount'] as num?)?.toInt(),
      completedVideoCount: (json['completedVideoCount'] as num?)?.toInt(),
      notStart: (json['notStart'] as num?)?.toInt(),
      bookmarkVideoCount: (json['bookmarkVideoCount'] as num?)?.toInt(),
    )
      ..priorityLabel = json['priorityLabel'] as String?
      ..priorityColor = json['priorityColor'] as String?;

Map<String, dynamic> _$VideoCategoryModelToJson(VideoCategoryModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'category_id': instance.category_id,
      'category_name': instance.category_name,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'subcategory': instance.subcategory,
      'video': instance.video,
      'sid': instance.sid,
      'description': instance.description,
      'subcategory_id': instance.subcategory_id,
      'subcategory_name': instance.subcategory_name,
      'topic_id': instance.topic_id,
      'topic_name': instance.topic_name,
      'progressCount': instance.progressCount,
      'completedVideoCount': instance.completedVideoCount,
      'notStart': instance.notStart,
      'bookmarkVideoCount': instance.bookmarkVideoCount,
      'priorityLabel': instance.priorityLabel,
      'priorityColor': instance.priorityColor,
    };
