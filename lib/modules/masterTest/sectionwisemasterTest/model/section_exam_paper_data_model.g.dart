// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'section_exam_paper_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SectionExamPaperDataModel _$SectionExamPaperDataModelFromJson(
        Map<String, dynamic> json) =>
    SectionExamPaperDataModel(
      questionImg: (json['question_image'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      explanationImg: (json['explanation_image'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      sId: json['_id'] as String?,
      examId: json['exam_id'] as String?,
      questionText: json['question_text'] as String?,
      correctOption: json['correct_option'] as String?,
      explanation: json['explanation'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      id: (json['id'] as num?)?.toInt(),
      optionVal: (json['options'] as List<dynamic>?)
          ?.map((e) => OptionData.fromJson(e as Map<String, dynamic>))
          .toList(),
      questionNumber: (json['question_number'] as num?)?.toInt(),
      statusColor: (json['statusColor'] as num?)?.toInt(),
      txtColor: (json['txtColor'] as num?)?.toInt(),
      bookmarks: json['bookmarks'] as bool?,
      selectedOption: json['selected_option'] as String?,
      isCorrect: json['is_correct'] as bool?,
    );

Map<String, dynamic> _$SectionExamPaperDataModelToJson(
        SectionExamPaperDataModel instance) =>
    <String, dynamic>{
      'question_image': instance.questionImg,
      'explanation_image': instance.explanationImg,
      '_id': instance.sId,
      'exam_id': instance.examId,
      'question_text': instance.questionText,
      'correct_option': instance.correctOption,
      'selected_option': instance.selectedOption,
      'is_correct': instance.isCorrect,
      'explanation': instance.explanation,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'id': instance.id,
      'options': instance.optionVal?.map((e) => e.toJson()).toList(),
      'question_number': instance.questionNumber,
      'statusColor': instance.statusColor,
      'txtColor': instance.txtColor,
      'bookmarks': instance.bookmarks,
    };

OptionData _$OptionDataFromJson(Map<String, dynamic> json) => OptionData(
      answerImg: json['answer_image'] as String?,
      answerTitle: json['answer_title'] as String?,
      sId: json['_id'] as String?,
      value: json['value'] as String?,
    );

Map<String, dynamic> _$OptionDataToJson(OptionData instance) =>
    <String, dynamic>{
      'answer_image': instance.answerImg,
      'answer_title': instance.answerTitle,
      '_id': instance.sId,
      'value': instance.value,
    };
