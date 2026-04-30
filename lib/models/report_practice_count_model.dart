import 'package:json_annotation/json_annotation.dart';

part 'report_practice_count_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ReportPracticeCountModel {
  int? correctAnswers;
  int? incorrectAnswers;
  @JsonKey(name: 'not_visited')
  int? notVisited;
  int? bookmarkCount;
  int? totalQuestions;

  ReportPracticeCountModel({
    this.correctAnswers,
    this.incorrectAnswers,
    this.notVisited,
    this.totalQuestions,
    this.bookmarkCount
  });

  factory ReportPracticeCountModel.fromJson(Map<String, dynamic> json) =>
      _$ReportPracticeCountModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReportPracticeCountModelToJson(this);
}