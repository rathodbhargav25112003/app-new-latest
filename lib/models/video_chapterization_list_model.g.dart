// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_chapterization_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoChapterizationListModel _$VideoChapterizationListModelFromJson(
        Map<String, dynamic> json) =>
    VideoChapterizationListModel(
      uri: json['uri'] as String?,
      title: json['title'] as String?,
      timeCode: (json['timecode'] as num?)?.toInt(),
    );

Map<String, dynamic> _$VideoChapterizationListModelToJson(
        VideoChapterizationListModel instance) =>
    <String, dynamic>{
      'uri': instance.uri,
      'title': instance.title,
      'timecode': instance.timeCode,
    };
