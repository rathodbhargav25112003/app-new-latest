import 'package:json_annotation/json_annotation.dart';

part 'get_notes_solution_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GetNotesSolutionModel {
  GetNotesSolutionModel({
    this.notes,
    this.id,
    this.queId,
    this.err,
  });

  factory GetNotesSolutionModel.fromJson(Map<String, dynamic> json) => _$GetNotesSolutionModelFromJson(json);

  @JsonKey(name: 'Notes')
  String? notes;
  @JsonKey(name: '_id')
  String? id;
  @JsonKey(name: 'question_id')
  String? queId;
  ErrorModel? err;

  Map<String, dynamic> toJson() => _$GetNotesSolutionModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ErrorModel {
  ErrorModel({
    this.code,
    this.message,
    this.params,
  });

  factory ErrorModel.fromJson(Map<String, dynamic> json) =>
      _$ErrorModelFromJson(json);

  final dynamic code;
  final String? message;
  final Map<String, dynamic>? params;

  Map<String, dynamic> toJson() => _$ErrorModelToJson(this);
}
