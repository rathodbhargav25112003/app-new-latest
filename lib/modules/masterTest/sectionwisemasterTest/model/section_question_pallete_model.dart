import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'section_question_pallete_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SectionQuestionPalleteModel {
  SectionQuestionPalleteModel({
    this.section,
    this.status,
    this.questions,
  });

  factory SectionQuestionPalleteModel.fromJson(Map<String, dynamic> json) => _$SectionQuestionPalleteModelFromJson(json);

  String? section;
  String? status;
  @JsonKey(name: 'questions')
  List<Question>? questions;


  Map<String, dynamic> toJson() => _$SectionQuestionPalleteModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Question {
  Question({
    this.questionId,
    this.questionNumber,
    this.isAttempted,
    this.isMarkedForReview,
    this.isAttemptedMarkedForReview,
    this.isSkipped,
    this.isGuess
  });

  factory Question.fromJson(Map<String, dynamic> json) => _$QuestionFromJson(json);

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


  Map<String, dynamic> toJson() => _$QuestionToJson(this);
}