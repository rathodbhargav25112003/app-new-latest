import 'package:json_annotation/json_annotation.dart';

part 'custom_test_topic_by_subcategory_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CustomTestTopicBySubCategoryModel {
  CustomTestTopicBySubCategoryModel({
    this.sId,
    this.topicName,
    this.description,
    this.questionCount,
    this.subCategoryId,
    this.categoryId,
  });

  factory CustomTestTopicBySubCategoryModel.fromJson(
          Map<String, dynamic> json) =>
      _$CustomTestTopicBySubCategoryModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: 'topic_name')
  String? topicName;
  String? description;
  int? questionCount;
  @JsonKey(name: 'subcategory_id')
  String? subCategoryId;
  @JsonKey(name: 'category_id')
  String? categoryId;
  Map<String, dynamic> toJson() =>
      _$CustomTestTopicBySubCategoryModelToJson(this);
}
