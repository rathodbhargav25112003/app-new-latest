import 'package:json_annotation/json_annotation.dart';

part 'video_category_model.g.dart';

@JsonSerializable(explicitToJson: true)
class VideoCategoryModel {
  VideoCategoryModel({
    this.id,
    this.category_id,
    this.category_name,
    this.created_at,
    this.updated_at,
    this.video,
    this.subcategory,
    this.sid,
    this.description,
    this.subcategory_id,
    this.subcategory_name,
    this.topic_id,
    this.topic_name,
    this.progressCount,
    this.completedVideoCount,
    this.notStart,
    this.bookmarkVideoCount,
    this.priorityLabel,
    this.priorityColor,
  });

  factory VideoCategoryModel.fromJson(Map<String, dynamic> json) => _$VideoCategoryModelFromJson(json);

  @JsonKey(name: '_id')
  String? id;
  String? category_id;
  String? category_name;
  String? created_at;
  String? updated_at;
  int? subcategory;
  int? video;
  String? sid;
  String? description;
  String? subcategory_id;
  String? subcategory_name;
  String? topic_id;
  String? topic_name;
  int? progressCount;
  int? completedVideoCount;
  int? notStart;
  int? bookmarkVideoCount;
  String? priorityLabel;
  String? priorityColor;

  Map<String, dynamic> toJson() => _$VideoCategoryModelToJson(this);
}