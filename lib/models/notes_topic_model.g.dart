// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_topic_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotesTopicModel _$NotesTopicModelFromJson(Map<String, dynamic> json) =>
    NotesTopicModel(
      id: (json['id'] as num?)?.toInt(),
      topicId: json['topic_id'] as String?,
      topicName: json['topic'] as String?,
      topic_name: json['topic_name'] as String?,
      subcategoryId: json['subcategory_id'] as String?,
      description: json['description'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      sid: json['sid'] as String?,
      sId: json['_id'] as String?,
      contentUrl: json['content_url'] as String?,
      videoUrl: json['video_url'] as String?,
      subscriptionId: (json['subscription_id'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isfeatured: json['isfeatured'] as bool?,
      isAccess: json['is_access'] as bool?,
      bannerImg: json['Banner_img'] as String?,
      contentType: json['content_type'] as String?,
      categoryId: json['category_id'] as String?,
      iV: (json['__v'] as num?)?.toInt(),
      title: json['title'] as String?,
      category_name: json['category_name'] as String?,
      subcategory_name: json['subcategory_name'] as String?,
      isCompleted: json['isCompleted'] as bool?,
      isBookmark: json['isBookmark'] as bool?,
      isPaused: json['isPaused'] as bool?,
      notStart: json['notStart'] as bool?,
      pageNumber: (json['pageNumber'] as num?)?.toInt(),
      annotation: (json['annotation'] as List<dynamic>?)
          ?.map((e) => AnnotationData.fromJson(e as Map<String, dynamic>))
          .toList(),
      plan_id: json['plan_id'] as String?,
      day: json['day'] as String?,
      isfreeTrail: json['isfreeTrail'] as bool?,
      annotationData: json['notesAnnotation'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$NotesTopicModelToJson(NotesTopicModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'topic_id': instance.topicId,
      '_id': instance.sId,
      'topic': instance.topicName,
      'category_name': instance.category_name,
      'subcategory_name': instance.subcategory_name,
      'topic_name': instance.topic_name,
      'subcategory_id': instance.subcategoryId,
      'subscription_id': instance.subscriptionId,
      'video_url': instance.videoUrl,
      'content_url': instance.contentUrl,
      'Banner_img': instance.bannerImg,
      'description': instance.description,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'sid': instance.sid,
      'is_access': instance.isAccess,
      'isfeatured': instance.isfeatured,
      'content_type': instance.contentType,
      'category_id': instance.categoryId,
      '__v': instance.iV,
      'pageNumber': instance.pageNumber,
      'title': instance.title,
      'isCompleted': instance.isCompleted,
      'isBookmark': instance.isBookmark,
      'isPaused': instance.isPaused,
      'notStart': instance.notStart,
      'annotation': instance.annotation?.map((e) => e.toJson()).toList(),
      'plan_id': instance.plan_id,
      'day': instance.day,
      'isfreeTrail': instance.isfreeTrail,
      'notesAnnotation': instance.annotationData,
    };

AnnotationData _$AnnotationDataFromJson(Map<String, dynamic> json) =>
    AnnotationData(
      annotationType: json['annotationType'] as String?,
      bounds: json['bounds'] as String?,
      pageNumber: (json['pageNumber'] as num?)?.toInt(),
      text: json['text'] as String?,
    );

Map<String, dynamic> _$AnnotationDataToJson(AnnotationData instance) =>
    <String, dynamic>{
      'annotationType': instance.annotationType,
      'bounds': instance.bounds,
      'pageNumber': instance.pageNumber,
      'text': instance.text,
    };
