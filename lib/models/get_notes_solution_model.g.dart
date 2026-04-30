// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_notes_solution_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetNotesSolutionModel _$GetNotesSolutionModelFromJson(
        Map<String, dynamic> json) =>
    GetNotesSolutionModel(
      notes: json['Notes'] as String?,
      id: json['_id'] as String?,
      queId: json['question_id'] as String?,
      err: json['err'] == null
          ? null
          : ErrorModel.fromJson(json['err'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetNotesSolutionModelToJson(
        GetNotesSolutionModel instance) =>
    <String, dynamic>{
      'Notes': instance.notes,
      '_id': instance.id,
      'question_id': instance.queId,
      'err': instance.err?.toJson(),
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
