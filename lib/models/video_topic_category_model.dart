import 'package:json_annotation/json_annotation.dart';

part 'video_topic_category_model.g.dart';

@JsonSerializable(explicitToJson: true)
class VideoTopicCategoryModel {
  VideoTopicCategoryModel({
    this.sId,
    this.subcategoryId,
    this.subcategoryName,
    this.categoryId,
    this.topic_id,
    this.topicName,
    this.created_at,
    this.updated_at,
    this.description,
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

  factory VideoTopicCategoryModel.fromJson(Map<String, dynamic> json) => _$VideoTopicCategoryModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: 'subcategory_id')
  String? subcategoryId;
  @JsonKey(name: 'subcategory_name')
  String? subcategoryName;
  @JsonKey(name: 'category_id')
  String? categoryId;
  int? position;
  int? id;
  @JsonKey(name: '__v')
  int? iV;
  int? topicCount;
  String? topic_id;
  @JsonKey(name: 'topic_name')
  String? topicName;
  String? created_at;
  String? updated_at;
  String? description;
  String? sid;
  int? video;
  int? videoCount;
  int? completVideoCount;
  int? progressCount;
  int? completedVideoCount;
  int? notStart;
  int? bookmarkVideoCount;

  Map<String, dynamic> toJson() => _$VideoTopicCategoryModelToJson(this);
}

// class VideoTopicCategoryModel {
//   Null? deletedAt;
//   String? sId;
//   String? topicName;
//   String? subcategoryId;
//   String? description;
//   int? position;
//   String? createdAt;
//   String? updatedAt;
//   int? id;
//   int? iV;
//   int? video;
//   String? sid;
//
//   VideoTopicCategoryModel(
//       {this.deletedAt,
//         this.sId,
//         this.topicName,
//         this.subcategoryId,
//         this.description,
//         this.position,
//         this.createdAt,
//         this.updatedAt,
//         this.id,
//         this.iV,
//         this.video,
//         this.sid});
//
//   VideoTopicCategoryModel.fromJson(Map<String, dynamic> json) {
//     deletedAt = json['deleted_at'];
//     sId = json['_id'];
//     topicName = json['topic_name'];
//     subcategoryId = json['subcategory_id'];
//     description = json['description'];
//     position = json['position'];
//     createdAt = json['created_at'];
//     updatedAt = json['updated_at'];
//     id = json['id'];
//     iV = json['__v'];
//     video = json['video'];
//     sid = json['sid'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['deleted_at'] = this.deletedAt;
//     data['_id'] = this.sId;
//     data['topic_name'] = this.topicName;
//     data['subcategory_id'] = this.subcategoryId;
//     data['description'] = this.description;
//     data['position'] = this.position;
//     data['created_at'] = this.createdAt;
//     data['updated_at'] = this.updatedAt;
//     data['id'] = this.id;
//     data['__v'] = this.iV;
//     data['video'] = this.video;
//     data['sid'] = this.sid;
//     return data;
//   }
// }
