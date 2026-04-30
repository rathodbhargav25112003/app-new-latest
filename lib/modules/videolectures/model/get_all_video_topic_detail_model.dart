import 'package:json_annotation/json_annotation.dart';

part 'get_all_video_topic_detail_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GetAllVideoTopicDetailModel {
  GetAllVideoTopicDetailModel({
    this.topicId,
    this.sId,
    this.created_at,
    this.section,
    this.updated_at,
    this.message
  });

  factory GetAllVideoTopicDetailModel.fromJson(Map<String, dynamic> json) => _$GetAllVideoTopicDetailModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: 'content_id')
  String? topicId;
  String? created_at;
  String? updated_at;
  String? message;
  List<Section>? section;

  Map<String, dynamic> toJson() => _$GetAllVideoTopicDetailModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Section {
  Section({
    this.sectionId,
    this.sectionName,
    this.description,
    this.chapter,
    this.sectionTime,
  });

  factory Section.fromJson(Map<String, dynamic> json) => _$SectionFromJson(json);

  @JsonKey(name: '_id')
  String? sectionId;
  String? sectionName;
  String? sectionTime;
  String? description;
  List<Chapter>? chapter;

  Map<String, dynamic> toJson() => _$SectionToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Chapter {
  Chapter({
    this.title,
    this.chapterId,
    this.time
  });

  factory Chapter.fromJson(Map<String, dynamic> json) => _$ChapterFromJson(json);

  @JsonKey(name: '_id')
  String? chapterId;
  String? title;
  String? time;

  Map<String, dynamic> toJson() => _$ChapterToJson(this);
}
