import 'package:json_annotation/json_annotation.dart';

part 'create_query_mock_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateQueryMockModel {
  CreateQueryMockModel({
    this.isSolveQuery,
    this.id,
    this.userId,
    this.questionId,
    this.query,
    this.createdAt,
  });

  factory CreateQueryMockModel.fromJson(Map<String, dynamic> json) => _$CreateQueryMockModelFromJson(json);

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

  Map<String, dynamic> toJson() => _$CreateQueryMockModelToJson(this);
}
