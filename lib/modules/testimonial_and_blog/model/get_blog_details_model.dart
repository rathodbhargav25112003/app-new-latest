import 'package:json_annotation/json_annotation.dart';

part 'get_blog_details_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GetBlogDetailsModel{
  GetBlogDetailsModel({
    this.id,
    this.sId,
    this.title,
    this.image,
    this.alias,
    this.blogCategoryId,
    this.blogCategoryName,
    this.content
  });

  factory GetBlogDetailsModel.fromJson(Map<String, dynamic> json) => _$GetBlogDetailsModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: 'Image')
  String? image;
  String? content;
  String? title;
  String? alias;
  @JsonKey(name: 'blogCategory_id')
  String? blogCategoryId;
  String? blogCategoryName;
  int? id;

  Map<String, dynamic> toJson() => _$GetBlogDetailsModelToJson(this);
}
