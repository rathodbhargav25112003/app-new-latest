import 'package:json_annotation/json_annotation.dart';

part 'notes_subcategory_model.g.dart';

@JsonSerializable(explicitToJson: true)
class NotesSubCategoryModel {
  NotesSubCategoryModel({
    this.sId,
    this.subcategory_id,
    this.subcategoryName,
    this.categoryId,
    this.topic_id,
    this.topic_name,
    this.created_at,
    this.updated_at,
    this.description,
    this.sid,
    this.position,
    this.id,
    this.iV,
    this.topicCount,
    this.completPdfCount,
    this.progressCount,
    this.notStart,
    this.notes,
    this.bookmarkPdfCount,
    this.priorityLabel,
    this.priorityColor,
  });

  factory NotesSubCategoryModel.fromJson(Map<String, dynamic> json) => _$NotesSubCategoryModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  String? subcategory_id;
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
  int? completPdfCount;
  int? progressCount;
  int? notStart;
  int? bookmarkPdfCount;
  String? topic_id;
  String? topic_name;
  String? created_at;
  String? updated_at;
  String? description;
  String? sid;
  String? priorityLabel;
  String? priorityColor;

  Map<String, dynamic> toJson() => _$NotesSubCategoryModelToJson(this);
}