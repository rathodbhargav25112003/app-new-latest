import 'package:json_annotation/json_annotation.dart';

part 'report_by_exam_list_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ReportByExamListModel {
  ReportByExamListModel({
    this.score,
    this.isAttemptcount,
    this.id,
    this.examId,
    this.startTime,
    this.endTime,
    this.userId,
    this.createdAt,
    this.examName,
    this.declarationTime,
    this.isAccess,
    this.isDeclaration,
  });

  factory ReportByExamListModel.fromJson(Map<String, dynamic> json) => _$ReportByExamListModelFromJson(json);

  num? score;
  int? isAttemptcount;
  @JsonKey(name:"_id")
  String? id;
  @JsonKey(name: 'exam_id')
  String? examId;
  @JsonKey(name: 'start_time')
  String? startTime;
  @JsonKey(name: 'end_time')
  String? endTime;
  @JsonKey(name: 'user_id')
  String? userId;
  @JsonKey(name: 'created_at')
  String? createdAt;
  @JsonKey(name: 'exam_name')
  String? examName;
  String? declarationTime;
  bool? isAccess;
  bool? isDeclaration;

  Map<String, dynamic> toJson() => _$ReportByExamListModelToJson(this);
}
