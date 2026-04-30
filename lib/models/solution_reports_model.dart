import 'package:json_annotation/json_annotation.dart';

part 'solution_reports_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SolutionReportsModel {
  SolutionReportsModel(
      {this.isCorrect,
      this.bookmarks,
      this.selectedOption,
      this.questionImg,
      this.explanationImg,
      this.questionId,
      this.userAnswerId,
      this.examId,
      this.questionText,
      this.correctOption,
      this.correctPercentage,
      this.explanation,
      this.created_at,
      this.annotationData,
      this.updated_at,
      this.id,
      this.options,
      this.isHighlight,
      this.questionNumber,
      this.statusColor,
      this.txtColor,
      this.guess,
      this.Notes,
      this.topicName,
      this.skipped});

  factory SolutionReportsModel.fromJson(Map<String, dynamic> json) =>
      _$SolutionReportsModelFromJson(json);

  @JsonKey(name: 'is_correct')
  bool? isCorrect;
  bool? bookmarks;
  @JsonKey(name: 'selected_option')
  String? selectedOption;
  String? guess;
  @JsonKey(name: 'question_image')
  List<String>? questionImg;
  @JsonKey(name: 'explanation_image')
  List<String>? explanationImg;
  @JsonKey(name: 'question_id')
  String? questionId;
  @JsonKey(name: 'userAnswer_id')
  String? userAnswerId;
  @JsonKey(name: 'exam_id')
  String? examId;
  @JsonKey(name: 'question_text')
  String? questionText;
  @JsonKey(name: 'correct_option')
  String? correctOption;
  String? correctPercentage;
  String? explanation;
  @JsonKey(name: 'annotation_data')
  List<Map<String, dynamic>>? annotationData;
  bool? isHighlight;
  String? created_at;
  String? updated_at;
  @JsonKey(name: 'marked_for_review')
  String? markedforreview;
  @JsonKey(name: 'attempted_marked_for_review')
  String? attemptedmarkedforreview;
  int? id;
  @JsonKey(name: 'options')
  List<Options>? options;
  @JsonKey(name: 'question_number')
  int? questionNumber;
  int? statusColor;
  int? txtColor;
  @JsonKey(name: 'bookmark_id')
  String? bookmarkId;
  String? Notes;
  String? topicName;
  bool? skipped;

  Map<String, dynamic> toJson() => _$SolutionReportsModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Options {
  Options(
      {this.answerImg,
      this.answerTitle,
      this.sId,
      this.value,
      this.percentage});

  factory Options.fromJson(Map<String, dynamic> json) =>
      _$OptionsFromJson(json);

  @JsonKey(name: 'answer_image')
  String? answerImg;
  @JsonKey(name: 'answer_title')
  String? answerTitle;
  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: 'value')
  String? value;
  String? percentage;

  Map<String, dynamic> toJson() => _$OptionsToJson(this);
}
