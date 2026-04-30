import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';

part 'preparing_for_model.g.dart';

@JsonSerializable(explicitToJson: true)
class PreparingForModel{
  PreparingForModel({
    this.id,
    this.preparingFor,
    this.created_at,
    this.err,
    this.checkbox
  });

  factory PreparingForModel.fromJson(Map<String, dynamic> json) => _$PreparingForModelFromJson(json);

  @JsonKey(name: '_id')
  final String? id;
  @JsonKey(name: 'preparing_for')
  final String? preparingFor;
  final String? created_at;
  final ErrorModel? err;
  final List<String>? checkbox;
  Map<String, dynamic> toJson() => _$PreparingForModelToJson(this);
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
