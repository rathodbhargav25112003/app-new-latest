// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Files _$FilesFromJson(Map<String, dynamic> json) => Files(
      quality: json['quality'] as String?,
      rendition: json['rendition'] as String?,
      link: json['link'] as String?,
      videoSize: json['size_short'] as String?,
    );

Map<String, dynamic> _$FilesToJson(Files instance) => <String, dynamic>{
      'quality': instance.quality,
      'rendition': instance.rendition,
      'link': instance.link,
      'size_short': instance.videoSize,
    };

Download _$DownloadFromJson(Map<String, dynamic> json) => Download(
      quality: json['quality'] as String?,
      rendition: json['rendition'] as String?,
      link: json['link'] as String?,
      videoSize: json['size_short'] as String?,
    );

Map<String, dynamic> _$DownloadToJson(Download instance) => <String, dynamic>{
      'quality': instance.quality,
      'rendition': instance.rendition,
      'link': instance.link,
      'size_short': instance.videoSize,
    };

AnnotationList _$AnnotationListFromJson(Map<String, dynamic> json) =>
    AnnotationList(
      annotationType: json['annotationType'] as String?,
      bounds: json['bounds'] as String?,
      pageNumber: (json['pageNumber'] as num?)?.toInt(),
      text: json['text'] as String?,
    );

Map<String, dynamic> _$AnnotationListToJson(AnnotationList instance) =>
    <String, dynamic>{
      'annotationType': instance.annotationType,
      'bounds': instance.bounds,
      'pageNumber': instance.pageNumber,
      'text': instance.text,
    };
