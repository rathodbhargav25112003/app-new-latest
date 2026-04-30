import 'package:json_annotation/json_annotation.dart';

part 'notes_category_model.g.dart';

@JsonSerializable(explicitToJson: true)
class NotesCategoryModel {
  NotesCategoryModel({
    this.id,
    this.category_id,
    this.category_name,
    this.created_at,
    this.updated_at,
    this.notes,
    this.subcategory,
    this.sid,
    this.description,
    this.subcategory_id,
    this.subcategory_name,
    this.topic_id,
    this.topic_name,
    this.completedPdfCount,
    this.progressCount,
    this.notStart,
    this.bookmarkPdfCount,
    this.priorityLabel,
    this.priorityColor,
  });

  factory NotesCategoryModel.fromJson(Map<String, dynamic> json) => _$NotesCategoryModelFromJson(json);

  @JsonKey(name: '_id')
  String? id;
  String? category_id;
  String? category_name;
  String? created_at;
  String? updated_at;
  int? subcategory;
  @JsonKey(name: "Notes")
  int? notes;
  String? sid;
  String? description;
  String? subcategory_id;
  String? subcategory_name;
  String? topic_id;
  String? topic_name;
  int? completedPdfCount;
  int? progressCount;
  int? notStart;
  int? bookmarkPdfCount;
  String? priorityLabel;
  String? priorityColor;

  Map<String, dynamic> toJson() => _$NotesCategoryModelToJson(this);
}