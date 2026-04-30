import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';

part 'error_message_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ErrorMessageModel{
  ErrorMessageModel({
    this.error,
    this.message
  });

  factory ErrorMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ErrorMessageModelFromJson(json);

  final String? error;
  final String? message;
  Map<String, dynamic> toJson() => _$ErrorMessageModelToJson(this);
}