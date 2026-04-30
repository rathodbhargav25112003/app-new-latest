import 'package:json_annotation/json_annotation.dart';

part 'plan_subcategory_model.g.dart';

@JsonSerializable(explicitToJson: true)
class PlanSubcategoryModel {
  PlanSubcategoryModel({
    this.id,
    this.sid,
    this.subcategory_name,
    this.description,
    this.category_id,
    this.created_at,
    this.updated_at,
    this.deleted_at,
    this.isMcq,
    this.isMock,
    this.isVideo,
    this.isNote,
    this.isLive,
  });

  factory PlanSubcategoryModel.fromJson(Map<String, dynamic> json) =>
      _$PlanSubcategoryModelFromJson(json);

  @JsonKey(name: '_id')
  String? sid;
  String? subcategory_name;
  String? description;
  String? category_id;
  String? created_at;
  String? updated_at;
  dynamic deleted_at;
  int? id;
  bool? isMcq;
  bool? isMock;
  bool? isVideo;
  bool? isNote;
  bool? isLive;

  Map<String, dynamic> toJson() => _$PlanSubcategoryModelToJson(this);
} 