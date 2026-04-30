import 'package:json_annotation/json_annotation.dart';

part 'search_data_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SearchDataModel {
  SearchDataModel({
    this.id,
    this.category_name,
    this.category_id,
    this.created_at,
    this.updated_at,
    this.subcategory_id,
    this.subcategory_name,
    this.topic_id,
    this.topic_name,
    this.description
  });

  factory SearchDataModel.fromJson(Map<String, dynamic> json) => _$SearchDataModelFromJson(json);

  @JsonKey(name: '_id')
  String? id;
  String? category_name;
  String? category_id;
  String? created_at;
  String? updated_at;
  String? subcategory_id;
  String? subcategory_name;
  String? topic_id;
  String? topic_name;
  String? description;

  Map<String, dynamic> toJson() => _$SearchDataModelToJson(this);
}