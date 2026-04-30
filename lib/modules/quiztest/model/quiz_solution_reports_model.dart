import 'package:json_annotation/json_annotation.dart';

part 'quiz_solution_reports_model.g.dart';

@JsonSerializable(explicitToJson: true)
class QuizSolutionReportsModel {
  QuizSolutionReportsModel({
    this.isCorrect,
    this.bookmarks,
    this.selectedOption,
    this.questionImg,
    this.explanationImg,
    this.questionId,
    this.userAnswerId,
    this.examId,
    this.questionText,
    this.correctOption,
    this.explanation,
    this.created_at,
    this.updated_at,
    this.id,
    this.options,
    this.questionNumber,
    this.statusColor,
    this.txtColor,
    this.guess,
    this.Notes,
    this.topicName});

  factory QuizSolutionReportsModel.fromJson(Map<String, dynamic> json) => _$QuizSolutionReportsModelFromJson(json);

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
  @JsonKey(name: 'quizQuestion_id')
  String? questionId;
  @JsonKey(name: 'quizUserAnswer_id')
  String? userAnswerId;
  @JsonKey(name: 'exam_id')
  String? examId;
  @JsonKey(name: 'question_text')
  String? questionText;
  @JsonKey(name: 'correct_option')
  String? correctOption;
  String? explanation;
  String? created_at;
  String? updated_at;
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

  Map<String, dynamic> toJson() => _$QuizSolutionReportsModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Options {
  Options({
    this.answerImg,
    this.answerTitle,
    this.sId,
    this.value});

  factory Options.fromJson(Map<String, dynamic> json) => _$OptionsFromJson(json);

  @JsonKey(name: 'answer_image')
  String? answerImg;
  @JsonKey(name: 'answer_title')
  String? answerTitle;
  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: 'value')
  String? value;

  Map<String, dynamic> toJson() => _$OptionsToJson(this);
}