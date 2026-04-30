import 'package:json_annotation/json_annotation.dart';

part 'user_exam_answer_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UserExamAnswer{
  UserExamAnswer({
    this.isCorrect,
    this.attempted,
    this.markedForReview,
    this.attemptedMarkedForReview,
    this.skipped,
    this.bookmarks,
    this.deleted_at,
    this.sId,
    this.guess,
    this.selectedOption,
    this.previousSelected,
    this.userExamId,
    this.questionId,
    this.timePerQuestion,
    this.created_at,
    this.updated_at,
    this.time,
    this.iV,
    this.id
  });

  factory UserExamAnswer.fromJson(Map<String, dynamic> json) =>
      _$UserExamAnswerFromJson(json);

  @JsonKey(name: 'is_correct')
  bool? isCorrect;
  bool? attempted;
  @JsonKey(name: 'marked_for_review')
  bool? markedForReview;
  @JsonKey(name: 'attempted_marked_for_review')
  bool? attemptedMarkedForReview;
  bool? skipped;
  bool? bookmarks;
  String? deleted_at;
  @JsonKey(name: '_id')
  String? sId;
  String? time;
  String? guess;
  String? previousSelected;
  @JsonKey(name: 'userExam_id')
  String? userExamId;
  @JsonKey(name: 'question_id')
  String? questionId;
  @JsonKey(name: 'selected_option')
  String? selectedOption;
  String? created_at;
  String? updated_at;
  String? timePerQuestion;
  int? id;
  @JsonKey(name: '__v')
  int? iV;

  Map<String, dynamic> toJson() => _$UserExamAnswerToJson(this);
}