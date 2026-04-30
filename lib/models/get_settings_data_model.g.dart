// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_settings_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetSettingsDataModel _$GetSettingsDataModelFromJson(
        Map<String, dynamic> json) =>
    GetSettingsDataModel(
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      id: json['_id'] as String?,
      attempt: (json['attempt'] as num?)?.toInt(),
      err: json['err'] == null
          ? null
          : ErrorModel.fromJson(json['err'] as Map<String, dynamic>),
      showActiveUser: json['showActiveUser'] as bool?,
      hardCopyOff: json['hardCopyOff'] as String?,
      hardCopydes: json['hardCopydes'] as String?,
      isInAPurchases: json['isInAPurchases'] as bool?,
    );

Map<String, dynamic> _$GetSettingsDataModelToJson(
        GetSettingsDataModel instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'email': instance.email,
      '_id': instance.id,
      'attempt': instance.attempt,
      'showActiveUser': instance.showActiveUser,
      'err': instance.err?.toJson(),
      'hardCopyOff': instance.hardCopyOff,
      'hardCopydes': instance.hardCopydes,
      'isInAPurchases': instance.isInAPurchases,
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
