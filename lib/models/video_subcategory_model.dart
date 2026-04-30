import 'package:json_annotation/json_annotation.dart';

part 'video_subcategory_model.g.dart';

@JsonSerializable(explicitToJson: true)
class VideoSubCategoryModel {
  VideoSubCategoryModel({
    this.sId,
    this.subcategory_id,
    this.subcategoryName,
    this.categoryId,
    this.topic_id,
    this.topic_name,
    this.description,
    this.created_at,
    this.updated_at,
    this.video,
    this.sid,
    this.position,
    this.id,
    this.iV,
    this.topicCount,
    this.videoCount,
    this.completVideoCount,
    this.progressCount,
    this.completedVideoCount,
    this.notStart,
    this.bookmarkVideoCount,
  });

  factory VideoSubCategoryModel.fromJson(Map<String, dynamic> json) => _$VideoSubCategoryModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  String? subcategory_id;
  @JsonKey(name: 'subcategory_name')
  String? subcategoryName;
  String? topic_id;
  String? topic_name;
  String? description;
  @JsonKey(name: 'category_id')
  String? categoryId;
  String? created_at;
  String? updated_at;
  int? video;
  int? id;
  int? position;
  @JsonKey(name: '__v')
  int? iV;
  int? topicCount;
  int? videoCount;
  int? completVideoCount;
  String? sid;
  int? progressCount;
  int? completedVideoCount;
  int? notStart;
  int? bookmarkVideoCount;

  Map<String, dynamic> toJson() => _$VideoSubCategoryModelToJson(this);
}