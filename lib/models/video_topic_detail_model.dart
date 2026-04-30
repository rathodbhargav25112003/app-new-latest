import 'package:json_annotation/json_annotation.dart';

part 'video_topic_detail_model.g.dart';

@JsonSerializable(explicitToJson: true)
class VideoTopicDetailModel {
  VideoTopicDetailModel({
    this.topicName,
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
    this.isCompleted,
    this.pdfcontents,
    this.sId,
    this.title,
    this.subscriptionId,
    this.isfeatured,
    this.iV,
    this.duration,
    this.thumbnail,
    this.isBookmark,
  });

  factory VideoTopicDetailModel.fromJson(Map<String, dynamic> json) => _$VideoTopicDetailModelFromJson(json);

  @JsonKey(name: 'topic_name')
  String? topicName;
  @JsonKey(name: '_id')
  String? sId;
  int? id;
  @JsonKey(name: '__v')
  int? iV;
  @JsonKey(name: 'subcategory_id')
  String? subscriptionId;
  String? title;
  @JsonKey(name: 'topic_id')
  String? topicId;
  String? description;
  String? created_at;
  String? updated_at;
  String? sid;
  @JsonKey(name: 'content_id')
  String? contentId;
  @JsonKey(name: 'content_type')
  String? contentType;
  @JsonKey(name: 'video_url')
  String? videoUrl;
  @JsonKey(name: 'content_url')
  String? contentUrl;
  @JsonKey(name: 'is_access')
  bool? isAccess;
  bool? isCompleted;
  bool? isfeatured;
  @JsonKey(name: 'Pdfcontents')
  String? pdfcontents;
  int? duration;
  String? thumbnail;
  bool? isBookmark;

  Map<String, dynamic> toJson() => _$VideoTopicDetailModelToJson(this);
}
