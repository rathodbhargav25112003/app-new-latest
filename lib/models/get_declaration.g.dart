// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_declaration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetDeclaration _$GetDeclarationFromJson(Map<String, dynamic> json) =>
    GetDeclaration(
      examId: json['exam_id'] as String?,
      categoryId: json['category_id'] as String?,
      examName: json['exam_name'] as String?,
      categoryName: json['category_name'] as String?,
    );

Map<String, dynamic> _$GetDeclarationToJson(GetDeclaration instance) =>
    <String, dynamic>{
      'exam_id': instance.examId,
      'category_id': instance.categoryId,
      'exam_name': instance.examName,
      'category_name': instance.categoryName,
    };
