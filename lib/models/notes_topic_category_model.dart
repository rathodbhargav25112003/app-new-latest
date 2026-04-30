import 'package:json_annotation/json_annotation.dart';

part 'notes_topic_category_model.g.dart';

@JsonSerializable(explicitToJson: true)
class NotesTopicCategoryModel {
  NotesTopicCategoryModel({
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
    this.notes,
    this.pdfCount,
    this.completPdfCount,
    this.progressCount,
    this.notStart,
    this.bookmarkPdfCount,
    this.priorityLabel,
    this.priorityColor,
  });

  factory NotesTopicCategoryModel.fromJson(Map<String, dynamic> json) => _$NotesTopicCategoryModelFromJson(json);

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
  @JsonKey(name: 'Notes')
  int? notes;
  String? topic_id;
  @JsonKey(name: 'topic_name')
  String? topicName;
  String? created_at;
  String? updated_at;
  String? description;
  String? sid;
  int? pdfCount;
  int? completPdfCount;
  int? progressCount;
  int? notStart;
  int? bookmarkPdfCount;
  String? priorityLabel;
  String? priorityColor;

  Map<String, dynamic> toJson() => _$NotesTopicCategoryModelToJson(this);
}
// class NotesTopicCategoryModel {
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
//   int? pdfCount;
//   String? sid;
//
//   NotesTopicCategoryModel(
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
//         this.pdfCount,
//         this.sid});
//
//   NotesTopicCategoryModel.fromJson(Map<String, dynamic> json) {
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
//     pdfCount = json['pdfCount'];
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
//     data['pdfCount'] = this.pdfCount;
//     data['sid'] = this.sid;
//     return data;
//   }
// }
