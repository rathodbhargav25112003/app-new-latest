// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_video_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateVideoHistoryModel _$CreateVideoHistoryModelFromJson(
        Map<String, dynamic> json) =>
    CreateVideoHistoryModel(
      sId: json['_id'] as String?,
      content_id: json['content_id'] as String?,
      user_id: json['user_id'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      id: (json['id'] as num?)?.toInt(),
      iV: (json['__v'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CreateVideoHistoryModelToJson(
        CreateVideoHistoryModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'content_id': instance.content_id,
      'user_id': instance.user_id,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'id': instance.id,
      '__v': instance.iV,
    };
