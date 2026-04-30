import 'package:json_annotation/json_annotation.dart';

part 'plan_category_model.g.dart';

@JsonSerializable(explicitToJson: true)
class PlanCategoryModel {
  PlanCategoryModel({
    this.id,
    this.sid,
    this.category_name,
    this.description,
    this.created_at,
    this.deleted_at,
  });

  factory PlanCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$PlanCategoryModelFromJson(json);

  @JsonKey(name: '_id')
  String? sid;
  String? category_name;
  String? description;
  String? created_at;
  dynamic deleted_at;
  int? id;

  Map<String, dynamic> toJson() => _$PlanCategoryModelToJson(this);
} 