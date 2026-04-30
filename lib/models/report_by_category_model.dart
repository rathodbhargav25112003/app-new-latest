import 'package:json_annotation/json_annotation.dart';

part 'report_by_category_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ReportByCategoryModel {
  ReportByCategoryModel({
    this.categoryName,
    this.userRank,
    this.userFirstRank,
    this.myMark,
    this.candidate,
    this.question,
    this.isAttemptcount,
    this.duration,
    this.date,
    this.mark,
    this.percentage,
    this.correctAnswers,
    this.incorrectAnswers,
    this.skippedAnswers,
    this.correctAnswersPercentage,
    this.incorrectAnswersPercentage,
    this.skippedAnswersPercentage,
    this.leftqusestion,
    this.accuracyPercentage,
    this.attemptQuetion,
    this.userExamId,
    this.isDeclaration,
    this.declarationTime,
    this.timeOnQuestion,
    this.guessedAnswersCount,
    this.correctGuessCount,
  this.wrongGuessCount,
    this.incorrect_correct,
    this.correct_incorrect,
    this.incorrect_incorres
  });

  factory ReportByCategoryModel.fromJson(Map<String, dynamic> json) => _$ReportByCategoryModelFromJson(json);

  @JsonKey(name:"category_name")
  String? categoryName;
  num? userRank;
  num? userFirstRank;
  @JsonKey(name:"mymark")
  num? myMark;
  int? candidate;
  bool? isDeclaration;
  String? declarationTime;
  @JsonKey(name:"Question")
  int? question;
  int? isAttemptcount;
  @JsonKey(name: 'Duration')
  String? duration;
  @JsonKey(name: 'Date')
  String? date;
  num? mark;
  String? percentage;
  int? correctAnswers;
  int? incorrectAnswers;
  int? skippedAnswers;
  String? correctAnswersPercentage;
  String? incorrectAnswersPercentage;
  String? skippedAnswersPercentage;
  int? leftqusestion;
  String? accuracyPercentage;
  @JsonKey(name: 'Attemptquetion')
  int? attemptQuetion;
  String? userExamId;
  @JsonKey(name: 'TimeOnQuestion')
  String? timeOnQuestion;
  num? guessedAnswersCount;
  int? correctGuessCount;
  int? wrongGuessCount;

  int? incorrect_correct;
      int? correct_incorrect;
  int? incorrect_incorres;
  String? Time;


  Map<String, dynamic> toJson() => _$ReportByCategoryModelToJson(this);
}
