import 'package:json_annotation/json_annotation.dart';

part 'section_question_pallete_count_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SectionQuestionPalleteCountModel {
  SectionQuestionPalleteCountModel({
    this.section,
    this.isAttempted,
    this.isMarkedForReview,
    this.isAttemptedMarkedForReview,
    this.isSkipped,
    this.notVisited,
    this.isGuess
  });

  factory SectionQuestionPalleteCountModel.fromJson(Map<String, dynamic> json) => _$SectionQuestionPalleteCountModelFromJson(json);

  @JsonKey(name: 'attempted')
  int? isAttempted;
  String? section;
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


  Map<String, dynamic> toJson() => _$SectionQuestionPalleteCountModelToJson(this);
}