import 'package:json_annotation/json_annotation.dart';

part 'custom_test_sub_by_category_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CustomTestSubByCategoryModel {
  CustomTestSubByCategoryModel({
    this.sId,
    this.subcategoryName,
    this.description,
    this.questionCount,
    this.categoryId,
  });

  factory CustomTestSubByCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CustomTestSubByCategoryModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: 'subcategory_name')
  String? subcategoryName;
  String? description;
  int? questionCount;
  @JsonKey(name: 'category_id')
  String? categoryId;
  Map<String, dynamic> toJson() => _$CustomTestSubByCategoryModelToJson(this);
}
