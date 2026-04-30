// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_subcategory_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotesSubCategoryModel _$NotesSubCategoryModelFromJson(
        Map<String, dynamic> json) =>
    NotesSubCategoryModel(
      sId: json['_id'] as String?,
      subcategory_id: json['subcategory_id'] as String?,
      subcategoryName: json['subcategory_name'] as String?,
      categoryId: json['category_id'] as String?,
      topic_id: json['topic_id'] as String?,
      topic_name: json['topic_name'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      description: json['description'] as String?,
      sid: json['sid'] as String?,
      position: (json['position'] as num?)?.toInt(),
      id: (json['id'] as num?)?.toInt(),
      iV: (json['__v'] as num?)?.toInt(),
      topicCount: (json['topicCount'] as num?)?.toInt(),
      completPdfCount: (json['completPdfCount'] as num?)?.toInt(),
      progressCount: (json['progressCount'] as num?)?.toInt(),
      notStart: (json['notStart'] as num?)?.toInt(),
      notes: (json['Notes'] as num?)?.toInt(),
      bookmarkPdfCount: (json['bookmarkPdfCount'] as num?)?.toInt(),
    )
      ..priorityLabel = json['priorityLabel'] as String?
      ..priorityColor = json['priorityColor'] as String?;

Map<String, dynamic> _$NotesSubCategoryModelToJson(
        NotesSubCategoryModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'subcategory_id': instance.subcategory_id,
      'subcategory_name': instance.subcategoryName,
      'category_id': instance.categoryId,
      'position': instance.position,
      'id': instance.id,
      '__v': instance.iV,
      'topicCount': instance.topicCount,
      'Notes': instance.notes,
      'completPdfCount': instance.completPdfCount,
      'progressCount': instance.progressCount,
      'notStart': instance.notStart,
      'bookmarkPdfCount': instance.bookmarkPdfCount,
      'topic_id': instance.topic_id,
      'topic_name': instance.topic_name,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'description': instance.description,
      'sid': instance.sid,
      'priorityLabel': instance.priorityLabel,
      'priorityColor': instance.priorityColor,
    };
