import 'package:json_annotation/json_annotation.dart';

part 'create_query_solution_report_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateQuerySolutionReportModel {
  CreateQuerySolutionReportModel({
    this.isSolveQuery,
    this.id,
    this.userId,
    this.questionId,
    this.query,
    this.createdAt,
  });

  factory CreateQuerySolutionReportModel.fromJson(Map<String, dynamic> json) => _$CreateQuerySolutionReportModelFromJson(json);

  bool? isSolveQuery;
  @JsonKey(name:"_id")
  String? id;
  @JsonKey(name:"user_id")
  String? userId;
  @JsonKey(name:"question_id")
  String? questionId;
  String? query;
  @JsonKey(name: 'created_at')
  String? createdAt;

  Map<String, dynamic> toJson() => _$CreateQuerySolutionReportModelToJson(this);
}
