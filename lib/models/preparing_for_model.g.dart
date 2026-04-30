// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preparing_for_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PreparingForModel _$PreparingForModelFromJson(Map<String, dynamic> json) =>
    PreparingForModel(
      id: json['_id'] as String?,
      preparingFor: json['preparing_for'] as String?,
      created_at: json['created_at'] as String?,
      err: json['err'] == null
          ? null
          : ErrorModel.fromJson(json['err'] as Map<String, dynamic>),
      checkbox: (json['checkbox'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$PreparingForModelToJson(PreparingForModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'preparing_for': instance.preparingFor,
      'created_at': instance.created_at,
      'err': instance.err?.toJson(),
      'checkbox': instance.checkbox,
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
