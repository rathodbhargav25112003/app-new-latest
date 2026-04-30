import 'package:json_annotation/json_annotation.dart';

part 'bookmark_category_model.g.dart';

@JsonSerializable(explicitToJson: true)
class BookMarkCategoryModel {
  BookMarkCategoryModel({
    this.category_id,
    this.category_name,
    this.isNeetss,
    this.created_at,
    this.questionCount = 0,
  });

  factory BookMarkCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$BookMarkCategoryModelFromJson(json);

  String? category_id;
  String? category_name;
  @JsonKey(name: 'Neet_SS')
  bool? isNeetss;
  String? created_at;
  int? questionCount;

  Map<String, dynamic> toJson() => _$BookMarkCategoryModelToJson(this);
}
