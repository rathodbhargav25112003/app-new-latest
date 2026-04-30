// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_topic_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoTopicCategoryModel _$VideoTopicCategoryModelFromJson(
        Map<String, dynamic> json) =>
    VideoTopicCategoryModel(
      sId: json['_id'] as String?,
      subcategoryId: json['subcategory_id'] as String?,
      subcategoryName: json['subcategory_name'] as String?,
      categoryId: json['category_id'] as String?,
      topic_id: json['topic_id'] as String?,
      topicName: json['topic_name'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      description: json['description'] as String?,
      sid: json['sid'] as String?,
      position: (json['position'] as num?)?.toInt(),
      id: (json['id'] as num?)?.toInt(),
      iV: (json['__v'] as num?)?.toInt(),
      topicCount: (json['topicCount'] as num?)?.toInt(),
      videoCount: (json['videoCount'] as num?)?.toInt(),
      completVideoCount: (json['completVideoCount'] as num?)?.toInt(),
      progressCount: (json['progressCount'] as num?)?.toInt(),
      completedVideoCount: (json['completedVideoCount'] as num?)?.toInt(),
      notStart: (json['notStart'] as num?)?.toInt(),
      bookmarkVideoCount: (json['bookmarkVideoCount'] as num?)?.toInt(),
    )..video = (json['video'] as num?)?.toInt();

Map<String, dynamic> _$VideoTopicCategoryModelToJson(
        VideoTopicCategoryModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'subcategory_id': instance.subcategoryId,
      'subcategory_name': instance.subcategoryName,
      'category_id': instance.categoryId,
      'position': instance.position,
      'id': instance.id,
      '__v': instance.iV,
      'topicCount': instance.topicCount,
      'topic_id': instance.topic_id,
      'topic_name': instance.topicName,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'description': instance.description,
      'sid': instance.sid,
      'video': instance.video,
      'videoCount': instance.videoCount,
      'completVideoCount': instance.completVideoCount,
      'progressCount': instance.progressCount,
      'completedVideoCount': instance.completedVideoCount,
      'notStart': instance.notStart,
      'bookmarkVideoCount': instance.bookmarkVideoCount,
    };
