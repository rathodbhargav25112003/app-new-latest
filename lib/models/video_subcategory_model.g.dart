// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_subcategory_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoSubCategoryModel _$VideoSubCategoryModelFromJson(
        Map<String, dynamic> json) =>
    VideoSubCategoryModel(
      sId: json['_id'] as String?,
      subcategory_id: json['subcategory_id'] as String?,
      subcategoryName: json['subcategory_name'] as String?,
      categoryId: json['category_id'] as String?,
      topic_id: json['topic_id'] as String?,
      topic_name: json['topic_name'] as String?,
      description: json['description'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      video: (json['video'] as num?)?.toInt(),
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
    )
      ..priorityLabel = json['priorityLabel'] as String?
      ..priorityColor = json['priorityColor'] as String?;

Map<String, dynamic> _$VideoSubCategoryModelToJson(
        VideoSubCategoryModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'subcategory_id': instance.subcategory_id,
      'subcategory_name': instance.subcategoryName,
      'topic_id': instance.topic_id,
      'topic_name': instance.topic_name,
      'description': instance.description,
      'category_id': instance.categoryId,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'video': instance.video,
      'id': instance.id,
      'position': instance.position,
      '__v': instance.iV,
      'topicCount': instance.topicCount,
      'videoCount': instance.videoCount,
      'completVideoCount': instance.completVideoCount,
      'sid': instance.sid,
      'progressCount': instance.progressCount,
      'completedVideoCount': instance.completedVideoCount,
      'notStart': instance.notStart,
      'bookmarkVideoCount': instance.bookmarkVideoCount,
      'priorityLabel': instance.priorityLabel,
      'priorityColor': instance.priorityColor,
    };
