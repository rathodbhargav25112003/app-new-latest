import 'package:json_annotation/json_annotation.dart';

part 'custom_test_exam_by_topic_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CustomTestExamByTopicModel {
  CustomTestExamByTopicModel({
    this.sId,
    this.examName,
    this.timeDuration,
    this.questionCount,
    this.remainingAttempts,
    this.isAttempt,
    this.isGivenTest,
    this.categoryId,
    this.subCategoryId,
    this.topicId,
  });

  factory CustomTestExamByTopicModel.fromJson(Map<String, dynamic> json) => _$CustomTestExamByTopicModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: 'exam_name')
  String? examName;
  @JsonKey(name: 'time_duration')
  String? timeDuration;
  int? questionCount;
  int? remainingAttempts;
  bool? isAttempt;
  bool? isGivenTest;
  @JsonKey(name: 'category_id')
  String? categoryId;
  @JsonKey(name: 'subcategory_id')
  String? subCategoryId;
  @JsonKey(name: 'topic_id')
  String? topicId;
  Map<String, dynamic> toJson() => _$CustomTestExamByTopicModelToJson(this);
}