// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_all_video_topic_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAllVideoTopicDetailModel _$GetAllVideoTopicDetailModelFromJson(
        Map<String, dynamic> json) =>
    GetAllVideoTopicDetailModel(
      topicId: json['content_id'] as String?,
      sId: json['_id'] as String?,
      created_at: json['created_at'] as String?,
      section: (json['section'] as List<dynamic>?)
          ?.map((e) => Section.fromJson(e as Map<String, dynamic>))
          .toList(),
      updated_at: json['updated_at'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$GetAllVideoTopicDetailModelToJson(
        GetAllVideoTopicDetailModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'content_id': instance.topicId,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'message': instance.message,
      'section': instance.section?.map((e) => e.toJson()).toList(),
    };

Section _$SectionFromJson(Map<String, dynamic> json) => Section(
      sectionId: json['_id'] as String?,
      sectionName: json['sectionName'] as String?,
      description: json['description'] as String?,
      chapter: (json['chapter'] as List<dynamic>?)
          ?.map((e) => Chapter.fromJson(e as Map<String, dynamic>))
          .toList(),
      sectionTime: json['sectionTime'] as String?,
    );

Map<String, dynamic> _$SectionToJson(Section instance) => <String, dynamic>{
      '_id': instance.sectionId,
      'sectionName': instance.sectionName,
      'sectionTime': instance.sectionTime,
      'description': instance.description,
      'chapter': instance.chapter?.map((e) => e.toJson()).toList(),
    };

Chapter _$ChapterFromJson(Map<String, dynamic> json) => Chapter(
      title: json['title'] as String?,
      chapterId: json['_id'] as String?,
      time: json['time'] as String?,
    );

Map<String, dynamic> _$ChapterToJson(Chapter instance) => <String, dynamic>{
      '_id': instance.chapterId,
      'title': instance.title,
      'time': instance.time,
    };
