import 'package:json_annotation/json_annotation.dart';

part 'quiz_report_by_category_model.g.dart';

@JsonSerializable(explicitToJson: true)
class QuizReportByCategoryModel {
  QuizReportByCategoryModel({
    this.id,
    this.questionCount,
    this.incorrectAnswers,
    this.correctAnswers,
    this.myScore,
    this.percentage,
    this.totalMarks
  });

  factory QuizReportByCategoryModel.fromJson(Map<String, dynamic> json) => _$QuizReportByCategoryModelFromJson(json);

  @JsonKey(name:"_id")
  String? id;
  num? myScore;
  num? totalMarks;
  int? correctAnswers;
  int? incorrectAnswers;
  int? questionCount;
  num? percentage;


  Map<String, dynamic> toJson() => _$QuizReportByCategoryModelToJson(this);
}
