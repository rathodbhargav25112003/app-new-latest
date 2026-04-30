import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';

part 'forgot_password_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ForgotPasswordModel{
  ForgotPasswordModel({
    this.message,
    this.token,
    this.error,
    this.err,
  });

  factory ForgotPasswordModel.fromJson(Map<String, dynamic> json) =>
      _$ForgotPasswordModelFromJson(json);

  final String? message;
  final String? token;
  final String? error;
  final ErrorModel? err;
  Map<String, dynamic> toJson() => _$ForgotPasswordModelToJson(this);
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
