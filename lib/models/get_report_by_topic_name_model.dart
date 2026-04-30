import 'package:json_annotation/json_annotation.dart';

part 'get_report_by_topic_name_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ReportByTopicNameModel {
  ReportByTopicNameModel({
    this.correctAnswers,
    this.incorrectAnswers,
    this.skippedAnswers,
    this.guessedAnswers,
    this.totalQuestions,
    this.topicName,
    this.totalTime
  });

  factory ReportByTopicNameModel.fromJson(Map<String, dynamic> json) => _$ReportByTopicNameModelFromJson(json);

  int? correctAnswers;
  int? incorrectAnswers;
  int? skippedAnswers;
  int? guessedAnswers;
  int? totalQuestions;
  String? topicName;
  String? totalTime;


  Map<String, dynamic> toJson() => _$ReportByTopicNameModelToJson(this);
}
