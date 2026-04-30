// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotesCategoryModel _$NotesCategoryModelFromJson(Map<String, dynamic> json) =>
    NotesCategoryModel(
      id: json['_id'] as String?,
      category_id: json['category_id'] as String?,
      category_name: json['category_name'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      notes: (json['Notes'] as num?)?.toInt(),
      subcategory: (json['subcategory'] as num?)?.toInt(),
      sid: json['sid'] as String?,
      description: json['description'] as String?,
      subcategory_id: json['subcategory_id'] as String?,
      subcategory_name: json['subcategory_name'] as String?,
      topic_id: json['topic_id'] as String?,
      topic_name: json['topic_name'] as String?,
      completedPdfCount: (json['completedPdfCount'] as num?)?.toInt(),
      progressCount: (json['progressCount'] as num?)?.toInt(),
      notStart: (json['notStart'] as num?)?.toInt(),
      bookmarkPdfCount: (json['bookmarkPdfCount'] as num?)?.toInt(),
    )
      ..priorityLabel = json['priorityLabel'] as String?
      ..priorityColor = json['priorityColor'] as String?;

Map<String, dynamic> _$NotesCategoryModelToJson(NotesCategoryModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'category_id': instance.category_id,
      'category_name': instance.category_name,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'subcategory': instance.subcategory,
      'Notes': instance.notes,
      'sid': instance.sid,
      'description': instance.description,
      'subcategory_id': instance.subcategory_id,
      'subcategory_name': instance.subcategory_name,
      'topic_id': instance.topic_id,
      'topic_name': instance.topic_name,
      'completedPdfCount': instance.completedPdfCount,
      'progressCount': instance.progressCount,
      'notStart': instance.notStart,
      'bookmarkPdfCount': instance.bookmarkPdfCount,
      'priorityLabel': instance.priorityLabel,
      'priorityColor': instance.priorityColor,
    };
