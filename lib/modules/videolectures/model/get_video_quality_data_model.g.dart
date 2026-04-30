// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_video_quality_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetVideoQualityDataModel _$GetVideoQualityDataModelFromJson(
        Map<String, dynamic> json) =>
    GetVideoQualityDataModel(
      thumbnail: json['thumbnail'] as String?,
      files: (json['files'] as List<dynamic>?)
          ?.map((e) => Files.fromJson(e as Map<String, dynamic>))
          .toList(),
      download: (json['download'] as List<dynamic>?)
          ?.map((e) => Download.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetVideoQualityDataModelToJson(
        GetVideoQualityDataModel instance) =>
    <String, dynamic>{
      'thumbnail': instance.thumbnail,
      'files': instance.files?.map((e) => e.toJson()).toList(),
      'download': instance.download?.map((e) => e.toJson()).toList(),
    };

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
