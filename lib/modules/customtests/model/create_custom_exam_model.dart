import 'package:json_annotation/json_annotation.dart';

part 'create_custom_exam_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateCustomExamModel {
  CreateCustomExamModel({
    this.score,
    this.isAttemptcount,
    this.isPractice,
    this.id,
    this.examId,
    this.startTime,
    this.endTime,
    this.userId,
    this.created_at,
    this.updated_at,
    this.sid,
    this.err
  });

  factory CreateCustomExamModel.fromJson(Map<String, dynamic> json) => _$CreateCustomExamModelFromJson(json);

  num? score;
  int? isAttemptcount;
  bool? isPractice;
  @JsonKey(name: '_id')
  String? id;
  @JsonKey(name: 'exam_id')
  String? examId;
  @JsonKey(name: 'start_time')
  String? startTime;
  @JsonKey(name: 'end_time')
  String? endTime;
  @JsonKey(name: 'user_id')
  String? userId;
  String? created_at;
  String? updated_at;
  @JsonKey(name: "id")
  int? sid;
  errMsg? err;

  Map<String, dynamic> toJson() => _$CreateCustomExamModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class errMsg {
  errMsg({
    this.message,
  });

  factory errMsg.fromJson(Map<String, dynamic> json) =>
      _$errMsgFromJson(json);

  String? message;

  Map<String, dynamic> toJson() => _$errMsgToJson(this);
}
