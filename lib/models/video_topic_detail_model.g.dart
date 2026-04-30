// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_topic_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoTopicDetailModel _$VideoTopicDetailModelFromJson(
        Map<String, dynamic> json) =>
    VideoTopicDetailModel(
      topicName: json['topic_name'] as String?,
      id: (json['id'] as num?)?.toInt(),
      contentId: json['content_id'] as String?,
      contentType: json['content_type'] as String?,
      videoUrl: json['video_url'] as String?,
      topicId: json['topic_id'] as String?,
      description: json['description'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      sid: json['sid'] as String?,
      contentUrl: json['content_url'] as String?,
      isAccess: json['is_access'] as bool?,
      isCompleted: json['isCompleted'] as bool?,
      pdfcontents: json['Pdfcontents'] as String?,
      sId: json['_id'] as String?,
      title: json['title'] as String?,
      subscriptionId: json['subcategory_id'] as String?,
      isfeatured: json['isfeatured'] as bool?,
      iV: (json['__v'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
      thumbnail: json['thumbnail'] as String?,
      isBookmark: json['isBookmark'] as bool?,
    );

Map<String, dynamic> _$VideoTopicDetailModelToJson(
        VideoTopicDetailModel instance) =>
    <String, dynamic>{
      'topic_name': instance.topicName,
      '_id': instance.sId,
      'id': instance.id,
      '__v': instance.iV,
      'subcategory_id': instance.subscriptionId,
      'title': instance.title,
      'topic_id': instance.topicId,
      'description': instance.description,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'sid': instance.sid,
      'content_id': instance.contentId,
      'content_type': instance.contentType,
      'video_url': instance.videoUrl,
      'content_url': instance.contentUrl,
      'is_access': instance.isAccess,
      'isCompleted': instance.isCompleted,
      'isfeatured': instance.isfeatured,
      'Pdfcontents': instance.pdfcontents,
      'duration': instance.duration,
      'thumbnail': instance.thumbnail,
      'isBookmark': instance.isBookmark,
    };
