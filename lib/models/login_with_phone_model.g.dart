// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_with_phone_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginWithPhoneModel _$LoginWithPhoneModelFromJson(Map<String, dynamic> json) =>
    LoginWithPhoneModel(
      message: json['message'] as String?,
      token: json['token'] as String?,
      error: json['error'] as String?,
      err: json['err'] == null
          ? null
          : ErrorModel.fromJson(json['err'] as Map<String, dynamic>),
      isActive: json['isActive'] as bool?,
      lastLoginDevices: (json['lastLoginDevices'] as List<dynamic>?)
              ?.map((e) =>
                  LastLoginDeviceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$LoginWithPhoneModelToJson(
        LoginWithPhoneModel instance) =>
    <String, dynamic>{
      'message': instance.message,
      'token': instance.token,
      'error': instance.error,
      'isActive': instance.isActive,
      'err': instance.err?.toJson(),
      'lastLoginDevices':
          instance.lastLoginDevices.map((e) => e.toJson()).toList(),
    };

LastLoginDeviceModel _$LastLoginDeviceModelFromJson(
        Map<String, dynamic> json) =>
    LastLoginDeviceModel(
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      platform: json['platform'] as String?,
      lastLogin: json['lastLogin'] == null
          ? null
          : DateTime.parse(json['lastLogin'] as String),
    );

Map<String, dynamic> _$LastLoginDeviceModelToJson(
        LastLoginDeviceModel instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'platform': instance.platform,
      'lastLogin': instance.lastLogin?.toIso8601String(),
    };

ErrorModel _$ErrorModelFromJson(Map<String, dynamic> json) => ErrorModel(
      code: json['code'],
      message: json['message'] as String?,
      params: json['params'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ErrorModelToJson(ErrorModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'params': instance.params,
    };
