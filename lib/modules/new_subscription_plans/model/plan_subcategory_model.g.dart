// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_subcategory_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanSubcategoryModel _$PlanSubcategoryModelFromJson(
        Map<String, dynamic> json) =>
    PlanSubcategoryModel(
      id: (json['id'] as num?)?.toInt(),
      sid: json['_id'] as String?,
      subcategory_name: json['subcategory_name'] as String?,
      description: json['description'] as String?,
      category_id: json['category_id'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      deleted_at: json['deleted_at'],
      isMcq: json['isMcq'] as bool?,
      isMock: json['isMock'] as bool?,
      isVideo: json['isVideo'] as bool?,
      isNote: json['isNote'] as bool?,
      isLive: json['isLive'] as bool?,
    );

Map<String, dynamic> _$PlanSubcategoryModelToJson(
        PlanSubcategoryModel instance) =>
    <String, dynamic>{
      '_id': instance.sid,
      'subcategory_name': instance.subcategory_name,
      'description': instance.description,
      'category_id': instance.category_id,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'deleted_at': instance.deleted_at,
      'id': instance.id,
      'isMcq': instance.isMcq,
      'isMock': instance.isMock,
      'isVideo': instance.isVideo,
      'isNote': instance.isNote,
      'isLive': instance.isLive,
    };
