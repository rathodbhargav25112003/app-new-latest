// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_video_note_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateVideoNoteHistoryModel _$CreateVideoNoteHistoryModelFromJson(
        Map<String, dynamic> json) =>
    CreateVideoNoteHistoryModel(
      id: (json['id'] as num?)?.toInt(),
      contentId: json['content_id'] as String?,
      contentType: json['content_type'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      sId: json['_id'] as String?,
      iV: (json['__v'] as num?)?.toInt(),
      userId: json['user_id'] as String?,
    );

Map<String, dynamic> _$CreateVideoNoteHistoryModelToJson(
        CreateVideoNoteHistoryModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'id': instance.id,
      '__v': instance.iV,
      'content_id': instance.contentId,
      'user_id': instance.userId,
      'content_type': instance.contentType,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
    };
