import 'package:json_annotation/json_annotation.dart';

part 'test_category_model.g.dart';

@JsonSerializable(explicitToJson: true)
class TestCategoryModel {
  TestCategoryModel(
      {this.id,
      this.category_id,
      this.category_name,
      this.created_at,
      this.updated_at,
      this.Test,
      this.subcategory,
      required this.examCount,
      this.sid,
      this.isNeetSS = true,
      this.description,
      this.isAttempt,
      this.isCompleted,
      this.isSeries = false,
      this.allTestCount,
      this.sId});

  factory TestCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$TestCategoryModelFromJson(json);

  int? id;
  String? category_id;
  String? category_name;
  String? created_at;
  String? updated_at;
  int? subcategory;
  int? Test;
  int? examCount;
  int? userExamCount;
  int? questionCount;
  int? practiceAnswersCount;
  String? sid;
  String? description;
  @JsonKey(name: 'Neet_SS')
  bool? isNeetSS;
  @JsonKey(name: '_id')
  String? sId;
  bool? isAttempt;
  bool? isSeries;
  bool? isCompleted;
  @JsonKey(name: 'AllTestCount')
  int? allTestCount;

  Map<String, dynamic> toJson() => _$TestCategoryModelToJson(this);
}
