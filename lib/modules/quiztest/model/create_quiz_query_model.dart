import 'package:json_annotation/json_annotation.dart';

part 'create_quiz_query_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateQuizQueryModel {
  CreateQuizQueryModel({
    this.isSolveQuery,
    this.id,
    this.userId,
    this.questionId,
    this.query,
    this.createdAt,
    this.otherIssue,
    this.explanationIssue,
    this.incorrectAnswer,
    this.incorrectQuestion
  });

  factory CreateQuizQueryModel.fromJson(Map<String, dynamic> json) => _$CreateQuizQueryModelFromJson(json);

  bool? isSolveQuery;
  @JsonKey(name:"IncorrectQuestion")
  bool? incorrectQuestion;
  @JsonKey(name:"IncorrectAnswer")
  bool? incorrectAnswer;
  @JsonKey(name:"ExplanationIssue")
  bool? explanationIssue;
  @JsonKey(name:"OtherIssue")
  bool? otherIssue;
  @JsonKey(name:"_id")
  String? id;
  @JsonKey(name:"user_id")
  String? userId;
  @JsonKey(name:"question_id")
  String? questionId;
  String? query;
  @JsonKey(name: 'created_at')
  String? createdAt;

  Map<String, dynamic> toJson() => _$CreateQuizQueryModelToJson(this);
}
