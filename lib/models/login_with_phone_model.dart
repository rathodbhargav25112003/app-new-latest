import 'package:json_annotation/json_annotation.dart';

part 'login_with_phone_model.g.dart';

@JsonSerializable(explicitToJson: true)
class LoginWithPhoneModel {
  LoginWithPhoneModel({
    this.message,
    this.token,
    this.error,
    this.err,
    this.isActive,
    this.lastLoginDevices = const [], // Add lastLoginDevices list
  });

  factory LoginWithPhoneModel.fromJson(Map<String, dynamic> json) =>
      _$LoginWithPhoneModelFromJson(json);

  final String? message;
  final String? token;
  final String? error;
  final bool? isActive;
  final ErrorModel? err;
  final List<LastLoginDeviceModel>
      lastLoginDevices; // List of lastLoginDevices

  Map<String, dynamic> toJson() => _$LoginWithPhoneModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LastLoginDeviceModel {
  LastLoginDeviceModel({
    this.deviceId,
    this.deviceName,
    this.platform,
    this.lastLogin,
  });

  factory LastLoginDeviceModel.fromJson(Map<String, dynamic> json) =>
      _$LastLoginDeviceModelFromJson(json);

  final String? deviceId;
  final String? deviceName;
  final String? platform;
  final DateTime? lastLogin;

  Map<String, dynamic> toJson() => _$LastLoginDeviceModelToJson(this);
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
