import 'package:json_annotation/json_annotation.dart';
import 'package:shusruta_lms/models/video_data_model.dart';

part 'video_topic_model.g.dart';

@JsonSerializable(explicitToJson: true)
class VideoTopicModel {
  VideoTopicModel({
    this.topic,
    this.id,
    this.contentId,
    this.contentType,
    this.videoUrl,
    this.topicId,
    this.description,
    this.created_at,
    this.updated_at,
    this.sid,
    this.contentUrl,
    this.isAccess,
    this.sId,
    this.iV,
    this.isfeatured,
    this.isCompleted,
    this.title,
    this.pdfContents,
    this.videoLink,
    this.duration,
    this.thumbnail,
    this.pausedTime,
    this.notStart,
    this.videoFiles,
    this.downloadVideo,
    this.category_id,
    this.subcategory_id,
    this.isBookmark,
    this.annotationData,
    this.annotation,
    this.plan_id,
    this.day,
    this.isfreeTrail,
    this.hlsLink,
  });

  factory VideoTopicModel.fromJson(Map<String, dynamic> json) => _$VideoTopicModelFromJson(json);

  String? topic;
  int? id;
  String? subcategory_id;
  @JsonKey(name: 'topic_id')
  String? topicId;
  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: '__v')
  int? iV;
  bool? isfeatured;
  bool? isCompleted;
  String? description;
  String? created_at;
  String? updated_at;
  String? title;
  String? sid;
  @JsonKey(name: 'content_id')
  String? contentId;
  @JsonKey(name: 'content_type')
  String? contentType;
  @JsonKey(name: 'video_url')
  String? videoUrl;
  @JsonKey(name: 'content_url')
  String? contentUrl;
  @JsonKey(name: 'pdf_id')
  String? pdfId;
  @JsonKey(name: 'is_access')
  bool? isAccess;
  @JsonKey(name: 'Pdfcontents')
  String? pdfContents;
  String? videoLink;
  int? duration;
  String? thumbnail;
  String? pausedTime;
  String? category_id;
  bool? notStart;
  List<Files>? videoFiles;
  List<Download>? downloadVideo;
  bool? isBookmark;
  List<AnnotationList>? annotation;
  @JsonKey(name: 'notesAnnotation')
  Map<String, dynamic>? annotationData;
  String? plan_id;
  String? day;
  bool? isfreeTrail;  
  String? hlsLink;
  
  Map<String, dynamic> toJson() => _$VideoTopicModelToJson(this);
}

// @JsonSerializable(explicitToJson: true)
// class Files {
//   Files({
//     this.quality,
//     this.rendition,
//     this.link,
//     this.videoSize,
//   });
//
//   factory Files.fromJson(Map<String, dynamic> json) => _$FilesFromJson(json);
//
//   String? quality;
//   String? rendition;
//   String? link;
//   @JsonKey(name: 'size_short')
//   String? videoSize;
//
//   Map<String, dynamic> toJson() => _$FilesToJson(this);
// }
//
// @JsonSerializable(explicitToJson: true)
// class Download {
//   Download({
//     this.quality,
//     this.rendition,
//     this.link,
//     this.videoSize,
//   });
//
//   factory Download.fromJson(Map<String, dynamic> json) => _$DownloadFromJson(json);
//
//   String? quality;
//   String? rendition;
//   String? link;
//   @JsonKey(name: 'size_short')
//   String? videoSize;
//
//   Map<String, dynamic> toJson() => _$DownloadToJson(this);
// }
//
//
// @JsonSerializable(explicitToJson: true)
// class AnnotationList {
//   AnnotationList({
//     this.annotationType,
//     this.bounds,
//     this.pageNumber,
//     this.text,
//   });
//
//   factory AnnotationList.fromJson(Map<String, dynamic> json) => _$AnnotationListFromJson(json);
//
//   String? annotationType;
//   String? bounds;
//   int? pageNumber;
//   String? text;
//
//   Map<String, dynamic> toJson() => _$AnnotationListToJson(this);
// }
