import 'package:json_annotation/json_annotation.dart';

part 'custom_test_question_pallete_count_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CustomTestQuestionPalleteCountModel {
  CustomTestQuestionPalleteCountModel({
    this.isAttempted,
    this.isMarkedForReview,
    this.isAttemptedMarkedForReview,
    this.isSkipped,
    this.notVisited,
    this.isGuess
  });

  factory CustomTestQuestionPalleteCountModel.fromJson(Map<String, dynamic> json) => _$CustomTestQuestionPalleteCountModelFromJson(json);

  @JsonKey(name: 'attempted')
  int? isAttempted;
  @JsonKey(name: 'marked_for_review')
  int? isMarkedForReview;
  @JsonKey(name: 'attempted_marked_for_review')
  int? isAttemptedMarkedForReview;
  @JsonKey(name: 'skipped')
  int? isSkipped;
  @JsonKey(name: 'not_visited')
  int? notVisited;
  @JsonKey(name: 'guess')
  int? isGuess;


  Map<String, dynamic> toJson() => _$CustomTestQuestionPalleteCountModelToJson(this);
}