// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanCategoryModel _$PlanCategoryModelFromJson(Map<String, dynamic> json) =>
    PlanCategoryModel(
      id: (json['id'] as num?)?.toInt(),
      sid: json['_id'] as String?,
      category_name: json['category_name'] as String?,
      description: json['description'] as String?,
      created_at: json['created_at'] as String?,
      deleted_at: json['deleted_at'],
    );

Map<String, dynamic> _$PlanCategoryModelToJson(PlanCategoryModel instance) =>
    <String, dynamic>{
      '_id': instance.sid,
      'category_name': instance.category_name,
      'description': instance.description,
      'created_at': instance.created_at,
      'deleted_at': instance.deleted_at,
      'id': instance.id,
    };
