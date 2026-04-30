import 'package:json_annotation/json_annotation.dart';

part 'test_topic_model.g.dart';

@JsonSerializable(explicitToJson: true)
class TestTopicModel {
  TestTopicModel({
    this.id,
    this.topicId,
    this.topicName,
    this.subcategoryId,
    this.description,
    this.created_at,
    this.updated_at,
    this.userExamCount,
    required this.examCount,
    required this.isCompleted,
    this.practiceAnswersCount,
    this.questionCount,
    this.sid,
    this.isAttempt,
    this.allTestCount,
  });

  factory TestTopicModel.fromJson(Map<String, dynamic> json) =>
      _$TestTopicModelFromJson(json);

  int? id;
  @JsonKey(name: 'topic_id')
  String? topicId;
  @JsonKey(name: "topic_name")
  String? topicName;
  @JsonKey(name: 'subcategory_id')
  String? subcategoryId;
  String? description;
  int examCount;
  bool isCompleted;
  int? userExamCount;
  int? questionCount;
  int? practiceAnswersCount;
  String? created_at;
  String? updated_at;
  String? sid;
  bool? isAttempt;
  @JsonKey(name: 'AllTestCount')
  int? allTestCount;

  Map<String, dynamic> toJson() => _$TestTopicModelToJson(this);
}
