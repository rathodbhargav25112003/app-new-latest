import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

part 'section_exam_paper_data_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SectionExamPaperDataModel {
  SectionExamPaperDataModel({
    this.questionImg,
    this.explanationImg,
    this.sId,
    this.examId,
    this.questionText,
    this.correctOption,
    this.explanation,
    this.created_at,
    this.updated_at,
    this.id,
    this.optionVal,
    this.questionNumber,
    this.statusColor,
    this.txtColor,
    this.bookmarks,
    this.selectedOption,
    this.isCorrect,
  });

  factory SectionExamPaperDataModel.fromJson(Map<String, dynamic> json) => _$SectionExamPaperDataModelFromJson(json);

  @JsonKey(name: 'question_image')
  List<String>? questionImg;
  @JsonKey(name: 'explanation_image')
  List<String>? explanationImg;
  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: 'exam_id')
  String? examId;
  @JsonKey(name: 'question_text')
  String? questionText;
  @JsonKey(name: 'correct_option')
  String? correctOption;
  @JsonKey(name: 'selected_option')
  String? selectedOption;
  @JsonKey(name: 'is_correct')
  bool? isCorrect;
  String? explanation;
  String? created_at;
  String? updated_at;
  int? id;
  @JsonKey(name: 'options')
  List<OptionData>? optionVal;
  @JsonKey(name: 'question_number')
  int? questionNumber;
  int? statusColor;
  int? txtColor;
  bool? bookmarks;

  Map<String, dynamic> toJson() => _$SectionExamPaperDataModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OptionData {
  OptionData({
    this.answerImg,
    this.answerTitle,
    this.sId,
    this.value});

  factory OptionData.fromJson(Map<String, dynamic> json) => _$OptionDataFromJson(json);

  @JsonKey(name: 'answer_image')
  String? answerImg;
  @JsonKey(name: 'answer_title')
  String? answerTitle;
  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: 'value')
  String? value;

  Map<String, dynamic> toJson() => _$OptionDataToJson(this);
}