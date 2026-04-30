import 'dart:ui';
import 'package:json_annotation/json_annotation.dart';

part 'test_exampaper_list_model.g.dart';

@JsonSerializable(explicitToJson: true)
class TestExamPaperListModel {
  TestExamPaperListModel(
      {this.negativeMarking,
      this.marksDeducted,
      this.examId,
      this.id,
      this.examName,
      this.categoryId,
      this.timeDuration,
      this.marksAwarded,
      this.created_at,
      this.updated_at,
      this.isAttempt,
      this.plan_id,
      this.isfreeTrail,
      this.sid,
      this.instruction,
      this.test,
      this.isPracticeExamAttempt,
      this.isAccess,
      this.isPracticeMode,
      this.totalQuestions,
      this.totalMarks,
      this.highestScore,
      this.highestScoreRank,
      this.remainingAttempts,
      this.fromtime,
      this.totime,
      this.isDeclaration,
      this.exitUserExamId,
      this.isCorrect,
      this.declarationTime,
      this.day = "0",
      this.isGivenTest,
      this.isSection,
      this.sectionWiseCount});

  factory TestExamPaperListModel.fromJson(Map<String, dynamic> json) =>
      _$TestExamPaperListModelFromJson(json);

  @JsonKey(name: 'negative_marking')
  bool? negativeMarking;
  @JsonKey(name: 'marks_deducted')
  double? marksDeducted;
  @JsonKey(name: '_id')
  String? examId;
  int? id;
  bool? isDeclaration;
  bool? isGivenTest;
  String? declarationTime;
  @JsonKey(name: 'exam_name')
  String? examName;
  @JsonKey(name: 'category_id')
  String? categoryId;
  @JsonKey(name: 'time_duration')
  String? timeDuration;
  @JsonKey(name: 'marks_awarded')
  int? marksAwarded;
  String? created_at;
  String? updated_at;
  bool? isAttempt;
  String? sid;
  String? instruction;
  String? day;
  List<TestData>? test;
  @JsonKey(name: 'sectiondata')
  List<SectionData>? sectionData;
  bool? isPracticeExamAttempt;
  bool? isAccess;
  @JsonKey(name: 'is_practice_mode')
  bool? isPracticeMode;
  bool? isSection;
  bool? isfreeTrail;
  String? plan_id;
  int? sectionWiseCount;
  int? highestScoreRank;
  int? highestScore;
  int? totalMarks;
  int? totalQuestions;
  int? remainingAttempts;
  @JsonKey(name: 'exitUserExam_id')
  String? exitUserExamId;
  @JsonKey(name: 'is_correct')
  bool? isCorrect;
  String? fromtime;
  String? totime;
  String? lastPracticeTime;
  String? lastTestModeTime;
  String? userExamType;
  bool? isCompleted;
  int? practiceAnswersCount;

  Map<String, dynamic> toJson() => _$TestExamPaperListModelToJson(this);
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
    this.correctPercentage,
    this.explanation,
    this.created_at,
    this.updated_at,
    this.id,
    this.skipped,
    this.optionsData,
    this.questionNumber,
    this.selectedOption,
    this.isCorrect,
    this.statusColor,
    this.isHighlight,
    this.txtColor,
    this.annotationData,
    this.bookmarks,
  });

  factory TestData.fromJson(Map<String, dynamic> json) =>
      _$TestDataFromJson(json);

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
  bool? skipped;
  bool? isHighlight;
  @JsonKey(name: 'annotation_data')
  List<Map<String, dynamic>>? annotationData;
  @JsonKey(name: 'options')
  List<Options>? optionsData;
  @JsonKey(name: 'question_number')
  int? questionNumber;
  @JsonKey(name: 'selected_option')
  String? selectedOption;
  String? correctPercentage;
  @JsonKey(name: 'is_correct')
  bool? isCorrect;
  int? statusColor;
  int? txtColor;
  bool? bookmarks;

  Map<String, dynamic> toJson() => _$TestDataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SectionData {
  SectionData({
    this.section,
    this.timeDuration,
    this.questionCount,
  });

  factory SectionData.fromJson(Map<String, dynamic> json) =>
      _$SectionDataFromJson(json);

  String? section;
  @JsonKey(name: 'time_duration')
  String? timeDuration;
  int? questionCount;

  Map<String, dynamic> toJson() => _$SectionDataToJson(this);
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
