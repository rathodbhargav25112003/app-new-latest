// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_topic_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoTopicModel _$VideoTopicModelFromJson(Map<String, dynamic> json) =>
    VideoTopicModel(
      topic: json['topic'] as String?,
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
      sId: json['_id'] as String?,
      iV: (json['__v'] as num?)?.toInt(),
      isfeatured: json['isfeatured'] as bool?,
      isCompleted: json['isCompleted'] as bool?,
      title: json['title'] as String?,
      pdfContents: json['Pdfcontents'] as String?,
      videoLink: json['videoLink'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      thumbnail: json['thumbnail'] as String?,
      pausedTime: json['pausedTime'] as String?,
      notStart: json['notStart'] as bool?,
      videoFiles: (json['videoFiles'] as List<dynamic>?)
          ?.map((e) => Files.fromJson(e as Map<String, dynamic>))
          .toList(),
      downloadVideo: (json['downloadVideo'] as List<dynamic>?)
          ?.map((e) => Download.fromJson(e as Map<String, dynamic>))
          .toList(),
      category_id: json['category_id'] as String?,
      subcategory_id: json['subcategory_id'] as String?,
      isBookmark: json['isBookmark'] as bool?,
      annotationData: json['notesAnnotation'] as Map<String, dynamic>?,
      annotation: (json['annotation'] as List<dynamic>?)
          ?.map((e) => AnnotationList.fromJson(e as Map<String, dynamic>))
          .toList(),
      plan_id: json['plan_id'] as String?,
      day: json['day'] as String?,
      isfreeTrail: json['isfreeTrail'] as bool?,
      hlsLink: json['hlsLink'] as String?,
    )..pdfId = json['pdf_id'] as String?;

Map<String, dynamic> _$VideoTopicModelToJson(VideoTopicModel instance) =>
    <String, dynamic>{
      'topic': instance.topic,
      'id': instance.id,
      'subcategory_id': instance.subcategory_id,
      'topic_id': instance.topicId,
      '_id': instance.sId,
      '__v': instance.iV,
      'isfeatured': instance.isfeatured,
      'isCompleted': instance.isCompleted,
      'description': instance.description,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'title': instance.title,
      'sid': instance.sid,
      'content_id': instance.contentId,
      'content_type': instance.contentType,
      'video_url': instance.videoUrl,
      'content_url': instance.contentUrl,
      'pdf_id': instance.pdfId,
      'is_access': instance.isAccess,
      'Pdfcontents': instance.pdfContents,
      'videoLink': instance.videoLink,
      'duration': instance.duration,
      'thumbnail': instance.thumbnail,
      'pausedTime': instance.pausedTime,
      'category_id': instance.category_id,
      'notStart': instance.notStart,
      'videoFiles': instance.videoFiles?.map((e) => e.toJson()).toList(),
      'downloadVideo': instance.downloadVideo?.map((e) => e.toJson()).toList(),
      'isBookmark': instance.isBookmark,
      'annotation': instance.annotation?.map((e) => e.toJson()).toList(),
      'notesAnnotation': instance.annotationData,
      'plan_id': instance.plan_id,
      'day': instance.day,
      'isfreeTrail': instance.isfreeTrail,
      'hlsLink': instance.hlsLink,
    };
