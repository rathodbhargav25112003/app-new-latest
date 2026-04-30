import 'package:json_annotation/json_annotation.dart';

part 'get_all_my_custom_test_model.g.dart';

@JsonSerializable(explicitToJson: true)
class MyCustomTestListModel {
  MyCustomTestListModel({
    this.isSubscribe,
    this.data,
  });

  factory MyCustomTestListModel.fromJson(Map<String, dynamic> json) => _$MyCustomTestListModelFromJson(json);

  bool? isSubscribe;
  @JsonKey(name: 'data')
  List<Data>? data;

  Map<String, dynamic> toJson() => _$MyCustomTestListModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Data {
  Data({
    this.timeDuration,
    this.marksAwarded,
    this.remainingAttempts,
    this.description,
    this.subcategory,
    this.sId,
    this.category,
    this.exam,
    this.exitUserExamId,
    this.isGivenTest,
    this.isAttempt,
    this.numberOfQuestions,
    this.testName,
    this.test,
    this.topic});

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  String? testName;
  int? category;
  int? subcategory;
  int? topic;
  int? exam;
  @JsonKey(name: 'NumberOfQuestions')
  int? numberOfQuestions;
  @JsonKey(name: 'time_duration')
  String? timeDuration;
  @JsonKey(name: 'Description')
  String? description;
  @JsonKey(name: 'marks_awarded')
  int? marksAwarded;
  @JsonKey(name: 'marks_deducted')
  int? marksDeducted;
  @JsonKey(name: 'RemainingAttempts')
  int? remainingAttempts;
  bool? isGivenTest;
  bool? isAttempt;
  List<TestData>? test;
  @JsonKey(name: 'exitUserExam_id')
  String? exitUserExamId;

  Map<String, dynamic> toJson() => _$DataToJson(this);
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
    this.selectedOption,
    this.isCorrect,
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
  @JsonKey(name: 'selected_option')
  String? selectedOption;
  @JsonKey(name: 'is_correct')
  bool? isCorrect;
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