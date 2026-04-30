import 'package:json_annotation/json_annotation.dart';

part 'notes_topic_detail_model.g.dart';

@JsonSerializable(explicitToJson: true)
class NotesTopicDetailModel {
  NotesTopicDetailModel({
    this.topicId,
    this.topicName,
    this.description,
    this.created_at,
    this.updated_at,
  });

  factory NotesTopicDetailModel.fromJson(Map<String, dynamic> json) => _$NotesTopicDetailModelFromJson(json);

  @JsonKey(name: 'sid')
  String? topicId;
  @JsonKey(name:"topic_name")
  String? topicName;
  String? description;
  String? created_at;
  String? updated_at;
  Contents? contents;

  Map<String, dynamic> toJson() => _$NotesTopicDetailModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Contents {
  Contents({
    this.is_access,
    this.id,
    this.contentId,
    this.contentType,
    this.contentUrl,
    this.topicId,
    this.subcategoryName,
    this.categoryName,
    this.subcategoryId,
    this.categoryId,
  });

  factory Contents.fromJson(Map<String, dynamic> json) =>
      _$ContentsFromJson(json);

  bool? is_access;
  @JsonKey(name: '_id')
  String? id;
  @JsonKey(name: 'content_id')
  String? contentId;
  @JsonKey(name: 'content_type')
  String? contentType;
  @JsonKey(name: 'content_url')
  String? contentUrl;
  @JsonKey(name: 'topic_id')
  String? topicId;
  @JsonKey(name:"subcategory_name")
  String? subcategoryName;
  @JsonKey(name:"category_name")
  String? categoryName;
  @JsonKey(name: 'subcategory_id')
  String? subcategoryId;
  @JsonKey(name: 'category_id')
  String? categoryId;

  Map<String, dynamic> toJson() => _$ContentsToJson(this);
}

