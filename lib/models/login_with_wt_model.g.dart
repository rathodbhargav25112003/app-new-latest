// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_with_wt_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginWithWtModel _$LoginWithWtModelFromJson(Map<String, dynamic> json) =>
    LoginWithWtModel(
      message: json['message'] as String?,
      phone: json['phone'] as String?,
      token: json['token'] as String?,
      error: json['error'] as String?,
      err: json['err'] == null
          ? null
          : ErrorModel.fromJson(json['err'] as Map<String, dynamic>),
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$LoginWithWtModelToJson(LoginWithWtModel instance) =>
    <String, dynamic>{
      'message': instance.message,
      'phone': instance.phone,
      'token': instance.token,
      'error': instance.error,
      'isActive': instance.isActive,
      'err': instance.err?.toJson(),
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
