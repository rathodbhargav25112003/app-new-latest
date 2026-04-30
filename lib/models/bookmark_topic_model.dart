import 'package:json_annotation/json_annotation.dart';

part 'bookmark_topic_model.g.dart';

@JsonSerializable(explicitToJson: true)
class BookMarkTopicModel {
  BookMarkTopicModel({
    this.topic_id,
    this.topic_name,
    this.created_at,
    this.subcategory_id,
    this.questionCount,
  });

  factory BookMarkTopicModel.fromJson(Map<String, dynamic> json) => _$BookMarkTopicModelFromJson(json);

  String? topic_id;
  String? topic_name;
  String? created_at;
  String? subcategory_id;
  int? questionCount;

  Map<String, dynamic> toJson() => _$BookMarkTopicModelToJson(this);
}