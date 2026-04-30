import 'package:json_annotation/json_annotation.dart';

part 'ask_question_model.g.dart';

@JsonSerializable(explicitToJson: true)
class AskQuestionModel {
  AskQuestionModel({
    this.id,
    this.userId,
    this.question,
    this.answer,
    this.created_at,
    this.updated_at,
    this.sId,
    this.iV,
  });

  factory AskQuestionModel.fromJson(Map<String, dynamic> json) => _$AskQuestionModelFromJson(json);

  int? id;
  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: '__v')
  int? iV;
  @JsonKey(name: 'user_id')
  String? userId;
  String? question;
  String? answer;
  String? created_at;
  String? updated_at;

  Map<String, dynamic> toJson() => _$AskQuestionModelToJson(this);
}
