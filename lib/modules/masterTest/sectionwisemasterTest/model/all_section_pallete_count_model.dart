import 'package:json_annotation/json_annotation.dart';

part 'all_section_pallete_count_model.g.dart';

@JsonSerializable(explicitToJson: true)
class AllSectionQuestionPalleteCountModel {
  AllSectionQuestionPalleteCountModel({
    this.section,
    this.isAttempted,
    this.isMarkedForReview,
    this.isAttemptedMarkedForReview,
    this.isSkipped,
    this.notVisited,
    this.isGuess
  });

  factory AllSectionQuestionPalleteCountModel.fromJson(Map<String, dynamic> json) => _$AllSectionQuestionPalleteCountModelFromJson(json);

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


  Map<String, dynamic> toJson() => _$AllSectionQuestionPalleteCountModelToJson(this);
}