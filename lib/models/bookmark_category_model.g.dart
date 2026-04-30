// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookMarkCategoryModel _$BookMarkCategoryModelFromJson(
        Map<String, dynamic> json) =>
    BookMarkCategoryModel(
      category_id: json['category_id'] as String?,
      category_name: json['category_name'] as String?,
      isNeetss: json['Neet_SS'] as bool?,
      created_at: json['created_at'] as String?,
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$BookMarkCategoryModelToJson(
        BookMarkCategoryModel instance) =>
    <String, dynamic>{
      'category_id': instance.category_id,
      'category_name': instance.category_name,
      'Neet_SS': instance.isNeetss,
      'created_at': instance.created_at,
      'questionCount': instance.questionCount,
    };
