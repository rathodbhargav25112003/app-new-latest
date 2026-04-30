import 'package:json_annotation/json_annotation.dart';

part 'bookmark_subcategory_model.g.dart';

@JsonSerializable(explicitToJson: true)
class BookMarkSubCategoryModel {
  BookMarkSubCategoryModel({
    this.subcategory_id,
    this.subcategory_name,
    this.created_at,
    this.category_id,
    this.questionCount,
  });

  factory BookMarkSubCategoryModel.fromJson(Map<String, dynamic> json) => _$BookMarkSubCategoryModelFromJson(json);

  String? subcategory_id;
  String? subcategory_name;
  String? created_at;
  String? category_id;
  int? questionCount;

  Map<String, dynamic> toJson() => _$BookMarkSubCategoryModelToJson(this);
}