import 'package:json_annotation/json_annotation.dart';

part 'searched_data_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SearchedDataModel{
  SearchedDataModel({
    this.id,
    this.categoryName,
    this.subcategoryName,
    this.subName,
    this.topicName,
    this.description,
    this.title,
    this.contentUrl,
    this.topicId,
    this.subcategoryId,
    this.categoryId,
    this.err,
  });

  factory SearchedDataModel.fromJson(Map<String, dynamic> json) => _$SearchedDataModelFromJson(json);

  @JsonKey(name: '_id')
  String? id;
  @JsonKey(name: 'category_name')
  String? categoryName;
  @JsonKey(name: 'subcategory_name')
  String? subcategoryName;
  @JsonKey(name: 'sub_name')
  String? subName;
  @JsonKey(name: 'content_url')
  String? contentUrl;
  @JsonKey(name: 'topic_name')
  String? topicName;
  @JsonKey(name: 'subcategory_id')
  String? subcategoryId;
  @JsonKey(name: 'topic_id')
  String? topicId;
  @JsonKey(name: 'category_id')
  String? categoryId;
  String? title;
  String? description;
  ErrorModel? err;

  Map<String, dynamic> toJson() => _$SearchedDataModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ErrorModel {
  ErrorModel({
    this.code,
    this.message,
    this.params,
  });

  factory ErrorModel.fromJson(Map<String, dynamic> json) =>
      _$ErrorModelFromJson(json);

  final dynamic code;
  final String? message;
  final Map<String, dynamic>? params;

  Map<String, dynamic> toJson() => _$ErrorModelToJson(this);
}
