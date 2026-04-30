import 'package:json_annotation/json_annotation.dart';

part 'test_subcategory_model.g.dart';

@JsonSerializable(explicitToJson: true)
class TestSubCategoryModel {
  TestSubCategoryModel(
      {this.id,
      this.subcategory_id,
      this.subcategory_name,
      this.category_id,
      this.created_at,
      this.updated_at,
      this.userExamCount,
      required this.examCount,
      this.practiceAnswersCount,
      this.questionCount,
      this.description,
      this.isAttempt,
      required this.isCompleted,
      this.sid,
      this.examdata,
      this.allTestCount});

  factory TestSubCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$TestSubCategoryModelFromJson(json);

  int? id;
  String? subcategory_id;
  String? subcategory_name;
  String? category_id;
  String? created_at;
  String? updated_at;
  String? description;
  int examCount;
  bool isCompleted;
  int? userExamCount;
  int? questionCount;
  int? practiceAnswersCount;
  bool? isAttempt;
  String? sid;
  List<Examdata>? examdata;
  @JsonKey(name: 'AllTestCount')
  int? allTestCount;

  Map<String, dynamic> toJson() => _$TestSubCategoryModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Examdata {
  Examdata({
    this.negative_marking,
    this.deleted_at,
    this.sId,
    this.examId,
    this.examName,
    this.subcategoryId,
    this.timeDuration,
    this.marksDeducted,
    this.marksAwarded,
    this.created_at,
    this.updated_at,
    this.id,
  });

  factory Examdata.fromJson(Map<String, dynamic> json) =>
      _$ExamdataFromJson(json);

  bool? negative_marking;
  String? deleted_at;
  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: 'exam_id')
  String? examId;
  @JsonKey(name: 'exam_name')
  String? examName;
  @JsonKey(name: 'subcategory_id')
  String? subcategoryId;
  @JsonKey(name: 'time_duration')
  String? timeDuration;
  @JsonKey(name: 'marks_deducted')
  double? marksDeducted;
  @JsonKey(name: 'marks_awarded')
  int? marksAwarded;
  String? created_at;
  String? updated_at;
  int? id;

  Map<String, dynamic> toJson() => _$ExamdataToJson(this);
}
