import 'package:json_annotation/json_annotation.dart';

part 'question_pallete_model.g.dart';

@JsonSerializable(explicitToJson: true)
class QuestionPalleteModel {
  QuestionPalleteModel({
    this.questionId,
    this.questionNumber,
    this.isAttempted,
    this.isMarkedForReview,
    this.isAttemptedMarkedForReview,
    this.isSkipped,
    this.isGuess
  });

  factory QuestionPalleteModel.fromJson(Map<String, dynamic> json) => _$QuestionPalleteModelFromJson(json);

  @JsonKey(name: 'question_id')
  String? questionId;
  @JsonKey(name: 'question_number')
  int? questionNumber;
  @JsonKey(name: 'attempted')
  bool? isAttempted;
  @JsonKey(name: 'marked_for_review')
  bool? isMarkedForReview;
  @JsonKey(name: 'attempted_marked_for_review')
  bool? isAttemptedMarkedForReview;
  @JsonKey(name: 'skipped')
  bool? isSkipped;
  @JsonKey(name: 'guess')
  bool? isGuess;


  Map<String, dynamic> toJson() => _$QuestionPalleteModelToJson(this);
}