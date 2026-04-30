import 'package:json_annotation/json_annotation.dart';

part 'quiz_model.g.dart';

@JsonSerializable(explicitToJson: true)
class QuizModel {
  QuizModel({
    this.description,
    this.marksAwarded,
    this.marksDeducted,
    this.timeDuration,
    this.correct,
    this.created_at,
    this.dateTime,
    this.incorrect,
    this.isTodayQuizComplete,
    this.quizId,
    this.quizName,
    this.test,
    this.totalQuestion,
    this.quizUserExamId
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) => _$QuizModelFromJson(json);

  @JsonKey(name: 'quiz_id')
  String? quizId;
  @JsonKey(name: 'quizUserExam_id')
  String? quizUserExamId;
  @JsonKey(name:"quiz_name")
  String? quizName;
  String? dateTime;
  @JsonKey(name:"time_duration")
  String? timeDuration;
  String? description;
  bool? isTodayQuizComplete;
  int? correct;
  List<TestData>? test;
  int? incorrect;
  @JsonKey(name:"marks_deducted")
  num? marksDeducted;
  @JsonKey(name:"marks_awarded")
  num? marksAwarded;
  int? totalQuestion;
  String? created_at;

  Map<String, dynamic> toJson() => _$QuizModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TestData {
  TestData({
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
    this.optionsData,
    this.questionNumber,
    this.statusColor,
    this.txtColor,
    this.bookmarks,
  });

  factory TestData.fromJson(Map<String, dynamic> json) => _$TestDataFromJson(json);

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
  String? explanation;
  String? created_at;
  String? updated_at;
  int? id;
  @JsonKey(name: 'options')
  List<Options>? optionsData;
  @JsonKey(name: 'question_number')
  int? questionNumber;
  int? statusColor;
  int? txtColor;
  bool? bookmarks;

  Map<String, dynamic> toJson() => _$TestDataToJson(this);
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