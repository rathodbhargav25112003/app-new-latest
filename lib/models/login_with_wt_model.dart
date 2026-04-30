import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';

part 'login_with_wt_model.g.dart';

@JsonSerializable(explicitToJson: true)
class LoginWithWtModel{
  LoginWithWtModel({
    this.message,
    this.phone,
    this.token,
    this.error,
    this.err,
    this.isActive
  });

  factory LoginWithWtModel.fromJson(Map<String, dynamic> json) =>
      _$LoginWithWtModelFromJson(json);
final String? message;
  final String? phone;
  final String? token;
  final String? error;
  final bool? isActive;
  final ErrorModel? err;
  Map<String, dynamic> toJson() => _$LoginWithWtModelToJson(this);
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
