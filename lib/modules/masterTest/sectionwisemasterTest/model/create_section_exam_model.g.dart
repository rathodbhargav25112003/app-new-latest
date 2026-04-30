// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_section_exam_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateSectionExamModel _$CreateSectionExamModelFromJson(
        Map<String, dynamic> json) =>
    CreateSectionExamModel(
      id: json['_id'] as String?,
      userExamId: json['userExam_id'] as String?,
      section: (json['section'] as List<dynamic>?)
          ?.map((e) => Section.fromJson(e as Map<String, dynamic>))
          .toList(),
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      err: json['err'] == null
          ? null
          : errMsg.fromJson(json['err'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CreateSectionExamModelToJson(
        CreateSectionExamModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'userExam_id': instance.userExamId,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'section': instance.section?.map((e) => e.toJson()).toList(),
      'err': instance.err?.toJson(),
    };

Section _$SectionFromJson(Map<String, dynamic> json) => Section(
      id: json['_id'] as String?,
      sectionId: json['section_id'] as String?,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$SectionToJson(Section instance) => <String, dynamic>{
      '_id': instance.id,
      'section_id': instance.sectionId,
      'status': instance.status,
    };

errMsg _$errMsgFromJson(Map<String, dynamic> json) => errMsg(
      message: json['message'] as String?,
    );

Map<String, dynamic> _$errMsgToJson(errMsg instance) => <String, dynamic>{
      'message': instance.message,
    };
